// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import '../asset/id.dart';
import 'build_step.dart';

/// The basic builder class, used to build new files from existing ones.
abstract class Builder {
  /// Generates the outputs for a given [BuildStep].
  Future build(BuildStep buildStep);

  /// Declares all potential output assets given [inputId]. If an empty [List]
  /// is returned then the asset will never be provided to [build].
  ///
  /// Note: Reading the contents of [inputId] is not supported during this
  /// phase. You can however choose later on not to actually output assets which
  /// you return here, but no other [Builder] will be able to output them.
  List<AssetId> declareOutputs(AssetId inputId);
}
