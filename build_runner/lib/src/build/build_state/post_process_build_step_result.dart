// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../asset_content.dart';

part 'post_process_build_step_result.g.dart';

/// The outputs and errors of a post process build step, and whether its
/// output is hidden.
abstract class PostProcessBuildStepResult
    implements
        Built<PostProcessBuildStepResult, PostProcessBuildStepResultBuilder> {
  static Serializer<PostProcessBuildStepResult> get serializer =>
      _$postProcessBuildStepResultSerializer;

  bool get hidden;

  bool get deletedPrimaryInput;

  BuiltMap<AssetId, AssetContent> get outputs;

  BuiltList<String> get errors;

  factory PostProcessBuildStepResult({
    required bool hidden,
    Map<AssetId, AssetContent> outputs = const {},
    Iterable<String> errors = const [],
    bool deletedPrimaryInput = false,
  }) => _$PostProcessBuildStepResult._(
    hidden: hidden,
    deletedPrimaryInput: deletedPrimaryInput,
    outputs: outputs.build(),
    errors: errors.toBuiltList(),
  );

  PostProcessBuildStepResult._();
}
