// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset/reader.dart';
import 'package:build_test/build_test.dart';

class InMemoryRunnerAssetReader extends InMemoryAssetReader
    implements RunnerAssetReader {
  final _onCanReadController = StreamController<AssetId>.broadcast();
  Stream<AssetId> get onCanRead => _onCanReadController.stream;

  @override
  Future<bool> canRead(AssetId id) {
    _onCanReadController.add(id);
    return super.canRead(id);
  }

  InMemoryRunnerAssetReader(
      [Map<AssetId, dynamic>? sourceAssets, String? rootPackage])
      : super(sourceAssets: sourceAssets, rootPackage: rootPackage);

  InMemoryRunnerAssetReader.shareAssetCache(Map<AssetId, List<int>> assetCache,
      {String? rootPackage})
      : super.shareAssetCache(assetCache, rootPackage: rootPackage);
}
