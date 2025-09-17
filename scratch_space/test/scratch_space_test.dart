// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';
import 'package:scratch_space/src/util.dart';
import 'package:test/test.dart';

void main() {
  group('ScratchSpace', () {
    late ScratchSpace scratchSpace;
    late TestReaderWriter readerWriter;

    final allAssets = [
      'dep|lib/dep.dart',
      'myapp|lib/myapp.dart',
      'myapp|web/main.dart',
    ].fold<Map<AssetId, Uint8List>>({}, (assets, serializedId) {
      assets[AssetId.parse(serializedId)] = Uint8List.fromList(
        serializedId.codeUnits,
      );
      return assets;
    });

    setUp(() async {
      scratchSpace = ScratchSpace();
      readerWriter = TestReaderWriter();
      for (final asset in allAssets.entries) {
        readerWriter.testing.writeBytes(asset.key, asset.value);
      }
      await scratchSpace.ensureAssets(allAssets.keys, readerWriter);
    });

    tearDown(() async {
      if (scratchSpace.exists) await scratchSpace.delete();
    });

    test('Creates a directory under the system temp directory', () async {
      expect(
        p.isWithin(
          Directory.systemTemp.resolveSymbolicLinksSync(),
          scratchSpace.tempDir.resolveSymbolicLinksSync(),
        ),
        isTrue,
      );
    });

    test('Can read files from a ScratchSpace', () async {
      for (final id in allAssets.keys) {
        final file = scratchSpace.fileFor(id);
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('$id'));
      }
    });

    test('Files in a ScratchSpace have standard dart layout', () async {
      for (final id in allAssets.keys) {
        final file = scratchSpace.fileFor(id);

        final relativeFilePath = p.relative(
          file.path,
          from: scratchSpace.tempDir.path,
        );
        if (topLevelDir(id.path) == 'lib') {
          final expectedPackagesPath = p.join(
            'packages',
            id.package,
            p.relative(id.path, from: 'lib'),
          );
          expect(relativeFilePath, equals(expectedPackagesPath));
        } else {
          expect(relativeFilePath, equals(p.normalize(id.path)));
        }
      }
    });

    test('Can copy outputs back from the ScratchSpace', () async {
      // Write a fake output to the dir.
      final outputId = AssetId('myapp', 'lib/output.txt');
      final outputFile = scratchSpace.fileFor(outputId);
      final outputContent = 'test!';
      await outputFile.writeAsString(outputContent);

      final writer = TestReaderWriter();
      await scratchSpace.copyOutput(outputId, writer);

      expect(writer.testing.readString(outputId), outputContent);
    });

    test('Can delete a ScratchSpace', () async {
      await scratchSpace.delete();
      for (final id in allAssets.keys) {
        final file = scratchSpace.fileFor(id);
        expect(file.existsSync(), isFalse);
      }
      expect(scratchSpace.tempDir.existsSync(), isFalse);
    });

    test('Can\'t use a ScratchSpace after deleting it', () async {
      unawaited(scratchSpace.delete());
      expect(
        () => scratchSpace.ensureAssets(allAssets.keys, readerWriter),
        throwsStateError,
      );
    });

    test('Can\'t delete a ScratchSpace twice', () async {
      unawaited(scratchSpace.delete());
      expect(scratchSpace.delete, throwsStateError);
    });

    group('regression tests', () {
      test(
        'doesn\'t deadlock when the reader also uses a scratchspace',
        () async {
          // Recursively "reads" from the previous numeric file until it gets
          // to 0, using the scratchSpace.
          final reader = RecursiveScratchSpaceAssetReader(scratchSpace);
          final first = AssetId('a', 'lib/100');
          expect(await reader.readAsBytes(first), utf8.encode('0'));
        },
      );
    });
  });

  test('canonicalUriFor', () {
    expect(
      canonicalUriFor(AssetId('a', 'lib/a.dart')),
      equals('package:a/a.dart'),
    );
    expect(
      canonicalUriFor(AssetId('a', 'lib/src/a.dart')),
      equals('package:a/src/a.dart'),
    );
    expect(canonicalUriFor(AssetId('a', 'web/a.dart')), equals('web/a.dart'));
    expect(canonicalUriFor(AssetId('a', 'a.dart')), equals('a.dart'));

    expect(
      () => canonicalUriFor(AssetId('a', 'lib/../../a.dart')),
      throwsArgumentError,
    );
    expect(
      () => canonicalUriFor(AssetId('a', 'web/../../a.dart')),
      throwsArgumentError,
    );
  });
}

/// An asset reader that uses a scratch space to implement `readAsBytes`, used
/// for the deadlock regression test.
class RecursiveScratchSpaceAssetReader implements AssetReader {
  final ScratchSpace scratchSpace;

  RecursiveScratchSpaceAssetReader(this.scratchSpace);

  @override
  Future<bool> canRead(_) async => true;

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    final idNum = int.parse(p.split(id.path).last);
    if (idNum > 0) {
      final readFrom = AssetId(id.package, 'lib/${idNum - 1}');
      await scratchSpace.ensureAssets([readFrom], this);
      return scratchSpace.fileFor(readFrom).readAsBytes();
    } else {
      return utf8.encode('0');
    }
  }

  @override
  Stream<AssetId> findAssets(_) => throw UnimplementedError();

  @override
  Future<String> readAsString(_, {Encoding encoding = utf8}) =>
      throw UnimplementedError();

  @override
  Future<Digest> digest(AssetId id) async => Digest(await readAsBytes(id));
}
