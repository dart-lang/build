// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/src/internal_test_reader_writer.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryAssetReaderWriter', () {
    final packageName = 'some_pkg';
    final libAsset = AssetId(packageName, 'lib/some_pkg.dart');
    final testAsset = AssetId(packageName, 'test/some_test.dart');

    late InternalTestReaderWriter readerWriter;

    setUp(() {
      readerWriter =
          InternalTestReaderWriter(outputRootPackage: packageName)
            ..testing.writeString(libAsset, 'libAsset')
            ..testing.writeString(testAsset, 'testAsset');
    });

    test('#findAssets should list files in lib/', () async {
      expect(
        await readerWriter.assetFinder
            .find(Glob('lib/*.dart'), package: packageName)
            .toList(),
        [libAsset],
      );
    });

    test('#findAssets should list files in test/', () async {
      expect(
        await readerWriter.assetFinder
            .find(Glob('test/*.dart'), package: packageName)
            .toList(),
        [testAsset],
      );
    });

    test(
      '#findAssets should be able to list files in non-root packages',
      () async {
        final otherLibAsset = AssetId('other', 'lib/other.dart');
        readerWriter.testing.writeString(otherLibAsset, 'otherLibAsset');
        expect(
          await readerWriter.assetFinder
              .find(Glob('lib/*.dart'), package: 'other')
              .toList(),
          [otherLibAsset],
        );
      },
    );

    test('load isolate sources', () async {
      final readerWriter = InternalTestReaderWriter();
      await readerWriter.testing.loadIsolateSources();
      expect(
        readerWriter.testing.assets,
        containsAll([
          AssetId('build', 'lib/build.dart'),
          AssetId('glob', 'lib/glob.dart'),
          AssetId('test', 'lib/test.dart'),
        ]),
      );
    });
  });
}
