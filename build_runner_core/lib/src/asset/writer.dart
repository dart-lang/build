// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

@Deprecated('No longer used')
typedef OnDelete = void Function(AssetId id);

abstract class RunnerAssetWriter implements AssetWriter {
  Future delete(AssetId id);

  /// Called after each completed build.
  ///
  /// Some [RunnerAssetWriter] implementations may buffer completed writes
  /// internally and flush them in [completeBuild].
  Future<void> completeBuild();
}
