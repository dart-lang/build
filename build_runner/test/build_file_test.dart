// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build_file.dart';
import 'package:build_runner/src/build_file_layout.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('AssetFile', () {
    test('source creates visible asset file', () {
      final file = AssetFile.source(AssetId('a', 'lib/a.dart'));
      expect(file.id, AssetId('a', 'lib/a.dart'));
      expect(file.hidden, false);
    });

    test('cache creates hidden asset file', () {
      final file = AssetFile.cache(AssetId('a', 'lib/a.dart'));
      expect(file.id, AssetId('a', 'lib/a.dart'));
      expect(file.hidden, true);
    });

    test('equality and hashCode', () {
      final file1 = AssetFile.source(AssetId('a', 'lib/a.dart'));
      final file2 = AssetFile.source(AssetId('a', 'lib/a.dart'));
      final file3 = AssetFile.cache(AssetId('a', 'lib/a.dart'));

      expect(file1, equals(file2));
      expect(file1.hashCode, equals(file2.hashCode));
      expect(file1, isNot(equals(file3)));
    });
  });

  group('InternalFile', () {
    test('holds package and path', () {
      final file = InternalFile('a', '.dart_tool/package_config.json');
      expect(file.package, 'a');
      expect(file.path, '.dart_tool/package_config.json');
    });

    test('enforces constraints', () {
      expect(
        () => InternalFile('a', 'lib/a.dart'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => InternalFile('a', '.dart_tool/build/generated/a/lib/a.dart'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => InternalFile('a', '/.dart_tool/package_config.json'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => InternalFile('a', '.dart_tool/../.dart_tool'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality and hashCode', () {
      final file1 = InternalFile('a', '.dart_tool/package_config.json');
      final file2 = InternalFile('a', '.dart_tool/package_config.json');
      final file3 = InternalFile('b', '.dart_tool/package_config.json');

      expect(file1, equals(file2));
      expect(file1.hashCode, equals(file2.hashCode));
      expect(file1, isNot(equals(file3)));
    });
  });

  group('BuildFileLayout', () {
    final pkgA = BuildPackage(
      name: 'a',
      path: p.join('/', 'root', 'a'),
      isOutput: true,
      dependencies: ['b'],
    );
    final pkgB = BuildPackage(
      name: 'b',
      path: p.join('/', 'root', 'b'),
      isOutput: true,
    );
    final buildPackages = BuildPackages.singlePackageBuild('a', [pkgA, pkgB]);

    test('converts source file path to AssetFile.source', () {
      final file = BuildFileLayout.fileFromPath(pkgA, 'lib/a.dart');
      expect(file, isA<AssetFile>());
      final assetFile = file as AssetFile;
      expect(assetFile.id, AssetId('a', 'lib/a.dart'));
      expect(assetFile.hidden, false);
    });

    test('converts generated cache file path to AssetFile.cache', () {
      final file = BuildFileLayout.fileFromPath(
        pkgA,
        '.dart_tool/build/generated/b/lib/b.g.dart',
      );
      expect(file, isA<AssetFile>());
      final assetFile = file as AssetFile;
      expect(assetFile.id, AssetId('b', 'lib/b.g.dart'));
      expect(assetFile.hidden, true);
    });

    test('converts non-asset .dart_tool path to InternalFile', () {
      final file = BuildFileLayout.fileFromPath(
        pkgA,
        '.dart_tool/package_config.json',
      );
      expect(file, isA<InternalFile>());
      final internalFile = file as InternalFile;
      expect(internalFile.package, 'a');
      expect(internalFile.path, '.dart_tool/package_config.json');
    });

    test('pathFor resolves paths for AssetFile and InternalFile', () {
      final source = AssetFile.source(AssetId('a', 'lib/a.dart'));
      expect(
        buildPackages.pathFor(source),
        p.join('/', 'root', 'a', 'lib', 'a.dart'),
      );

      final cached = AssetFile.cache(AssetId('b', 'lib/b.g.dart'));
      expect(
        buildPackages.pathFor(cached),
        p.join(
          '/',
          'root',
          'a',
          '.dart_tool',
          'build',
          'generated',
          'b',
          'lib',
          'b.g.dart',
        ),
      );

      final internal = InternalFile('a', '.dart_tool/package_config.json');
      expect(
        buildPackages.pathFor(internal),
        p.join('/', 'root', 'a', '.dart_tool', 'package_config.json'),
      );
    });
  });
}
