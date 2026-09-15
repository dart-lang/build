// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/commands/serve/path_to_asset_id.dart';
import 'package:test/test.dart';

void main() {
  group('pathToAssetIds', () {
    test('valid path', () {
      final ids = pathToAssetIds('a', 'web', ['foo', 'bar.dart']);
      expect(ids.length, 1);
      expect(ids.first, AssetId('a', 'web/foo/bar.dart'));
    });

    test('rejects sequences that escape the expected subdir', () {
      expect(
        () => pathToAssetIds('a', 'web', ['..', 'foo', 'bar.dart']),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('permits sequences using .. that stay in the expected subdir', () {
      final ids = pathToAssetIds('a', 'web', ['foo', '..', 'bar.dart']);
      expect(ids.first.path, 'web/bar.dart');
    });

    test('handles `packages` mapping', () {
      final ids = pathToAssetIds('a', 'web', ['packages', 'b', 'foo.dart']);
      expect(ids.length, 2);
      expect(ids[0], AssetId('a', 'web/packages/b/foo.dart'));
      expect(ids[1], AssetId('b', 'lib/foo.dart'));
    });

    test('rejects packages mapping that escapes the lib directory', () {
      expect(
        () => pathToAssetIds('a', 'web', ['packages', 'b', '..', 'foo.dart']),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
