// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:io';

import 'package:test/test.dart';

import 'package:build/build.dart';

import '../common/common.dart';

final packageGraph = new PackageGraph.forPath('test/fixtures/basic_pkg');

main() async {

  group('FileBasedAssetReader', () {
    final reader = new FileBasedAssetReader(packageGraph);

    test('can read any application package files', () async {
      expect(await reader.readAsString(makeAssetId('basic_pkg|hello.txt')),
          'world\n');
      expect(await reader.readAsString(makeAssetId('basic_pkg|lib/hello.txt')),
          'world\n');
      expect(await reader.readAsString(makeAssetId('basic_pkg|web/hello.txt')),
          'world\n');
    });

    test('can only read package dependency files in the lib dir', () async {
      expect(await reader.readAsString(makeAssetId('a|lib/a.txt')), 'A\n');
      expect(reader.readAsString(makeAssetId('a|web/a.txt')),
          throwsA(invalidInputException));
      expect(reader.readAsString(makeAssetId('a|a.txt')),
          throwsA(invalidInputException));
    });

    test('can check for existence of any application package files', () async {
      expect(await reader.hasInput(makeAssetId('basic_pkg|hello.txt')), isTrue);
      expect(await reader.hasInput(makeAssetId('basic_pkg|lib/hello.txt')),
          isTrue);
      expect(await reader.hasInput(makeAssetId('basic_pkg|web/hello.txt')),
          isTrue);

      expect(await reader.hasInput(makeAssetId('basic_pkg|a.txt')), isFalse);
      expect(
          await reader.hasInput(makeAssetId('basic_pkg|lib/a.txt')), isFalse);
    });

    test('can only check for existence of package dependency files in lib',
        () async {
      expect(await reader.hasInput(makeAssetId('a|lib/a.txt')), isTrue);
      expect(await reader.hasInput(makeAssetId('a|lib/b.txt')), isFalse);
      expect(reader.hasInput(makeAssetId('a|web/a.txt')),
          throwsA(invalidInputException));
      expect(reader.hasInput(makeAssetId('a|a.txt')),
          throwsA(invalidInputException));
      expect(reader.hasInput(makeAssetId('foo|bar.txt')),
          throwsA(invalidInputException));
    });

    test('throws when attempting to read a non-existent file', () async {
      expect(reader.readAsString(makeAssetId('basic_pkg|foo.txt')),
          throwsA(assetNotFoundException));
      expect(reader.readAsString(makeAssetId('a|lib/b.txt')),
          throwsA(assetNotFoundException));
      expect(reader.readAsString(makeAssetId('foo|lib/bar.txt')),
          throwsA(packageNotFoundException));
    });
  });

  group('FileBasedAssetWriter', () {
    final writer = new FileBasedAssetWriter(packageGraph);

    test('can output files in the application package', () async {
      var asset = makeAsset('basic_pkg|test_file.txt', 'test');
      await writer.writeAsString(asset);
      var id = asset.id;
      var file = new File('test/fixtures/${id.package}/${id.path}');
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), 'test');
      await file.delete();
    });

    test('can\'t output files in package dependencies', () async {
      var asset = makeAsset('a|test.txt');
      expect(writer.writeAsString(asset), throwsA(invalidOutputException));
    });

    test('can\'t output files in arbitrary packages', () async {
      var asset = makeAsset('foo|bar.txt');
      expect(writer.writeAsString(asset), throwsA(invalidOutputException));
    });
  });
}
