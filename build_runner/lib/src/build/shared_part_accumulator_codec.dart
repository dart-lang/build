// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:path/path.dart' as p;

import 'br_outputs.dart';
import 'shared_part_accumulator.dart';

/// Serializes a [SharedPartAccumulator] to and from human-readable Dart source.
class SharedPartAccumulatorCodec {
  const SharedPartAccumulatorCodec();

  /// Encodes [accumulator] to Dart source code.
  String encode(SharedPartAccumulator accumulator, {int? upToPhase}) {
    final validPhases = <int>{
      ...accumulator.imports.keys,
      ...accumulator.contributions.keys,
    }.where((phase) => upToPhase == null || phase <= upToPhase).toList();
    validPhases.sort();

    final buffer = StringBuffer();
    if (accumulator.languageVersion != null) {
      buffer.writeln(accumulator.languageVersion);
    }
    buffer.writeln('// dart format off');
    final relativePath = p.url.relative(
      accumulator.libraryId.path,
      from: p.url.dirname(accumulator.libraryId.sharedPartId!.path),
    );
    buffer.writeln("part of '$relativePath';");
    buffer.writeln();

    for (final phase in validPhases) {
      final phaseImports = accumulator.imports[phase];
      if (phaseImports?.isNotEmpty ?? false) {
        final builderKey = accumulator.builderKeys[phase] ?? '';
        buffer.writeln('// === $builderKey/$phase imports.');
        for (final import in phaseImports!) {
          buffer.writeln(_escapeContent(import));
        }
        buffer.writeln();
      }
    }

    for (final phase in validPhases) {
      final contribution = accumulator.contributions[phase];
      if (contribution != null && contribution.isNotEmpty) {
        final builderKey = accumulator.builderKeys[phase] ?? '';
        buffer.writeln('// === $builderKey/$phase contribution.');
        buffer.writeln(_escapeContent(contribution));
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Decodes shared part source [content] into a [SharedPartAccumulator] for
  /// [libraryId].
  SharedPartAccumulator decode(String content, AssetId libraryId) {
    if (content.isEmpty) {
      return SharedPartAccumulator(libraryId, null);
    }

    final parsed = parseString(content: content, throwIfDiagnostics: false);
    final languageVersion = parsed.unit.languageVersionToken?.lexeme;

    final delimiterPattern = RegExp(
      r'^// === (.+)/(\d+) (imports|contribution)\.$',
    );

    final markers =
        <
          ({String builderKey, int phase, bool isImports, int offset, int end})
        >[];

    void checkComments(Token? comment) {
      while (comment != null) {
        final text = comment.lexeme.trim();
        final match = delimiterPattern.firstMatch(text);
        if (match != null) {
          markers.add((
            builderKey: match.group(1)!,
            phase: int.parse(match.group(2)!),
            isImports: match.group(3)! == 'imports',
            offset: comment.offset,
            end: comment.end,
          ));
        }
        comment = comment.next;
      }
    }

    var token = parsed.unit.beginToken;
    while (!token.isEof) {
      checkComments(token.precedingComments);
      token = token.next!;
    }
    checkComments(parsed.unit.endToken.precedingComments);

    markers.sort((a, b) => a.offset.compareTo(b.offset));

    final builderKeys = <int, String>{};
    final importsByPhase = <int, ListBuilder<String>>{};
    final contributionsByPhase = <int, String>{};

    for (var i = 0; i < markers.length; i++) {
      final marker = markers[i];
      builderKeys[marker.phase] = marker.builderKey;
      final nextOffset = (i + 1 < markers.length)
          ? markers[i + 1].offset
          : content.length;
      final rawChunk = content.substring(marker.end, nextOffset).trim();
      final chunk = _unescapeContent(rawChunk);

      if (marker.isImports) {
        final lines = chunk
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty);
        importsByPhase.putIfAbsent(marker.phase, ListBuilder.new).addAll(lines);
      } else {
        contributionsByPhase[marker.phase] = chunk;
      }
    }

    final result = SharedPartAccumulator(libraryId, languageVersion);
    final allPhases = <int>{
      ...builderKeys.keys,
      ...importsByPhase.keys,
      ...contributionsByPhase.keys,
    }.toList()..sort();

    for (final phase in allPhases) {
      result.addContribution(
        phase,
        builderKeys[phase] ?? '',
        importsByPhase[phase]?.build() ?? BuiltList<String>(),
        contributionsByPhase[phase] ?? '',
      );
    }

    return result;
  }

  static String _escapeContent(String content) =>
      _transformComments(content, (text) {
        if (text.startsWith('// ===')) {
          return '// \\===${text.substring('// ==='.length)}';
        } else if (text.startsWith('// \\')) {
          return '// \\\\${text.substring('// \\'.length)}';
        }
        return null;
      });

  static String _unescapeContent(String content) =>
      _transformComments(content, (text) {
        if (text.startsWith('// \\===')) {
          return '// ===${text.substring('// \\==='.length)}';
        } else if (text.startsWith('// \\\\')) {
          return '// \\${text.substring('// \\\\'.length)}';
        }
        return null;
      });

  static String _transformComments(
    String content,
    String? Function(String commentText) transform,
  ) {
    if (content.isEmpty) return content;
    final parsed = parseString(content: content, throwIfDiagnostics: false);

    final replacements = <({int offset, int end, String replacement})>[];

    void checkComments(Token? comment) {
      while (comment != null) {
        final replacement = transform(comment.lexeme);
        if (replacement != null) {
          replacements.add((
            offset: comment.offset,
            end: comment.end,
            replacement: replacement,
          ));
        }
        comment = comment.next;
      }
    }

    var token = parsed.unit.beginToken;
    while (!token.isEof) {
      checkComments(token.precedingComments);
      token = token.next!;
    }
    checkComments(parsed.unit.endToken.precedingComments);

    if (replacements.isEmpty) return content;

    final buffer = StringBuffer();
    var lastIndex = 0;
    for (final r in replacements) {
      buffer.write(content.substring(lastIndex, r.offset));
      buffer.write(r.replacement);
      lastIndex = r.end;
    }
    buffer.write(content.substring(lastIndex));
    return buffer.toString();
  }
}
