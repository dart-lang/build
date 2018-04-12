// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

void main() {
  group('$PackageAssetReader', () {
    PackageAssetReader reader;

    final buildTest = new AssetId('build_test', 'lib/build_test.dart');
    final buildMissing = new AssetId('build_test', 'lib/build_missing.dart');
    final thisFile = new AssetId('build_test', 'test/package_reader_test.dart');

    setUp(() async {
      reader = await PackageAssetReader.currentIsolate(
        rootPackage: 'build_test',
      );
    });

    test('should be able to read `build_test.dart`', () async {
      expect(await reader.canRead(buildTest), isTrue);
      expect(await reader.readAsString(buildTest), isNotEmpty);
    });

    test('should be able to read this file (in test/)', () async {
      expect(await reader.canRead(thisFile), isTrue);
    });

    test('should not be able to read a missing file', () async {
      expect(await reader.canRead(buildMissing), isFalse);
    });

    test('does not support findAssets', () {
      expect(() => reader.findAssets(new Glob('lib/*.dart')),
          throwsUnsupportedError);
    });
  });

  group('$PackageAssetReader.forPackage', () {
    AssetReader reader;

    final exampleLibA = 'test/_libs/example_a/';
    final exampleLibB = 'test/_libs/example_b/';
    final exampleLibAFile = new AssetId('example_a', 'lib/example_a.dart');
    final exampleLibBFile = new AssetId('example_b', 'lib/example_b.dart');

    test('should resolve one library', () async {
      reader = new PackageAssetReader.forPackageRoot('test/_libs');
      expect(await reader.canRead(exampleLibAFile), isTrue);
      expect(await reader.canRead(exampleLibBFile), isTrue);
    });

    test('should resolve multiple libraries', () async {
      reader = new PackageAssetReader.forPackages({
        'example_a': exampleLibA,
        'example_b': exampleLibB,
      });
      expect(await reader.canRead(exampleLibAFile), isTrue);
      expect(await reader.canRead(exampleLibBFile), isTrue);
    });
  });
}
