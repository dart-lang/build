// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'build_step_id.g.dart';

/// Unique ID for a build step.
abstract class BuildStepId implements Built<BuildStepId, BuildStepIdBuilder> {
  static Serializer<BuildStepId> get serializer => _$buildStepIdSerializer;

  AssetId get primaryInput;
  int get phaseNumber;

  factory({
    required AssetId primaryInput,
    required int phaseNumber,
  }) = _$BuildStepId._;
  new _();
}
