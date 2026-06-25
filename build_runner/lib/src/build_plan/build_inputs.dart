// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import '../build/asset_content.dart';

part 'build_inputs.g.dart';

/// The state of the file system before a build begins.
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

  /// Sources that were added or modified since the last build.
  ///
  /// Empty if [cleanBuild].
  BuiltSet<AssetId> get updatedSources;

  /// Source files that were removed since the last build.
  ///
  /// Empty if [cleanBuild].
  BuiltSet<AssetId> get deletedSources;

  /// Generated outputs that were deleted from disk.
  ///
  /// Empty if [cleanBuild].
  BuiltSet<AssetId> get deletedOutputs;

  BuildInputs._();
  factory BuildInputs([void Function(BuildInputsBuilder) updates]) =
      _$BuildInputs;
}
