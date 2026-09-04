// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

import 'asset_content.dart';
import 'br_outputs.dart';
import 'finished_shared_part.dart';

/// Accumulates part file contributions and imports across build phases.
class SharedPartAccumulator {
  /// The library that this part is for.
  final AssetId libraryId;

  /// The language version override specified in the library source, or `null`
  /// if it has none and so uses the package language version.
  final String? languageVersion;

  final Map<int, List<String>> _imports = {};

  final Map<int, String> _contributions = {};

  final Map<int, AssetContent> contentsByPhase = {};

  SharedPartAccumulator(this.libraryId, this.languageVersion);

  /// Creates a [SharedPartAccumulator] seeded with existing contributions from
  /// a [FinishedSharedPart].
  factory SharedPartAccumulator.fromFinished(FinishedSharedPart finished) {
    final accumulator = SharedPartAccumulator(
      finished.libraryId,
      finished.languageVersion,
    );
    for (final entry in finished.imports.entries) {
      accumulator._imports[entry.key] = entry.value.toList();
    }
    for (final entry in finished.contributions.entries) {
      accumulator._contributions[entry.key] = entry.value;
    }
    return accumulator;
  }

  Map<int, List<String>> get imports => _imports;

  Map<int, String> get contributions => _contributions;

  /// Restores imports and contributions from on-disk part file content.
  void restoreContent(String content) {
    final parsed = SharedPartAccumulator.parseContent(content, libraryId);
    _imports
      ..clear()
      ..addAll(parsed._imports);
    _contributions
      ..clear()
      ..addAll(parsed._contributions);
    contentsByPhase.clear();
  }

  void updateContribution(
    int phase,
    List<String> newImports,
    String newContribution,
  ) {
    _imports[phase] = newImports;
    _contributions[phase] = newContribution;
    contentsByPhase.clear();
  }

  AssetContent contentAt({int? phase}) {
    final allKeys = {
      ..._imports.keys,
      ..._contributions.keys,
      ...contentsByPhase.keys,
    };
    final maxPhase = allKeys.isEmpty ? 0 : allKeys.reduce(max);
    final targetPhase = phase ?? maxPhase;
    if (contentsByPhase.containsKey(targetPhase)) {
      return contentsByPhase[targetPhase]!;
    }
    return contentsByPhase.putIfAbsent(targetPhase, () {
      final content = generateContent(upToPhase: phase);
      return AssetContent.string(content);
    });
  }

  /// Generates the `part of` directive connecting this part to the primary
  /// library.
  String get partOfDirective {
    final relativePath = p.url.relative(
      libraryId.path,
      from: p.url.dirname(libraryId.sharedPartId.path),
    );
    return "part of '$relativePath';";
  }

  /// Converts this [SharedPartAccumulator] into the final source code to be
  /// written to disk.
  String generateContent({bool format = true, int? upToPhase}) {
    final validPhases = <int>{
      ...imports.keys,
      ...contributions.keys,
    }.where((p) => upToPhase == null || p <= upToPhase).toList();
    validPhases.sort();

    final buffer = StringBuffer();
    if (languageVersion != null) {
      buffer.writeln(languageVersion);
    }
    buffer.writeln(partOfDirective);
    buffer.writeln();

    for (final phase in validPhases) {
      if (imports[phase]?.isNotEmpty ?? false) {
        buffer.writeln('// @PartBuilder:imports:$phase');
        for (final import in imports[phase]!) {
          buffer.writeln(import);
        }
      }
    }
    buffer.writeln();

    for (final phase in validPhases) {
      if (contributions[phase] != null) {
        buffer.writeln('// @PartBuilder:contribution:$phase');
        buffer.writeln(contributions[phase]);
        buffer.writeln();
      }
    }

    final rawContent = buffer.toString();
    String formattedContent;
    if (format) {
      try {
        formattedContent = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format(rawContent);
      } catch (_) {
        formattedContent = rawContent;
      }
    } else {
      formattedContent = rawContent;
    }

    if (languageVersion != null) {
      return formattedContent.replaceFirst(
        languageVersion!,
        '$languageVersion\n// dart format off',
      );
    } else {
      return '// dart format off\n$formattedContent';
    }
  }

  /// Converts this accumulator into an immutable [FinishedSharedPart].
  FinishedSharedPart toFinishedSharedPart() {
    return FinishedSharedPart(
      (b) => b
        ..libraryId = libraryId
        ..languageVersion = languageVersion
        ..imports.replace(
          _imports.map((k, v) => MapEntry(k, BuiltList<String>(v))),
        )
        ..contributions.replace(_contributions),
    );
  }

  /// Parses the raw content of a shared part file on disk into a
  /// [SharedPartAccumulator].
  static SharedPartAccumulator parseContent(String content, AssetId libraryId) {
    if (content.isEmpty) {
      return SharedPartAccumulator(libraryId, null);
    }

    final importPattern = RegExp(r'^// @PartBuilder:imports:(\d+)$');
    final contributionPattern = RegExp(r'^// @PartBuilder:contribution:(\d+)$');

    final lines = content.split('\n');
    var currentPhase = -1;
    var isImport = false;
    String? parsedLanguageVersion;

    if (lines.isNotEmpty && lines.first.startsWith('// @dart=')) {
      parsedLanguageVersion = lines.first;
    }

    final importsByPhase = <int, List<String>>{};
    final contributionsByPhase = <int, StringBuffer>{};

    for (final line in lines) {
      final importMatch = importPattern.firstMatch(line.trim());
      if (importMatch != null) {
        currentPhase = int.parse(importMatch.group(1)!);
        isImport = true;
        importsByPhase.putIfAbsent(currentPhase, () => []);
        continue;
      }

      final contributionMatch = contributionPattern.firstMatch(line.trim());
      if (contributionMatch != null) {
        currentPhase = int.parse(contributionMatch.group(1)!);
        isImport = false;
        contributionsByPhase.putIfAbsent(currentPhase, StringBuffer.new);
        continue;
      }

      if (currentPhase == -1) continue;
      if (line.trim().startsWith('part of')) continue;
      if (line.trim() == '// dart format off') continue;

      if (isImport) {
        if (line.trim().isNotEmpty) {
          importsByPhase[currentPhase]!.add(line);
        }
      } else {
        contributionsByPhase[currentPhase]!.writeln(line);
      }
    }

    final result = SharedPartAccumulator(libraryId, parsedLanguageVersion);
    result.imports.addAll(importsByPhase);
    contributionsByPhase.forEach((phase, buffer) {
      result.contributions[phase] = buffer.toString().trimRight();
    });

    return result;
  }
}
