// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:crypto/crypto.dart';

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

  /// Content hashes for source files that have declared outputs.
  BuiltMap<AssetId, Digest> get digests;

  /// Source files that were newly added since the last build.
  ///
  /// Empty if [cleanBuild].
  BuiltSet<AssetId> get addedSources;

  /// Source files that were removed since the last build.
  ///
  /// Empty if [cleanBuild].
  BuiltSet<AssetId> get deletedSources;

  /// Source files that existed in the previous build but have been modified.
  ///
  /// Empty if [cleanBuild].
  BuiltSet<AssetId> get modifiedSources;

  /// Generated outputs that were deleted from disk.
  ///
  /// Empty if [cleanBuild].
  BuiltSet<AssetId> get deletedOutputs;

  /// Generated outputs that are no longer generated because their primary
  /// input was deleted or transitively deleted.
  ///
  /// Empty if [cleanBuild].
  BuiltSet<AssetId> get disappearedOutputs;

  /// Sources that were modified or deleted since the last build.
  ///
  /// `null` if [cleanBuild].
  Iterable<AssetId>? get invalidatedSources =>
      cleanBuild ? null : modifiedSources.followedBy(deletedSources);

  BuildInputs._();
  factory BuildInputs([void Function(BuildInputsBuilder) updates]) =
      _$BuildInputs;
}
