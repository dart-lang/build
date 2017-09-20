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
    Map<AssetId, DatedValue> allAssets;

    setUp(() {
      allAssets = {
        libAsset: new DatedString('libAsset'),
        testAsset: new DatedString('testAsset'),
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

    test('#findAssets should list files in lib/', () {
      expect(assetReader.findAssets(new Glob('lib/*.dart')), [libAsset]);
    });

    test('#findAssets should list files in test/', () {
      expect(assetReader.findAssets(new Glob('test/*.dart')), [testAsset]);
    });

    test('#findAssets should be able to list files in non-root packages', () {
      var otherLibAsset = new AssetId('other', 'lib/other.dart');
      var otherAssets = {
        otherLibAsset: new DatedString('otherLibAsset'),
      };
      allAssets.addAll(otherAssets);
      expect(assetReader.findAssets(new Glob('lib/*.dart'), package: 'other'),
          [otherLibAsset]);
    });
  });
}
