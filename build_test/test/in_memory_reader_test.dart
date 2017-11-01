// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

void main() {
  group('$InMemoryAssetReader', () {
    final packageName = 'some_pkg';
    final libAsset = new AssetId(packageName, 'lib/some_pkg.dart');
    final testAsset = new AssetId(packageName, 'test/some_test.dart');

    InMemoryAssetReader assetReader;

    setUp(() {
      var allAssets = {
        libAsset: 'libAsset',
        testAsset: 'testAsset',
      };
      assetReader = new InMemoryAssetReader(
        sourceAssets: allAssets,
        rootPackage: packageName,
      );
    });

    test('#findAssets should throw if rootPackage and package are not supplied',
        () {
      assetReader = new InMemoryAssetReader();
      expect(
        () => assetReader.findAssets(new Glob('lib/*.dart')),
        throwsUnsupportedError,
      );
    });

    test('#findAssets should list files in lib/', () async {
      expect(await assetReader.findAssets(new Glob('lib/*.dart')).toList(),
          [libAsset]);
    });

    test('#findAssets should list files in test/', () async {
      expect(await assetReader.findAssets(new Glob('test/*.dart')).toList(),
          [testAsset]);
    });

    test('#findAssets should be able to list files in non-root packages',
        () async {
      var otherLibAsset = new AssetId('other', 'lib/other.dart');
      assetReader.cacheStringAsset(otherLibAsset, 'otherLibAsset');
      expect(
          await assetReader
              .findAssets(new Glob('lib/*.dart'), package: 'other')
              .toList(),
          [otherLibAsset]);
    });
  });
}
