// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:crypto/crypto.dart';

import 'build_step_id.dart';
import 'build_step_result.dart';
import 'glob_id.dart';
import 'glob_result.dart';
import 'post_process_build_step_id.dart';
import 'post_process_build_step_result.dart';

part 'incremental_build_state.g.dart';

/// `BuildState` saved for use in incremental builds.
abstract class IncrementalBuildState
    implements Built<IncrementalBuildState, IncrementalBuildStateBuilder> {
  static Serializer<IncrementalBuildState> get serializer =>
      _$incrementalBuildStateSerializer;

  BuiltSet<AssetId> get sources;
  BuiltMap<AssetId, Digest> get digests;
  BuiltSet<AssetId> get missingSources;
  BuiltMap<BuildStepId, BuildStepResult> get buildStepResults;
  BuiltMap<PostProcessBuildStepId, PostProcessBuildStepResult>
  get postProcessResults;
  BuiltMap<GlobId, GlobResult> get globResults;

  IncrementalBuildState._();
  factory IncrementalBuildState([
    void Function(IncrementalBuildStateBuilder) updates,
  ]) = _$IncrementalBuildState;
}
