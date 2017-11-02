// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:scratch_space/scratch_space.dart';
import 'package:scratch_space/src/util.dart';

void main() {
  group('ScratchSpace', () {
    ScratchSpace scratchSpace;
    InMemoryAssetReader assetReader;

    Map<AssetId, List<int>> allAssets = [
      'dep|lib/dep.dart',
      'myapp|lib/myapp.dart',
      'myapp|web/main.dart',
    ].fold({}, (assets, serializedId) {
      assets[new AssetId.parse(serializedId)] = serializedId.codeUnits;
      return assets;
    });

    setUp(() async {
      scratchSpace = new ScratchSpace();
      assetReader = new InMemoryAssetReader(sourceAssets: allAssets);
      await scratchSpace.ensureAssets(allAssets.keys, assetReader);
    });

    tearDown(() async {
      if (scratchSpace.exists) await scratchSpace.delete();
    });

    test('Creates a directory under the system temp directory', () async {
      expect(
          p.isWithin(Directory.systemTemp.resolveSymbolicLinksSync(),
              scratchSpace.tempDir.resolveSymbolicLinksSync()),
          isTrue);
    });

    test('Can read files from a ScratchSpace', () async {
      for (var id in allAssets.keys) {
        var file = scratchSpace.fileFor(id);
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('$id'));
      }
    });

    test('Files in a ScratchSpace have standard dart layout', () async {
      for (var id in allAssets.keys) {
        var file = scratchSpace.fileFor(id);

        var relativeFilePath =
            p.relative(file.path, from: scratchSpace.tempDir.path);
        if (topLevelDir(id.path) == 'lib') {
          var expectedPackagesPath =
              p.join('packages', id.package, p.relative(id.path, from: 'lib'));
          expect(relativeFilePath, equals(expectedPackagesPath));
        } else {
          expect(relativeFilePath, equals(id.path));
        }
      }
    });

    test('Can copy outputs back from the ScratchSpace', () async {
      // Write a fake output to the dir.
      var outputId = new AssetId('myapp', 'lib/output.txt');
      var outputFile = scratchSpace.fileFor(outputId);
      var outputContent = 'test!';
      await outputFile.writeAsString(outputContent);

      var writer = new InMemoryAssetWriter();
      await scratchSpace.copyOutput(outputId, writer);

      expect(writer.assets[outputId], decodedMatches(outputContent));
    });

    test('Can delete a ScratchSpace', () async {
      await scratchSpace.delete();
      for (var id in allAssets.keys) {
        var file = scratchSpace.fileFor(id);
        expect(file.existsSync(), isFalse);
      }
      expect(scratchSpace.tempDir.existsSync(), isFalse);
    });

    test('Can\'t use a ScratchSpace after deleting it', () async {
      // ignore: unawaited_futures
      scratchSpace.delete();
      expect(() => scratchSpace.ensureAssets(allAssets.keys, assetReader),
          throwsStateError);
    });

    test('Can\'t delete a ScratchSpace twice', () async {
      // ignore: unawaited_futures
      scratchSpace.delete();
      expect(scratchSpace.delete, throwsStateError);
    });

    group('regression tests', () {
      test('doesn\'t deadlock when the reader also uses a scratchspace',
          () async {
        // Recursively "reads" from the previous numeric file until it gets
        // to 0, using the scratchSpace.
        var reader = new RecursiveScratchSpaceAssetReader(scratchSpace);
        var first = new AssetId('a', 'lib/100');
        expect(await reader.readAsBytes(first), UTF8.encode('0'));
      });
    });
  });

  test('canonicalUriFor', () {
    expect(canonicalUriFor(new AssetId('a', 'lib/a.dart')),
        equals('package:a/a.dart'));
    expect(canonicalUriFor(new AssetId('a', 'lib/src/a.dart')),
        equals('package:a/src/a.dart'));
    expect(
        canonicalUriFor(new AssetId('a', 'web/a.dart')), equals('web/a.dart'));

    expect(
        () => canonicalUriFor(new AssetId('a', 'a.dart')), throwsArgumentError);
    expect(() => canonicalUriFor(new AssetId('a', 'lib/../a.dart')),
        throwsArgumentError);
    expect(() => canonicalUriFor(new AssetId('a', 'web/../a.dart')),
        throwsArgumentError);
  });
}

/// An asset reader that uses a scratch space to implement `readAsBytes`, used
/// for the deadlock regression test.
class RecursiveScratchSpaceAssetReader implements AssetReader {
  final ScratchSpace scratchSpace;

  RecursiveScratchSpaceAssetReader(this.scratchSpace);

  @override
  canRead(_) async => true;

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    var idNum = int.parse(p.split(id.path).last);
    if (idNum > 0) {
      var readFrom = new AssetId(id.package, 'lib/${idNum - 1}');
      await scratchSpace.ensureAssets([readFrom], this);
      return scratchSpace.fileFor(readFrom).readAsBytes();
    } else {
      return UTF8.encode('0');
    }
  }

  @override
  findAssets(_) => throw new UnimplementedError();

  @override
  readAsString(_, {encoding}) => throw new UnimplementedError();
}
