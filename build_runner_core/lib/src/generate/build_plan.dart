// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' show AssetId;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

part 'build_plan.g.dart';

abstract class BuildPlan implements Built<BuildPlan, BuildPlanBuilder> {
  BuiltSet<AssetId> get changedInputs;
  BuiltSet<AssetId> get outputsToBuild;
  BuiltSet<AssetId> get outputsToCheck;
  BuiltSet<AssetId> get globsToEvaluate;

  factory BuildPlan([void Function(BuildPlanBuilder) updates]) = _$BuildPlan;
  BuildPlan._();
}
