// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';

class StubAssetReader implements RunnerAssetReader {
  @override
  Future<bool> hasInput(AssetId id) => new Future.value(null);

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) =>
      new Future.value(null);

  @override
  Stream<AssetId> listAssetIds(_) async* {}

  @override
  Future<DateTime> lastModified(AssetId id) => new Future.value(null);
}
