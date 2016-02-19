// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'package:build/build.dart';
import 'package:build/src/asset_graph/graph.dart';

import '../common/common.dart';

final _watchers = <DirectoryWatcher>[];

main() {
  /// Basic phases/phase groups which get used in many tests
  final copyAPhase = new Phase([new CopyBuilder()], [new InputSet('a')]);
  final copyAPhaseGroup = [
    [copyAPhase]
  ];

  group('watch', () {
    setUp(() {
      _terminateWatchController = new StreamController();
    });

    tearDown(() {
      _watchers.clear();
      return terminateWatch();
    });

    group('simple', () {
      test('rebuilds on file updates', () async {
        var writer = new InMemoryAssetWriter();
        var results = [];
        startWatch(copyAPhaseGroup, {'a|web/a.txt': 'a'}, writer)
            .listen(results.add);

        var result = await nextResult(results);
        checkOutputs({'a|web/a.txt.copy': 'a',}, result, writer.assets);

        await writer.writeAsString(makeAsset('a|web/a.txt', 'b'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.MODIFY, 'a/web/a.txt'));

        result = await nextResult(results);
        checkOutputs({'a|web/a.txt.copy': 'b',}, result, writer.assets);
      });

      test('rebuilds on new files', () async {
        var writer = new InMemoryAssetWriter();
        var results = [];
        startWatch(copyAPhaseGroup, {'a|web/a.txt': 'a'}, writer)
            .listen(results.add);

        var result = await nextResult(results);
        checkOutputs({'a|web/a.txt.copy': 'a',}, result, writer.assets);

        await writer.writeAsString(makeAsset('a|web/b.txt', 'b'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.ADD, 'a/web/b.txt'));

        result = await nextResult(results);
        checkOutputs({'a|web/b.txt.copy': 'b',}, result, writer.assets);
        // Previous outputs should still exist.
        expect(writer.assets[makeAssetId('a|web/a.txt.copy')].value, 'a');
      });

      test('rebuilds on deleted files', () async {
        var writer = new InMemoryAssetWriter();
        var results = [];
        startWatch(copyAPhaseGroup, {'a|web/a.txt': 'a', 'a|web/b.txt': 'b',},
                writer)
            .listen(results.add);

        var result = await nextResult(results);
        checkOutputs({'a|web/a.txt.copy': 'a', 'a|web/b.txt.copy': 'b',},
            result, writer.assets);

        await writer.delete(makeAssetId('a|web/a.txt'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.REMOVE, 'a/web/a.txt'));

        result = await nextResult(results);

        // Shouldn't rebuild anything, no outputs.
        checkOutputs({}, result, writer.assets);

        // The old output file should no longer exist either.
        expect(writer.assets[makeAssetId('a|web/a.txt.copy')], isNull);
        // Previous outputs should still exist.
        expect(writer.assets[makeAssetId('a|web/b.txt.copy')].value, 'b');
      });

      test('rebuilds properly update asset_graph.json', () async {
        var writer = new InMemoryAssetWriter();
        var results = [];
        startWatch(copyAPhaseGroup, {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'},
                writer)
            .listen(results.add);

        var result = await nextResult(results);
        checkOutputs({'a|web/a.txt.copy': 'a', 'a|web/b.txt.copy': 'b',},
            result, writer.assets);

        await writer.writeAsString(makeAsset('a|web/c.txt', 'c'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.ADD, 'a/web/c.txt'));
        await writer.delete(makeAssetId('a|web/a.txt'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.REMOVE, 'a/web/a.txt'));

        result = await nextResult(results);
        checkOutputs({'a|web/c.txt.copy': 'c'}, result, writer.assets);

        var cachedGraph = new AssetGraph.deserialize(JSON.decode(
            writer.assets[makeAssetId('a|.build/asset_graph.json')].value));

        var expectedGraph = new AssetGraph();
        var bCopyNode = makeAssetNode('a|web/b.txt.copy');
        expectedGraph.add(bCopyNode);
        expectedGraph.add(makeAssetNode('a|web/b.txt', [bCopyNode.id]));
        var cCopyNode = makeAssetNode('a|web/c.txt.copy');
        expectedGraph.add(cCopyNode);
        expectedGraph.add(makeAssetNode('a|web/c.txt', [cCopyNode.id]));

        expect(cachedGraph, equalsAssetGraph(expectedGraph));
      });

      test('build fails if script is updated after the first build starts',
          () async {
        var writer = new InMemoryAssetWriter();
        var results = [];
        startWatch(copyAPhaseGroup, {'a|web/a.txt': 'a'}, writer)
            .listen(results.add);

        var result = await nextResult(results);
        checkOutputs({'a|web/a.txt.copy': 'a',}, result, writer.assets);

        /// Pretend like a part of the dart script got updated.
        await writer.writeAsString(makeAsset('test|lib/test.dart', ''),
            lastModified: new DateTime.now().add(new Duration(days: 1)));
        await writer.writeAsString(makeAsset('a|web/a.txt', 'b'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.MODIFY, 'a/web/a.txt'));

        result = await nextResult(results);
        expect(result.status, BuildStatus.Failure);
      });
    });

    group('multiple phases', () {
      test('edits propagate through all phases', () async {
        var phases = [
          [copyAPhase],
          [
            new Phase([
              new CopyBuilder()
            ], [
              new InputSet('a', filePatterns: ['**/*.copy'])
            ]),
          ]
        ];
        var writer = new InMemoryAssetWriter();
        var results = [];
        startWatch(phases, {'a|web/a.txt': 'a'}, writer).listen(results.add);

        var result = await nextResult(results);
        checkOutputs({'a|web/a.txt.copy': 'a', 'a|web/a.txt.copy.copy': 'a'},
            result, writer.assets);

        await writer.writeAsString(makeAsset('a|web/a.txt', 'b'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.MODIFY, 'a/web/a.txt'));

        result = await nextResult(results);
        checkOutputs({'a|web/a.txt.copy': 'b', 'a|web/a.txt.copy.copy': 'b'},
            result, writer.assets);
      });

      test('adds propagate through all phases', () async {
        var phases = [
          [copyAPhase],
          [
            new Phase([
              new CopyBuilder()
            ], [
              new InputSet('a', filePatterns: ['**/*.copy'])
            ]),
          ]
        ];
        var writer = new InMemoryAssetWriter();
        var results = [];
        startWatch(phases, {'a|web/a.txt': 'a'}, writer).listen(results.add);

        var result = await nextResult(results);
        checkOutputs({'a|web/a.txt.copy': 'a', 'a|web/a.txt.copy.copy': 'a'},
            result, writer.assets);

        await writer.writeAsString(makeAsset('a|web/b.txt', 'b'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.ADD, 'a/web/b.txt'));

        result = await nextResult(results);
        checkOutputs({'a|web/b.txt.copy': 'b', 'a|web/b.txt.copy.copy': 'b'},
            result, writer.assets);
        // Previous outputs should still exist.
        expect(writer.assets[makeAssetId('a|web/a.txt.copy')].value, 'a');
        expect(writer.assets[makeAssetId('a|web/a.txt.copy.copy')].value, 'a');
      });

      test('deletes propagate through all phases', () async {
        var phases = [
          [copyAPhase],
          [
            new Phase([
              new CopyBuilder()
            ], [
              new InputSet('a', filePatterns: ['**/*.copy'])
            ]),
          ]
        ];
        var writer = new InMemoryAssetWriter();
        var results = [];
        startWatch(phases, {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'}, writer)
            .listen(results.add);

        var result = await nextResult(results);
        checkOutputs({
          'a|web/a.txt.copy': 'a',
          'a|web/a.txt.copy.copy': 'a',
          'a|web/b.txt.copy': 'b',
          'a|web/b.txt.copy.copy': 'b'
        }, result, writer.assets);

        await writer.delete(makeAssetId('a|web/a.txt'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.REMOVE, 'a/web/a.txt'));

        result = await nextResult(results);
        // Shouldn't rebuild anything, no outputs.
        checkOutputs({}, result, writer.assets);

        // Derived outputs should no longer exist.
        expect(writer.assets[makeAssetId('a|web/a.txt.copy')], isNull);
        expect(writer.assets[makeAssetId('a|web/a.txt.copy.copy')], isNull);
        // Other outputs should still exist.
        expect(writer.assets[makeAssetId('a|web/b.txt.copy')].value, 'b');
        expect(writer.assets[makeAssetId('a|web/b.txt.copy.copy')].value, 'b');
      });
    });

    /// Tests for updates
    group('secondary dependency', () {
      test('of an output file is edited', () async {
        var phases = [
          [
            new Phase([
              new CopyBuilder(copyFromAsset: makeAssetId('a|web/b.txt'))
            ], [
              new InputSet('a', filePatterns: ['web/a.txt'])
            ]),
          ],
        ];
        var writer = new InMemoryAssetWriter();
        var results = [];
        startWatch(phases, {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'}, writer)
            .listen(results.add);

        var result = await nextResult(results);
        checkOutputs({'a|web/a.txt.copy': 'b'}, result, writer.assets);

        await writer.writeAsString(makeAsset('a|web/b.txt', 'c'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.MODIFY, 'a/web/b.txt'));

        result = await nextResult(results);
        checkOutputs({'a|web/a.txt.copy': 'c'}, result, writer.assets);
      });

      test(
          'of an output which is derived from another generated file is edited',
          () async {
        var phases = [
          [
            new Phase([
              new CopyBuilder()
            ], [
              new InputSet('a', filePatterns: ['web/a.txt'])
            ]),
          ],
          [
            new Phase([
              new CopyBuilder(copyFromAsset: makeAssetId('a|web/b.txt'))
            ], [
              new InputSet('a', filePatterns: ['web/a.txt.copy'])
            ]),
          ],
        ];
        var writer = new InMemoryAssetWriter();
        var results = [];
        startWatch(phases, {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'}, writer)
            .listen(results.add);

        var result = await nextResult(results);
        checkOutputs({'a|web/a.txt.copy': 'a', 'a|web/a.txt.copy.copy': 'b'},
            result, writer.assets);

        await writer.writeAsString(makeAsset('a|web/b.txt', 'c'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.MODIFY, 'a/web/b.txt'));

        result = await nextResult(results);
        checkOutputs({'a|web/a.txt.copy.copy': 'c'}, result, writer.assets);
      });
    });
  });
}

final _debounceDelay = new Duration(milliseconds: 10);
StreamController _terminateWatchController;

/// Start watching files and running builds.
Stream<BuildResult> startWatch(List<List<Phase>> phases,
    Map<String, String> inputs, InMemoryAssetWriter writer) {
  inputs.forEach((serializedId, contents) {
    writer.writeAsString(makeAsset(serializedId, contents));
  });
  final actualAssets = writer.assets;
  final reader = new InMemoryAssetReader(actualAssets);
  final rootPackage = new PackageNode('a', null, null, new Uri.file('a/'));
  final packageGraph = new PackageGraph.fromRoot(rootPackage);
  final watcherFactory = (path) => new FakeWatcher(path);

  return watch(phases,
      debounceDelay: _debounceDelay,
      directoryWatcherFactory: watcherFactory,
      reader: reader,
      writer: writer,
      packageGraph: packageGraph,
      terminateEventStream: _terminateWatchController.stream,
      logLevel: Level.OFF);
}

/// Tells the program to stop watching files and terminate.
Future terminateWatch() {
  assert(_terminateWatchController != null);

  /// Can add any type of event.
  _terminateWatchController.add(null);
  return _terminateWatchController.close();
}

/// A fake [DirectoryWatcher].
///
/// Use the static [FakeWatcher#notifyPath] method to add events.
class FakeWatcher implements DirectoryWatcher {
  String get directory => path;
  final String path;

  FakeWatcher(this.path) {
    watchers.add(this);
  }

  final _eventsController = new StreamController<WatchEvent>();
  Stream<WatchEvent> get events => _eventsController.stream;

  Future get ready => new Future(() {});

  bool get isReady => true;

  /// All watchers.
  static final watchers = <FakeWatcher>[];

  /// Notify all active watchers of [event] if their [FakeWatcher#path] matches.
  /// The path will also be adjusted to remove the path.
  static notifyWatchers(WatchEvent event) {
    for (var watcher in watchers) {
      if (event.path.startsWith(watcher.path)) {
        watcher._eventsController.add(new WatchEvent(
            event.type, event.path.replaceFirst(watcher.path, '')));
      }
    }
  }
}

Future<BuildResult> nextResult(results) {
  var done = new Completer();
  var startingLength = results.length;
  () async {
    while (results.length == startingLength) {
      await wait(10);
    }
    expect(results.length, startingLength + 1,
        reason: 'Got two build results but only expected one');
    done.complete(results.last);
  }();
  return done.future;
}
