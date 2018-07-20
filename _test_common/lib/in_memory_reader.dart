// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';

import 'package:build_runner_core/src/asset/reader.dart';

class InMemoryRunnerAssetReader extends InMemoryAssetReader
    implements RunnerAssetReader {
  InMemoryRunnerAssetReader(
      [Map<AssetId, dynamic> sourceAssets, String rootPackage])
      : super(sourceAssets: sourceAssets, rootPackage: rootPackage);

  InMemoryRunnerAssetReader.shareAssetCache(Map<AssetId, List<int>> assetCache,
      {String rootPackage})
      : super.shareAssetCache(assetCache, rootPackage: rootPackage);
}
