// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
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

void main() {
  /// Basic phases/phase groups which get used in many tests
  final copyABuildAction = new BuildAction(new CopyBuilder(), 'a');

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
        var results = new StreamQueue(
            startWatch([copyABuildAction], {'a|web/a.txt': 'a'}, writer));

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
        var results = new StreamQueue(
            startWatch([copyABuildAction], {'a|web/a.txt': 'a'}, writer));

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
        var results = new StreamQueue(startWatch([
          copyABuildAction
        ], {
          'a|web/a.txt': 'a',
          'a|web/b.txt': 'b',
        }, writer));

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
        var results = new StreamQueue(startWatch([copyABuildAction],
            {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'}, writer));

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

        var expectedGraph = await AssetGraph.build([], new Set(), 'a', null);
        var bCopyNode = new GeneratedAssetNode(null, makeAssetId('a|web/b.txt'),
            false, true, makeAssetId('a|web/b.txt.copy'),
            lastKnownDigest: computeDigest('b2'),
            inputs: [makeAssetId('a|web/b.txt')]);
        expectedGraph.add(bCopyNode);
        expectedGraph.add(
            makeAssetNode('a|web/b.txt', [bCopyNode.id], computeDigest('b2')));
        var cCopyNode = new GeneratedAssetNode(null, makeAssetId('a|web/c.txt'),
            false, true, makeAssetId('a|web/c.txt.copy'),
            lastKnownDigest: computeDigest('c'),
            inputs: [makeAssetId('a|web/c.txt')]);
        expectedGraph.add(cCopyNode);
        expectedGraph.add(
            makeAssetNode('a|web/c.txt', [cCopyNode.id], computeDigest('c')));

        expect(cachedGraph, equalsAssetGraph(expectedGraph));
      });

      test('ignores events from nested packages', () async {
        var writer = new InMemoryRunnerAssetWriter();
        var packageA = new PackageNode(
            'a', '0.1.0', PackageDependencyType.path, path.absolute('a'),
            includes: ['**']);
        var packageB = new PackageNode(
            'b', '0.1.0', PackageDependencyType.path, path.absolute('a', 'b'));
        packageA.dependencies.add(packageB);
        var packageGraph = new PackageGraph.fromRoot(packageA);

        var results = new StreamQueue(startWatch([
          copyABuildAction,
        ], {
          'a|web/a.txt': 'a',
          'b|web/b.txt': 'b'
        }, writer, packageGraph: packageGraph));

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
            new BuildAction(new CopyBuilder(blockUntil: blocker.future), 'a');
        var writer = new InMemoryRunnerAssetWriter();
        var results = new StreamQueue(
            startWatch([buildAction], {'a|web/a.txt': 'a'}, writer));

        await new Future(() {});
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
          copyABuildAction,
          new BuildAction(new CopyBuilder(), 'a', inputs: ['**/*.copy'])
        ];

        var writer = new InMemoryRunnerAssetWriter();
        var results = new StreamQueue(
            startWatch(buildActions, {'a|web/a.txt': 'a'}, writer));

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
          copyABuildAction,
          new BuildAction(new CopyBuilder(), 'a', inputs: ['**/*.copy'])
        ];

        var writer = new InMemoryRunnerAssetWriter();
        var results = new StreamQueue(
            startWatch(buildActions, {'a|web/a.txt': 'a'}, writer));

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
          copyABuildAction,
          new BuildAction(new CopyBuilder(), 'a', inputs: ['**/*.copy'])
        ];

        var writer = new InMemoryRunnerAssetWriter();
        var results = new StreamQueue(startWatch(
            buildActions, {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'}, writer));

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
          copyABuildAction,
          new BuildAction(new CopyBuilder(), 'a', inputs: ['**/*.copy']),
        ];

        var writer = new InMemoryRunnerAssetWriter();
        var results = new StreamQueue(
            startWatch(buildActions, {'a|web/a.txt': 'a'}, writer));

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
          new BuildAction(
              new CopyBuilder(copyFromAsset: makeAssetId('a|web/b.txt')), 'a',
              inputs: ['web/a.txt'])
        ];

        var writer = new InMemoryRunnerAssetWriter();
        var results = new StreamQueue(startWatch(
            buildActions, {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'}, writer));

        var result = await results.next;
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'b'}, writer: writer);

        await writer.writeAsString(makeAssetId('a|web/b.txt'), 'c');
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.MODIFY, path.absolute('a', 'web', 'b.txt')));

        result = await results.next;
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'c'}, writer: writer);
      });

      test(
          'of an output which is derived from another generated file is edited',
          () async {
        var buildActions = [
          new BuildAction(new CopyBuilder(), 'a', inputs: ['web/a.txt']),
          new BuildAction(
              new CopyBuilder(copyFromAsset: makeAssetId('a|web/b.txt')), 'a',
              inputs: ['web/a.txt.copy'])
        ];

        var writer = new InMemoryRunnerAssetWriter();
        var results = new StreamQueue(startWatch(
            buildActions, {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'}, writer));

        var result = await results.next;
        checkBuild(result,
            outputs: {'a|web/a.txt.copy': 'a', 'a|web/a.txt.copy.copy': 'b'},
            writer: writer);

        await writer.writeAsString(makeAssetId('a|web/b.txt'), 'c');
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.MODIFY, path.absolute('a', 'web', 'b.txt')));

        result = await results.next;
        checkBuild(result,
            outputs: {'a|web/a.txt.copy.copy': 'c'}, writer: writer);
      });
    });
  });
}

final _debounceDelay = new Duration(milliseconds: 10);
StreamController _terminateWatchController;

/// Start watching files and running builds.
Stream<BuildResult> startWatch(List<BuildAction> buildActions,
    Map<String, String> inputs, InMemoryRunnerAssetWriter writer,
    {PackageGraph packageGraph}) {
  var buildResults = new StreamController<BuildResult>.broadcast();
  inputs.forEach((serializedId, contents) {
    writer.writeAsString(makeAssetId(serializedId), contents);
  });
  final actualAssets = writer.assets;
  final reader = new InMemoryRunnerAssetReader(actualAssets);
  if (packageGraph == null) {
    packageGraph ??= new PackageGraph.fromRoot(new PackageNode.noPubspec('a',
        path: path.absolute('a'), includes: ['**']));
  }
  final watcherFactory = (String path) => new FakeWatcher(path);

  var buildState = watch_impl.watch(buildActions,
      deleteFilesByDefault: true,
      debounceDelay: _debounceDelay,
      directoryWatcherFactory: watcherFactory,
      reader: reader,
      writer: writer,
      packageGraph: packageGraph,
      terminateEventStream: _terminateWatchController.stream,
      logLevel: Level.OFF,
      skipBuildScriptCheck: true);
  buildState
      .then((s) => buildResults.addStream(s.buildResults))
      .then((_) => buildResults.close());
  return buildResults.stream;
}

/// Tells the program to stop watching files and terminate.
Future terminateWatch() {
  assert(_terminateWatchController != null);

  /// Can add any type of event.
  _terminateWatchController.add(null);
  return _terminateWatchController.close();
}
