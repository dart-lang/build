// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';
import 'package:build_runner/src/generate/watch_impl.dart' as watch_impl;
import 'package:build_test/build_test.dart';

import '../common/common.dart';
import '../common/package_graphs.dart';

void main() {
  /// Basic phases/phase groups which get used in many tests
  final copyABuildApplication = applyToRoot(new CopyBuilder());
  final defaultBuilderOptions = const BuilderOptions(const {});

  group('watch', () {
    setUp(() {
      _terminateWatchController = new StreamController();
    });

    tearDown(() {
      FakeWatcher.watchers.clear();
      return terminateWatch();
    });

    group('simple', () {
      test('rebuilds on file updates', () async {
        var writer = new InMemoryRunnerAssetWriter();
        var buildState = await startWatch(
            [copyABuildApplication], {'a|web/a.txt': 'a'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

        await writer.writeAsString(makeAssetId('a|web/a.txt'), 'b');
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.MODIFY, path.absolute('a', 'web', 'a.txt')));

        result = await results.next;
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'b'}, writer: writer);
      });

      test('rebuilds on new files', () async {
        var writer = new InMemoryRunnerAssetWriter();
        var buildState = await startWatch(
            [copyABuildApplication], {'a|web/a.txt': 'a'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

        await writer.writeAsString(makeAssetId('a|web/b.txt'), 'b');
        FakeWatcher.notifyWatchers(
            new WatchEvent(ChangeType.ADD, path.absolute('a', 'web', 'b.txt')));

        result = await results.next;
        checkBuild(result, outputs: {'a|web/b.txt.copy': 'b'}, writer: writer);
        // Previous outputs should still exist.
        expect(writer.assets[makeAssetId('a|web/a.txt.copy')],
            decodedMatches('a'));
      });

      test('rebuilds on deleted files', () async {
        var writer = new InMemoryRunnerAssetWriter();
        var buildState = await startWatch([
          copyABuildApplication
        ], {
          'a|web/a.txt': 'a',
          'a|web/b.txt': 'b',
        }, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {'a|web/a.txt.copy': 'a', 'a|web/b.txt.copy': 'b'},
            writer: writer);

        // Don't call writer.delete, that has side effects.
        writer.assets.remove(makeAssetId('a|web/a.txt'));
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.REMOVE, path.absolute('a', 'web', 'a.txt')));

        result = await results.next;

        // Shouldn't rebuild anything, no outputs.
        checkBuild(result, outputs: {}, writer: writer);

        // The old output file should no longer exist either.
        expect(writer.assets[makeAssetId('a|web/a.txt.copy')], isNull);
        // Previous outputs should still exist.
        expect(writer.assets[makeAssetId('a|web/b.txt.copy')],
            decodedMatches('b'));
      });

      test('rebuilds properly update asset_graph.json', () async {
        var writer = new InMemoryRunnerAssetWriter();
        var buildState = await startWatch([copyABuildApplication],
            {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {'a|web/a.txt.copy': 'a', 'a|web/b.txt.copy': 'b'},
            writer: writer);

        await writer.writeAsString(makeAssetId('a|web/c.txt'), 'c');
        FakeWatcher.notifyWatchers(
            new WatchEvent(ChangeType.ADD, path.absolute('a', 'web', 'c.txt')));

        await writer.writeAsString(makeAssetId('a|web/b.txt'), 'b2');
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.MODIFY, path.absolute('a', 'web', 'b.txt')));

        // Don't call writer.delete, that has side effects.
        writer.assets.remove(makeAssetId('a|web/a.txt'));
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.REMOVE, path.absolute('a', 'web', 'a.txt')));

        result = await results.next;
        checkBuild(result,
            outputs: {'a|web/b.txt.copy': 'b2', 'a|web/c.txt.copy': 'c'},
            writer: writer);

        var serialized = JSON.decode(
                UTF8.decode(writer.assets[makeAssetId('a|$assetGraphPath')]))
            as Map;
        var cachedGraph = new AssetGraph.deserialize(serialized);

        var expectedGraph =
            await AssetGraph.build([], new Set(), new Set(), 'a', null);

        var builderOptionsId = makeAssetId('a|Phase0.builderOptions');
        var builderOptionsNode = new BuilderOptionsAssetNode(builderOptionsId,
            computeBuilderOptionsDigest(defaultBuilderOptions));
        expectedGraph.add(builderOptionsNode);

        var bCopyNode = new GeneratedAssetNode(makeAssetId('a|web/b.txt.copy'),
            phaseNumber: 0,
            primaryInput: makeAssetId('a|web/b.txt'),
            needsUpdate: false,
            wasOutput: true,
            builderOptionsId: builderOptionsId,
            lastKnownDigest: computeDigest('b2'),
            inputs: [makeAssetId('a|web/b.txt')],
            isHidden: false);
        builderOptionsNode.outputs.add(bCopyNode.id);
        expectedGraph.add(bCopyNode);
        expectedGraph.add(
            makeAssetNode('a|web/b.txt', [bCopyNode.id], computeDigest('b2')));

        var cCopyNode = new GeneratedAssetNode(makeAssetId('a|web/c.txt.copy'),
            phaseNumber: 0,
            primaryInput: makeAssetId('a|web/c.txt'),
            needsUpdate: false,
            wasOutput: true,
            builderOptionsId: builderOptionsId,
            lastKnownDigest: computeDigest('c'),
            inputs: [makeAssetId('a|web/c.txt')],
            isHidden: false);
        builderOptionsNode.outputs.add(cCopyNode.id);
        expectedGraph.add(cCopyNode);
        expectedGraph.add(
            makeAssetNode('a|web/c.txt', [cCopyNode.id], computeDigest('c')));

        expect(cachedGraph, equalsAssetGraph(expectedGraph));
      });

      test('ignores events from nested packages', () async {
        var writer = new InMemoryRunnerAssetWriter();
        final packageGraph = buildPackageGraph({
          rootPackage('a', path: path.absolute('a')): ['b'],
          package('b', path: path.absolute('a', 'b')): []
        });

        var buildState = await startWatch([
          copyABuildApplication,
        ], {
          'a|web/a.txt': 'a',
          'b|web/b.txt': 'b'
        }, writer, packageGraph: packageGraph);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        // Should ignore the files under the `b` package, even though they
        // match the input set.
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

        await writer.writeAsString(makeAssetId('a|web/a.txt'), 'b');
        await writer.writeAsString(makeAssetId('b|web/b.txt'), 'c');
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.MODIFY, path.absolute('a', 'b', 'web', 'a.txt')));
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.MODIFY, path.absolute('a', 'web', 'a.txt')));

        result = await results.next;
        // Ignores the modification under the `b` package, even though it
        // matches the input set.
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'b'}, writer: writer);
      });

      test('rebuilds on file updates during first build', () async {
        var blocker = new Completer<Null>();
        var buildAction =
            applyToRoot(new CopyBuilder(blockUntil: blocker.future));
        var writer = new InMemoryRunnerAssetWriter();
        var buildState =
            await startWatch([buildAction], {'a|web/a.txt': 'a'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.MODIFY, path.absolute('a', 'web', 'a.txt')));
        blocker.complete();

        var result = await results.next;
        // TODO: Move this up above the call to notifyWatchers once
        // https://github.com/dart-lang/build/issues/526 is fixed.
        await writer.writeAsString(makeAssetId('a|web/a.txt'), 'b');

        checkBuild(result, outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

        result = await results.next;
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'b'}, writer: writer);
      });
    });

    group('multiple phases', () {
      test('edits propagate through all phases', () async {
        var buildActions = [
          copyABuildApplication,
          applyToRoot(
              new CopyBuilder(inputExtension: '.copy', extension: 'copy.copy'))
        ];

        var writer = new InMemoryRunnerAssetWriter();
        var buildState =
            await startWatch(buildActions, {'a|web/a.txt': 'a'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {'a|web/a.txt.copy': 'a', 'a|web/a.txt.copy.copy': 'a'},
            writer: writer);

        await writer.writeAsString(makeAssetId('a|web/a.txt'), 'b');
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.MODIFY, path.absolute('a', 'web', 'a.txt')));

        result = await results.next;
        checkBuild(result,
            outputs: {'a|web/a.txt.copy': 'b', 'a|web/a.txt.copy.copy': 'b'},
            writer: writer);
      });

      test('adds propagate through all phases', () async {
        var buildActions = [
          copyABuildApplication,
          applyToRoot(
              new CopyBuilder(inputExtension: '.copy', extension: 'copy.copy'))
        ];

        var writer = new InMemoryRunnerAssetWriter();
        var buildState =
            await startWatch(buildActions, {'a|web/a.txt': 'a'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {'a|web/a.txt.copy': 'a', 'a|web/a.txt.copy.copy': 'a'},
            writer: writer);

        await writer.writeAsString(makeAssetId('a|web/b.txt'), 'b');
        FakeWatcher.notifyWatchers(
            new WatchEvent(ChangeType.ADD, path.absolute('a', 'web', 'b.txt')));

        result = await results.next;
        checkBuild(result,
            outputs: {'a|web/b.txt.copy': 'b', 'a|web/b.txt.copy.copy': 'b'},
            writer: writer);
        // Previous outputs should still exist.
        expect(writer.assets[makeAssetId('a|web/a.txt.copy')],
            decodedMatches('a'));
        expect(writer.assets[makeAssetId('a|web/a.txt.copy.copy')],
            decodedMatches('a'));
      });

      test('deletes propagate through all phases', () async {
        var buildActions = [
          copyABuildApplication,
          applyToRoot(
              new CopyBuilder(inputExtension: '.copy', extension: 'copy.copy'))
        ];

        var writer = new InMemoryRunnerAssetWriter();
        var buildState = await startWatch(
            buildActions, {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {
              'a|web/a.txt.copy': 'a',
              'a|web/a.txt.copy.copy': 'a',
              'a|web/b.txt.copy': 'b',
              'a|web/b.txt.copy.copy': 'b'
            },
            writer: writer);

        // Don't call writer.delete, that has side effects.
        writer.assets.remove(makeAssetId('a|web/a.txt'));

        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.REMOVE, path.absolute('a', 'web', 'a.txt')));

        result = await results.next;
        // Shouldn't rebuild anything, no outputs.
        checkBuild(result, outputs: {}, writer: writer);

        // Derived outputs should no longer exist.
        expect(writer.assets[makeAssetId('a|web/a.txt.copy')], isNull);
        expect(writer.assets[makeAssetId('a|web/a.txt.copy.copy')], isNull);
        // Other outputs should still exist.
        expect(writer.assets[makeAssetId('a|web/b.txt.copy')],
            decodedMatches('b'));
        expect(writer.assets[makeAssetId('a|web/b.txt.copy.copy')],
            decodedMatches('b'));
      });

      test('deleted generated outputs are regenerated', () async {
        var buildActions = [
          copyABuildApplication,
          applyToRoot(
              new CopyBuilder(inputExtension: '.copy', extension: 'copy.copy'))
        ];

        var writer = new InMemoryRunnerAssetWriter();
        var buildState =
            await startWatch(buildActions, {'a|web/a.txt': 'a'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {
              'a|web/a.txt.copy': 'a',
              'a|web/a.txt.copy.copy': 'a',
            },
            writer: writer);

        // Don't call writer.delete, that has side effects.
        writer.assets.remove(makeAssetId('a|web/a.txt.copy'));
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.REMOVE, path.absolute('a', 'web', 'a.txt.copy')));

        result = await results.next;
        // Should rebuild the generated asset, but not its outputs because its
        // content didn't change.
        checkBuild(result,
            outputs: {
              'a|web/a.txt.copy': 'a',
            },
            writer: writer);
      });
    });

    /// Tests for updates
    group('secondary dependency', () {
      test('of an output file is edited', () async {
        var buildActions = [
          applyToRoot(new CopyBuilder(
              inputExtension: '.a',
              extension: 'a.copy',
              copyFromAsset: makeAssetId('a|web/file.b')))
        ];

        var writer = new InMemoryRunnerAssetWriter();
        var buildState = await startWatch(
            buildActions, {'a|web/file.a': 'a', 'a|web/file.b': 'b'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result, outputs: {'a|web/file.a.copy': 'b'}, writer: writer);

        await writer.writeAsString(makeAssetId('a|web/file.b'), 'c');
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.MODIFY, path.absolute('a', 'web', 'file.b')));

        result = await results.next;
        checkBuild(result, outputs: {'a|web/file.a.copy': 'c'}, writer: writer);
      });

      test(
          'of an output which is derived from another generated file is edited',
          () async {
        var buildActions = [
          applyToRoot(
              new CopyBuilder(inputExtension: '.a', extension: 'a.copy')),
          applyToRoot(new CopyBuilder(
              copyFromAsset: makeAssetId('a|web/file.b'),
              inputExtension: '.a.copy',
              extension: 'a.copy.copy'))
        ];

        var writer = new InMemoryRunnerAssetWriter();
        var buildState = await startWatch(
            buildActions, {'a|web/file.a': 'a', 'a|web/file.b': 'b'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {'a|web/file.a.copy': 'a', 'a|web/file.a.copy.copy': 'b'},
            writer: writer);

        await writer.writeAsString(makeAssetId('a|web/file.b'), 'c');
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.MODIFY, path.absolute('a', 'web', 'file.b')));

        result = await results.next;
        checkBuild(result,
            outputs: {'a|web/file.a.copy.copy': 'c'}, writer: writer);
      });
    });
  });
}

