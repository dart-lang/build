// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';
import 'package:build_runner/src/asset/reader.dart'
    show Md5DigestReader, RunnerAssetReader;
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';

/// Workaround class for mixin application limitations, if
/// [InMemoryRunnerAssetReader] extends [InMemoryAssetReader] directly then it
/// can't use mixins ([Md5DigestReader] in this case).
class _InMemoryAssetReader extends InMemoryAssetReader {
  _InMemoryAssetReader(Map<AssetId, dynamic> sourceAssets, String rootPackage)
      : super(sourceAssets: sourceAssets, rootPackage: rootPackage);
}

class InMemoryRunnerAssetReader extends _InMemoryAssetReader
    with Md5DigestReader
    implements RunnerAssetReader {
  InMemoryRunnerAssetReader(
      [Map<AssetId, dynamic> sourceAssets, String rootPackage])
      : super(sourceAssets, rootPackage);

  @override
  Stream<AssetId> findAssets(Glob glob, {String package}) {
    package ??= rootPackage;
    return new Stream.fromIterable(assets.keys
        .where((id) => id.package == package && glob.matches(id.path)));
  }
}
