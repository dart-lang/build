// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build_runner/src/internal.dart';
import 'package:build_test/src/fake_watcher.dart';
import 'package:build_test/src/internal_test_reader_writer.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  group('InMemoryAssetReaderWriter', () {
    final packageName = 'some_pkg';
    final libAsset = AssetId(packageName, 'lib/some_pkg.dart');
    final testAsset = AssetId(packageName, 'test/some_test.dart');

    late InternalTestReaderWriter readerWriter;

    setUp(() {
      readerWriter = InternalTestReaderWriter(outputRootPackage: packageName)
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

  group('FakeWatcher events', () {
    final rootPackage = 'root_pkg';
    late InternalTestReaderWriter readerWriter;
    late FakeWatcher rootWatcher;
    late FakeWatcher depWatcher;
    late List<WatchEvent> rootEvents;
    late List<WatchEvent> depEvents;
    late StreamSubscription<WatchEvent> rootSub;
    late StreamSubscription<WatchEvent> depSub;

    setUp(() {
      FakeWatcher.watchers.clear();
      readerWriter = InternalTestReaderWriter(outputRootPackage: rootPackage);
      rootWatcher = FakeWatcher(p.absolute(rootPackage));
      depWatcher = FakeWatcher(p.absolute('dep_pkg'));
      rootEvents = [];
      depEvents = [];
      rootSub = rootWatcher.events.listen(rootEvents.add);
      depSub = depWatcher.events.listen(depEvents.add);
    });

    tearDown(() async {
      await rootSub.cancel();
      await depSub.cancel();
      FakeWatcher.watchers.clear();
    });

    test('notifies package path writes and deletes', () async {
      final id = AssetId(rootPackage, 'lib/a.txt');
      await readerWriter.writeAsString(id, 'first');
      await pumpEventQueue();
      expect(rootEvents.map((e) => (e.type, e.path)), [
        (ChangeType.ADD, p.absolute(rootPackage, 'lib/a.txt')),
      ]);

      await readerWriter.writeAsString(id, 'second');
      await pumpEventQueue();
      expect(rootEvents.map((e) => (e.type, e.path)), [
        (ChangeType.ADD, p.absolute(rootPackage, 'lib/a.txt')),
        (ChangeType.MODIFY, p.absolute(rootPackage, 'lib/a.txt')),
      ]);

      await readerWriter.delete(AssetFile.atPackagePath(id));
      await pumpEventQueue();
      expect(rootEvents.map((e) => (e.type, e.path)), [
        (ChangeType.ADD, p.absolute(rootPackage, 'lib/a.txt')),
        (ChangeType.MODIFY, p.absolute(rootPackage, 'lib/a.txt')),
        (ChangeType.REMOVE, p.absolute(rootPackage, 'lib/a.txt')),
      ]);
    });

    test('notifies artifact tree writes and deletes', () async {
      final depId = AssetId('dep_pkg', 'lib/dep.txt');
      final expectedArtifactPath = p.absolute(
        rootPackage,
        '.dart_tool/build/generated/dep_pkg/lib/dep.txt',
      );

      await readerWriter.writeAsString(depId, 'content', inArtifactTree: true);
      await pumpEventQueue();
      expect(rootEvents.map((e) => (e.type, e.path)), [
        (ChangeType.ADD, expectedArtifactPath),
      ]);
      expect(depEvents, isEmpty);

      await readerWriter.writeAsString(depId, 'updated', inArtifactTree: true);
      await pumpEventQueue();
      expect(rootEvents.map((e) => (e.type, e.path)), [
        (ChangeType.ADD, expectedArtifactPath),
        (ChangeType.MODIFY, expectedArtifactPath),
      ]);
      expect(depEvents, isEmpty);

      await readerWriter.delete(AssetFile.inArtifactTree(depId));
      await pumpEventQueue();
      expect(rootEvents.map((e) => (e.type, e.path)), [
        (ChangeType.ADD, expectedArtifactPath),
        (ChangeType.MODIFY, expectedArtifactPath),
        (ChangeType.REMOVE, expectedArtifactPath),
      ]);
      expect(depEvents, isEmpty);
    });

    test(
      'notifies package path when forceToPackagePathsForTesting is true',
      () async {
        readerWriter = InternalTestReaderWriter(
          outputRootPackage: rootPackage,
          forceToPackagePathsForTesting: true,
        );
        final depId = AssetId('dep_pkg', 'lib/dep.txt');
        final expectedPackagePath = p.absolute('dep_pkg', 'lib/dep.txt');

        await readerWriter.writeAsString(
          depId,
          'content',
          inArtifactTree: true,
        );
        await pumpEventQueue();
        expect(depEvents.map((e) => (e.type, e.path)), [
          (ChangeType.ADD, expectedPackagePath),
        ]);
        expect(rootEvents, isEmpty);

        await readerWriter.delete(AssetFile.inArtifactTree(depId));
        await pumpEventQueue();
        expect(depEvents.map((e) => (e.type, e.path)), [
          (ChangeType.ADD, expectedPackagePath),
          (ChangeType.REMOVE, expectedPackagePath),
        ]);
        expect(rootEvents, isEmpty);
      },
    );
  });
}
