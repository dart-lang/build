// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_runner/src/build_plan/build_configs.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/io/asset_finder.dart';
import 'package:build_runner/src/io/asset_path_provider.dart';
import 'package:build_runner/src/io/asset_tracker.dart';
import 'package:build_runner/src/io/filesystem.dart';
import 'package:build_runner/src/io/filesystem_cache.dart';
import 'package:build_runner/src/io/generated_asset_hider.dart';
import 'package:build_runner/src/io/reader_writer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:watcher/watcher.dart';

void main() {
  group('AssetTracker.collectChanges()', () {
    late AssetTracker assetTracker;
    late AssetGraph assetGraph;
    late ReaderWriter reader;
    late BuildPackages buildPackages;
    late BuildConfigs buildConfigs;

    setUp(() async {
      await d.dir('a', [
        d.dir('web', [d.file('a.txt', 'hello')]),
        d.dir('.dart_tool', [
          d.file(
            'package_config.json',
            jsonEncode({'configVersion': 2, 'packages': <Object>[]}),
          ),
        ]),
      ]).create();
      buildPackages = BuildPackages.singlePackageBuild('a', [
        BuildPackage(
          name: 'a',
          path: p.join(d.sandbox, 'a'),
          languageVersion: LanguageVersion(2, 6),
          watch: true,
          isOutput: true,
        ),
      ]);
      reader = ReaderWriter(buildPackages);
      final aId = AssetId('a', 'web/a.txt');
      assetGraph = await AssetGraph.build(
        BuildPhases([]),
        {aId},
        buildPackages,
        reader,
      );
      // We need to pre-emptively assign a digest so we determine that the
      // node is "interesting".
      final digest = await reader.digest(aId);
      assetGraph.updateNode(aId, (nodeBuilder) {
        nodeBuilder.digest = digest;
      });

      buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['web/**'].build(),
        ),
      );
      assetTracker = AssetTracker(reader, buildPackages, buildConfigs);
      final updates = await assetTracker.collectChanges(assetGraph);
      await assetGraph.updateAndInvalidate(
        BuildPhases([]),
        updates,
        (_) async {},
        reader,
      );
      // We should see no changes initially other than new sdk sources
      expect(
        updates..removeWhere(
          (id, type) => id.package == r'$sdk' && type == ChangeType.ADD,
        ),
        isEmpty,
      );
    });

    test('Collects file edits', () async {
      File(p.join(d.sandbox, 'a', 'web', 'a.txt')).writeAsStringSync('goodbye');

      expect(await assetTracker.collectChanges(assetGraph), {
        AssetId('a', 'web/a.txt'): ChangeType.MODIFY,
      });
    });

    test('Collects new files', () async {
      File(p.join(d.sandbox, 'a', 'web', 'b.txt')).writeAsStringSync('yo!');

      expect(await assetTracker.collectChanges(assetGraph), {
        AssetId('a', 'web/b.txt'): ChangeType.ADD,
      });
    });

    test('Collects deleted files', () async {
      File(p.join(d.sandbox, 'a', 'web', 'a.txt')).deleteSync();

      expect(await assetTracker.collectChanges(assetGraph), {
        AssetId('a', 'web/a.txt'): ChangeType.REMOVE,
      });
    });
    test('Handles files deleted before digest is checked', () async {
      final throwDigestReader = _ThrowingDigestReaderWriter(reader);
      final failingAssetTracker = AssetTracker(
        throwDigestReader,
        buildPackages,
        buildConfigs,
      );

      expect(await failingAssetTracker.collectChanges(assetGraph), {
        AssetId('a', 'web/a.txt'): ChangeType.REMOVE,
      });
    });
  });
}

class _ThrowingDigestReaderWriter implements ReaderWriter {
  final ReaderWriter _delegate;

  _ThrowingDigestReaderWriter(this._delegate);

  @override
  AssetFinder get assetFinder => _delegate.assetFinder;
  @override
  AssetPathProvider get assetPathProvider => _delegate.assetPathProvider;
  @override
  GeneratedAssetHider get generatedAssetHider => _delegate.generatedAssetHider;
  @override
  Filesystem get filesystem => _delegate.filesystem;
  @override
  FilesystemCache get cache => _delegate.cache;
  @override
  void Function(AssetId)? get onDelete => _delegate.onDelete;

  @override
  Future<bool> canRead(AssetId id) => _delegate.canRead(id);
  @override
  Future<List<int>> readAsBytes(AssetId id) => _delegate.readAsBytes(id);
  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) =>
      _delegate.readAsString(id, encoding: encoding);
  @override
  Future<void> writeAsBytes(AssetId id, List<int> bytes) =>
      _delegate.writeAsBytes(id, bytes);
  @override
  Future<void> writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) => _delegate.writeAsString(id, contents, encoding: encoding);
  @override
  Future<void> delete(AssetId id) => _delegate.delete(id);
  @override
  Future<void> deleteDirectory(AssetId id) => _delegate.deleteDirectory(id);
  @override
  Stream<AssetId> findAssets(Glob glob, {String package = ''}) =>
      _delegate.findAssets(glob);
  @override
  ReaderWriter copyWith({
    FilesystemCache? cache,
    GeneratedAssetHider? generatedAssetHider,
    void Function(AssetId)? onDelete,
  }) {
    return _delegate.copyWith(
      cache: cache,
      generatedAssetHider: generatedAssetHider,
      onDelete: onDelete,
    );
  }

  @override
  Future<Digest> digest(AssetId id) {
    throw AssetNotFoundException(id);
  }
}