final _debounceDelay = new Duration(milliseconds: 10);
StreamController _terminateWatchController;

/// Start watching files and running builds.
Future<BuildState> startWatch(List<BuilderApplication> builders,
    Map<String, String> inputs, InMemoryRunnerAssetWriter writer,
    {PackageGraph packageGraph}) {
  inputs.forEach((serializedId, contents) {
    writer.writeAsString(makeAssetId(serializedId), contents);
  });
  final reader = new InMemoryRunnerAssetReader.shareAssetCache(writer.assets);
  packageGraph ??=
      buildPackageGraph({rootPackage('a', path: path.absolute('a')): []});
  final watcherFactory = (String path) => new FakeWatcher(path);

  return watch_impl.watch(builders,
      deleteFilesByDefault: true,
      debounceDelay: _debounceDelay,
      directoryWatcherFactory: watcherFactory,
      reader: reader,
      writer: writer,
      packageGraph: packageGraph,
      terminateEventStream: _terminateWatchController.stream,
      logLevel: Level.OFF,
      skipBuildScriptCheck: true);
}

/// Tells the program to stop watching files and terminate.
Future terminateWatch() {
  assert(_terminateWatchController != null);

  /// Can add any type of event.
  _terminateWatchController.add(null);
  return _terminateWatchController.close();
}
