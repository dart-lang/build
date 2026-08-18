// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/asset_location.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('AssetLocation', () {
    final pkg = BuildPackage(
      name: 'pkg_a',
      path: p.join('/', 'root', 'pkg_a'),
      watch: true,
    );

    test('fromPath creates source location for source files', () {
      final filePath = p.join('/', 'root', 'pkg_a', 'lib', 'foo.dart');
      final location = AssetLocation.fromPath(pkg, filePath);

      expect(location, AssetLocation.source(AssetId('pkg_a', 'lib/foo.dart')));
    });

    test('fromPath creates cache location for generated files', () {
      final filePath = p.join(
        '/',
        'root',
        'pkg_a',
        '.dart_tool',
        'build',
        'generated',
        'pkg_b',
        'lib',
        'bar.dart',
      );
      final location = AssetLocation.fromPath(pkg, filePath);

      expect(location, AssetLocation.cache(AssetId('pkg_b', 'lib/bar.dart')));
    });

    test('fromAssetId creates source location for regular AssetId', () {
      final id = AssetId('pkg_a', 'lib/foo.dart');
      final location = AssetLocation.fromAssetId(id);

      expect(location, AssetLocation.source(id));
    });

    test('fromAssetId creates cache location for generated path AssetId', () {
      final id = AssetId(
        'pkg_a',
        '.dart_tool/build/generated/pkg_b/lib/bar.dart',
      );
      final location = AssetLocation.fromAssetId(id);

      expect(location, AssetLocation.cache(AssetId('pkg_b', 'lib/bar.dart')));
    });

    test('toAssetId returns original id for source location', () {
      final location = AssetLocation.source(AssetId('pkg_a', 'lib/foo.dart'));
      expect(location.toAssetId('pkg_a'), AssetId('pkg_a', 'lib/foo.dart'));
    });

    test('toAssetId returns hidden id under outputRoot for cache location', () {
      final location = AssetLocation.cache(AssetId('pkg_b', 'lib/bar.dart'));
      expect(
        location.toAssetId('pkg_a'),
        AssetId('pkg_a', '.dart_tool/build/generated/pkg_b/lib/bar.dart'),
      );
    });
  });
}
