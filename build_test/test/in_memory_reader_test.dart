// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/src/in_memory_reader_writer.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryAssetReaderWriter', () {
    final packageName = 'some_pkg';
    final libAsset = AssetId(packageName, 'lib/some_pkg.dart');
    final testAsset = AssetId(packageName, 'test/some_test.dart');

    late InMemoryAssetReaderWriter readerWriter;

    setUp(() {
      readerWriter =
          InMemoryAssetReaderWriter(rootPackage: packageName)
            ..testing.writeString(libAsset, 'libAsset')
            ..testing.writeString(testAsset, 'testAsset');
    });

    test(
      '#findAssets should throw if rootPackage and package are not supplied',
      () {
        readerWriter = InMemoryAssetReaderWriter();
        expect(
          () => readerWriter.assetFinder.find(Glob('lib/*.dart')),
          throwsUnsupportedError,
        );
      },
    );

    test('#findAssets should list files in lib/', () async {
      expect(await readerWriter.assetFinder.find(Glob('lib/*.dart')).toList(), [
        libAsset,
      ]);
    });

    test('#findAssets should list files in test/', () async {
      expect(
        await readerWriter.assetFinder.find(Glob('test/*.dart')).toList(),
        [testAsset],
      );
    });

    test(
      '#findAssets should be able to list files in non-root packages',
      () async {
        var otherLibAsset = AssetId('other', 'lib/other.dart');
        readerWriter.testing.writeString(otherLibAsset, 'otherLibAsset');
        expect(
          await readerWriter.assetFinder
              .find(Glob('lib/*.dart'), package: 'other')
              .toList(),
          [otherLibAsset],
        );
      },
    );
  });
}
