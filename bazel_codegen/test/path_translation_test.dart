// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:build/build.dart';
import 'package:test/test.dart';

import 'package:_bazel_codegen/src/assets/path_translation.dart';

void main() {
  const packagePath = 'test/package/test_package';
  const packageName = 'test.package.test_package';
  const packageMap = const {packageName: packagePath};
  final f1AssetId = new AssetId(packageName, 'lib/filename1.dart');
  final f2AssetId = new AssetId(packageName, 'lib/src/filename2.dart');

  test('findAssetids translates paths', () {
    final translatedAssets = findAssetIds([
      'test/package/test_package/lib/filename1.dart',
      'test/package/test_package/lib/src/filename2.dart',
    ], packagePath, packageMap);
    expect(translatedAssets, equals([f1AssetId, f2AssetId]));
  });
}
