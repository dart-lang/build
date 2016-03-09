// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:build/build.dart';

import '../common/common.dart';

final packageGraph = new PackageGraph.forPath('test/fixtures/basic_pkg');
final newLine = Platform.isWindows ? '\r\n' : '\n';

main() {
  group('FileBasedAssetReader', () {
    final reader = new FileBasedAssetReader(packageGraph, ignoredDirs: ['pkg']);

    test('can read any application package files', () async {
      expect(await reader.readAsString(makeAssetId('basic_pkg|hello.txt')),
          'world$newLine');
      expect(await reader.readAsString(makeAssetId('basic_pkg|lib/hello.txt')),
          'world$newLine');
      expect(await reader.readAsString(makeAssetId('basic_pkg|web/hello.txt')),
          'world$newLine');
    });

    test('can read package dependency files in the lib dir', () async {
      expect(
          await reader.readAsString(makeAssetId('a|lib/a.txt')), 'A$newLine');
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

    test('can check for existence of package dependency files in lib',
        () async {
      expect(await reader.hasInput(makeAssetId('a|lib/a.txt')), isTrue);
      expect(await reader.hasInput(makeAssetId('a|lib/b.txt')), isFalse);
    });

    test('throws when attempting to read a non-existent file', () async {
      expect(reader.readAsString(makeAssetId('basic_pkg|foo.txt')),
          throwsA(assetNotFoundException));
      expect(reader.readAsString(makeAssetId('a|lib/b.txt')),
          throwsA(assetNotFoundException));
      expect(reader.readAsString(makeAssetId('foo|lib/bar.txt')),
          throwsA(packageNotFoundException));
    });

    test('can list files based on simple InputSets', () async {
      var inputSets = <InputSet>[
        new InputSet('basic_pkg', ['{lib,web}/**']),
        new InputSet('a', ['lib/**']),
      ];
      expect(
          await reader.listAssetIds(inputSets).toList(),
          unorderedEquals([
            makeAssetId('basic_pkg|lib/hello.txt'),
            makeAssetId('basic_pkg|web/hello.txt'),
            makeAssetId('a|lib/a.txt'),
          ]));
    });

    test('can list files based on InputSets with globs', () async {
      var inputSets = <InputSet>[
        new InputSet('basic_pkg', ['web/*.txt']),
        new InputSet('a', ['lib/*']),
      ];
      expect(
          await reader.listAssetIds(inputSets).toList(),
          unorderedEquals([
            makeAssetId('basic_pkg|web/hello.txt'),
            makeAssetId('a|lib/a.txt'),
          ]));
    });

    test('can get lastModified time for files', () async {
      expect(await reader.lastModified(makeAssetId('basic_pkg|hello.txt')),
          new isInstanceOf<DateTime>());
    });

    test('lastModified throws AssetNotFoundException appropriately', () async {
      expect(reader.lastModified(makeAssetId('basic_pkg|foo.txt')),
          throwsA(assetNotFoundException));
    });
  });

  group('FileBasedAssetWriter', () {
    final writer = new FileBasedAssetWriter(packageGraph);

    test('can output and delete files in the application package', () async {
      var asset = makeAsset('basic_pkg|test_file.txt', 'test');
      await writer.writeAsString(asset);
      var id = asset.id;
      var file = new File(path.join('test', 'fixtures', id.package, id.path));
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), 'test');

      await writer.delete(asset.id);
      expect(await file.exists(), isFalse);
    });
  });
}
