// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:dart_style/dart_style.dart';

import 'asset_content.dart';
import 'finished_shared_part.dart';
import 'shared_part_accumulator_codec.dart';

/// Accumulates part file contributions and imports across build phases.
class SharedPartAccumulator {
  /// The library that this part is for.
  final AssetId libraryId;

  /// The language version override specified in the library source, or `null`
  /// if it has none and so uses the package language version.
  final String? languageVersion;

  final MapBuilder<int, String> _builderKeys = MapBuilder();

  final MapBuilder<int, BuiltList<String>> _imports = MapBuilder();

  final MapBuilder<int, String> _contributions = MapBuilder();

  final Map<int, AssetContent> _contentsByPhase = {};
  AssetContent? _finalContent;

  SharedPartAccumulator(this.libraryId, this.languageVersion);

  void addContribution(
    int phase,
    String builderKey,
    BuiltList<String> newImports,
    String newContribution,
  ) {
    if (_contributions[phase] != null) {
      throw StateError('Contribution for phase $phase already added.');
    }
    _finalContent = null;
    _builderKeys[phase] = builderKey;
    _imports[phase] = newImports;
    _contributions[phase] = _formatContribution(newContribution);
  }

  static String _formatContribution(String contribution) {
    final trimmed = contribution.trim();
    if (trimmed.isEmpty) return '';
    try {
      return DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(trimmed).trim();
    } catch (_) {
      return trimmed;
    }
  }

  /// The content of this shared part up to and including [phase].
  ///
  /// Before reading at phase `p`, all contributions at or before `p` must
  /// have been added.
  AssetContent contentAt(int phase) => _contentsByPhase.putIfAbsent(phase, () {
    final content = const SharedPartAccumulatorCodec().encode(
      this,
      upToPhase: phase,
    );
    return AssetContent.string(content);
  });

  /// The final content of this shared part containing all contributions.
  AssetContent finalContent() => _finalContent ??= () {
    final content = const SharedPartAccumulatorCodec().encode(this);
    return AssetContent.string(content);
  }();

  /// This accumulated content as a [FinishedSharedPart].
  FinishedSharedPart toFinishedSharedPart() => FinishedSharedPart(
    (b) => b
      ..libraryId = libraryId
      ..languageVersion = languageVersion
      ..builderKeys = _builderKeys
      ..imports = _imports
      ..contributions = _contributions,
  );

  /// Parses the raw content of a shared part file on disk into a
  /// [SharedPartAccumulator].
  static SharedPartAccumulator parseContent(
    String content,
    AssetId libraryId,
  ) => const SharedPartAccumulatorCodec().decode(content, libraryId);

  BuiltMap<int, String> get builderKeys => _builderKeys.build();

  BuiltMap<int, BuiltList<String>> get imports => _imports.build();

  BuiltMap<int, String> get contributions => _contributions.build();
}
