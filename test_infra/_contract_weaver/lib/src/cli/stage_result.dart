// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';

part 'stage_result.g.dart';

/// What staging did to the `lib` directory of the woven package.
abstract class StageResult implements Built<StageResult, StageResultBuilder> {
  /// Libraries written with contracts woven in.
  int get transformedCount;

  /// Files linked to the original, unchanged.
  int get symlinkCount;

  StageResult._();
  factory StageResult([void Function(StageResultBuilder) updates]) =
      _$StageResult;
}
