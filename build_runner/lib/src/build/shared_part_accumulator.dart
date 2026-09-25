// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:dart_style/dart_style.dart';

import '../contracts.dart';
import 'asset_content.dart';
import 'finished_shared_part.dart';
import 'part_contribution.dart';
import 'shared_part_accumulator_codec.dart';

/// Accumulates part file contributions and imports across build phases.
@Invariant('libraryId.package.isNotEmpty')
@Invariant('libraryId.path.isNotEmpty')
@Invariant('libraryId.sharedPartId != null')
@Invariant('languageVersion == null || languageVersion!.isNotEmpty')
// Every recorded phase must survive a write and read of the shared part
// file. A phase with neither imports nor a contribution writes nothing, so
// reading the file back loses it, and `contentAt` then returns null where it
// previously returned content.
@Invariant(
  'contributions.values.every((c) => '
  'c.contribution.isNotEmpty || c.imports.isNotEmpty)',
)
// Imports are written and read back one per line, so an import containing a
// newline would come back as two imports.
@Invariant(
  r'contributions.values.every((c) => '
  r'c.imports.every((i) => !i.contains("\n")))',
)
class SharedPartAccumulator {
  /// The library that this part is for.
  final AssetId libraryId;

  /// The language version override specified in the library source, or `null`
  /// if it has none and so uses the package language version.
  final String? languageVersion;

  final MapBuilder<int, PartContribution> _contributions = MapBuilder();

  final Map<int, AssetContent> _contentsByPhase = {};
  AssetContent? _finalContent;

  SharedPartAccumulator(this.libraryId, this.languageVersion);

  @Requires('phase >= 0')
  @Requires('contribution.builderKey.isNotEmpty')
  @Requires('contributions.keys.every((p) => p <= phase)')
  @ThrowEnsures(StateError, 'contributions.containsKey(phase)')
  void addContribution(int phase, PartContribution contribution) {
    if (_contributions[phase] != null) {
      throw StateError('Contribution for phase $phase already added.');
    }
    _finalContent = null;
    _contributions[phase] = contribution.rebuild(
      (b) => b.contribution = _formatContribution(contribution.contribution),
    );
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

  /// The content of this shared part up to and including [phase], or `null` if
  /// there are no contributions at or before [phase].
  ///
  /// Before reading at phase `p`, all contributions at or before `p` must
  /// have been added.
  @Requires('phase >= -1')
  @Ensures('result == null || contributions.keys.any((p) => p <= phase)')
  @Ensures('result != null || contributions.keys.every((p) => p > phase)')
  AssetContent? contentAt(int phase) {
    if (_contributions.build().keys.every((p) => p > phase)) return null;
    return _contentsByPhase.putIfAbsent(phase, () {
      final content = const SharedPartAccumulatorCodec().encode(
        this,
        upToPhase: phase,
      );
      return AssetContent.string(content);
    });
  }

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
      ..contributions = _contributions,
  );

  /// Parses the raw content of a shared part file on disk into a
  /// [SharedPartAccumulator].
  static SharedPartAccumulator parseContent(
    String content,
    AssetId libraryId,
  ) => const SharedPartAccumulatorCodec().decode(content, libraryId);

  BuiltMap<int, PartContribution> get contributions => _contributions.build();
}
