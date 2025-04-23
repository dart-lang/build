// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'post_process_build_step_id.g.dart';

/// Identifies a `PostProcessBuildStep` within a build: the application of a
/// `PostProcessBuilder` to one input.
abstract class PostProcessBuildStepId
    implements Built<PostProcessBuildStepId, PostProcessBuildStepIdBuilder> {
  static Serializer<PostProcessBuildStepId> get serializer =>
      _$postProcessBuildStepIdSerializer;

  AssetId get input;

  /// The [actionNumber] identifying which `PostProcessBuilder` runs.
  int get actionNumber;

  PostProcessBuildStepId._();

  factory PostProcessBuildStepId({
    required AssetId input,
    required int actionNumber,
  }) = _$PostProcessBuildStepId._;
}
