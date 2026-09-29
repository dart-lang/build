// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import '../build/asset_content.dart';
import '../build/finished_shared_part.dart';
import '../contracts.dart';

part 'build_inputs.g.dart';

/// The state of the file system before a build begins.
@Invariant('!cleanBuild || retainedOutputContents.isEmpty')
@Invariant('!cleanBuild || updatedSources.isEmpty')
@Invariant('!cleanBuild || deletedSources.isEmpty')
@Invariant('!cleanBuild || invalidOutputs.isEmpty')
@Invariant('!cleanBuild || sharedParts.isEmpty')
@Invariant('sourceContents.keys.every((id) => sources.contains(id))')
@Invariant('retainedOutputContents.keys.every((id) => !sources.contains(id))')
@Invariant('updatedSources.every((id) => sources.contains(id))')
@Invariant('deletedSources.every((id) => !sources.contains(id))')
@Invariant(
  'invalidOutputs.every((id) => !retainedOutputContents.containsKey(id))',
)
@Invariant('sources.every((id) => id.package.isNotEmpty && id.path.isNotEmpty)')
@Invariant('sources.every((id) => !id.isBrOutput)')
@Invariant(
  'sharedParts.keys.every((id) => id.package.isNotEmpty && id.path.isNotEmpty)',
)
@Invariant('sharedParts.keys.every((id) => id.sharedPartId != null)')
abstract class BuildInputs implements Built<BuildInputs, BuildInputsBuilder> {
  /// Whether this is a clean build.
  ///
  /// If `false`, there is output on disk from a compatible previous build that
  /// can be reused.
  bool get cleanBuild;

  /// All source files that are input to the build.
  BuiltSet<AssetId> get sources;

  /// Contents for source files that have declared outputs.
  BuiltMap<AssetId, AssetContent> get sourceContents;

  /// Output contents from the previous build that are retained for reuse.
  ///
  /// Invalid or deleted outputs are omitted. In `--keep` mode, externally
  /// modified outputs are retained with modified content but the previous
  /// digest.
  ///
  /// Empty if [cleanBuild].
  BuiltMap<AssetId, AssetContent> get retainedOutputContents;

  /// Sources that were added or modified since the last build.
  ///
  /// Empty if [cleanBuild].
  BuiltSet<AssetId> get updatedSources;

  /// Source files that were removed since the last build.
  ///
  /// Empty if [cleanBuild].
  BuiltSet<AssetId> get deletedSources;

  /// Generated outputs that will be deleted from disk at the end of the build
  /// because their input is gone, or that will be forcefully overwritten
  /// because they have been manually modified or deleted by the user.
  ///
  /// Empty if [cleanBuild].
  BuiltSet<AssetId> get invalidOutputs;

  /// Shared parts recovered from the previous build or parsed from disk.
  ///
  /// Empty if [cleanBuild].
  BuiltMap<AssetId, FinishedSharedPart> get sharedParts;

  BuildInputs._();
  factory BuildInputs([void Function(BuildInputsBuilder) updates]) =
      _$BuildInputs;
}
