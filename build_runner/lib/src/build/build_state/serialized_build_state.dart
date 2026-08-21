// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../asset_content.dart';
import 'build_step_id.dart';
import 'build_step_result.dart';
import 'glob_id.dart';
import 'glob_result.dart';
import 'post_process_build_step_id.dart';
import 'post_process_build_step_result.dart';

part 'serialized_build_state.g.dart';

/// `BuildState` serialized for use across builds.
abstract class SerializedBuildState
    implements Built<SerializedBuildState, SerializedBuildStateBuilder> {
  static Serializer<SerializedBuildState> get serializer =>
      _$serializedBuildStateSerializer;

  BuiltSet<AssetId> get sources;
  BuiltMap<AssetId, AssetContent> get sourceContents;
  BuiltSet<AssetId> get missingSources;
  BuiltMap<BuildStepId, BuildStepResult> get buildStepResults;
  BuiltMap<PostProcessBuildStepId, PostProcessBuildStepResult>
  get postProcessResults;
  BuiltMap<GlobId, GlobResult> get globResults;

  SerializedBuildState._();
  factory SerializedBuildState([
    void Function(SerializedBuildStateBuilder) updates,
  ]) = _$SerializedBuildState;
}
