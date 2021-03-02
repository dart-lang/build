// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:build_test/src/multi_asset_reader.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

final isAssetNotFound = const TypeMatcher<AssetNotFoundException>();
final throwsAssetNotFound = throwsA(isAssetNotFound);

void main() {
  group('$MultiAssetReader', () {
    MultiAssetReader assetReader;

    test('should throw an $AssetNotFoundException with no readers', () {
      var missingId = AssetId('some_pkg', 'some_pkg.dart');
      assetReader = MultiAssetReader([]);
      expect(
        assetReader.readAsString(missingId),
        throwsAssetNotFound,
      );
    });

    test('should read an asset from an underyling reader', () async {
      var idA = AssetId('some_pkg', 'a.dart');
      var idB = AssetId('some_pkg', 'b.dart');
      var idC = AssetId('some_pkg', 'missing.dart');
      assetReader = MultiAssetReader([
        InMemoryAssetReader(sourceAssets: {
          idA: 'A',
        }),
        InMemoryAssetReader(sourceAssets: {
          idB: 'B',
        }),
      ]);
      expect(await assetReader.readAsString(idA), 'A');
      expect(await assetReader.readAsString(idB), 'B');
      expect(assetReader.readAsString(idC), throwsAssetNotFound);
    });

    test('should combine files when using `findAssets`', () async {
      var idA = AssetId('some_pkg', 'lib/a.dart');
      var idB = AssetId('some_pkg', 'lib/b.dart');
      assetReader = MultiAssetReader([
        InMemoryAssetReader(
          sourceAssets: {
            idA: 'A',
          },
          rootPackage: 'some_pkg',
        ),
        InMemoryAssetReader(
          sourceAssets: {
            idB: 'B',
          },
          rootPackage: 'some_pkg',
        ),
      ]);
      expect(await assetReader.findAssets(Glob('lib/*.dart')).toList(),
          [idA, idB]);
    });

    test('should support the `package` arg in `findAssets`', () async {
      var idA = AssetId('a', 'lib/a.dart');
      var idB = AssetId('b', 'lib/b.dart');
      assetReader = MultiAssetReader([
        InMemoryAssetReader(
          sourceAssets: {
            idA: 'A',
          },
        ),
        InMemoryAssetReader(
          sourceAssets: {
            idB: 'B',
          },
        ),
      ]);
      expect(
          await assetReader
              .findAssets(Glob('lib/*.dart'), package: 'a')
              .toList(),
          [idA]);
      expect(
          await assetReader
              .findAssets(Glob('lib/*.dart'), package: 'b')
              .toList(),
          [idB]);
    });

    test('propagates errors from wrapped readers', () {
      var idA = AssetId('a', 'lib/a.dart');
      assetReader = MultiAssetReader([
        InMemoryAssetReader(
          sourceAssets: {
            idA: 'A',
          },
        ),
      ]);
      expect(() => assetReader.findAssets(Glob('lib/*.dart')),
          throwsUnsupportedError);
    });
  });
}
