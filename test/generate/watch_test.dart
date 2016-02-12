// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'package:build/build.dart';

import '../common/common.dart';

final _watchers = <DirectoryWatcher>[];

main() {
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
        var phases = [
          [
            new Phase([new CopyBuilder()], [new InputSet('a')]),
          ]
        ];
        var writer = new InMemoryAssetWriter();
        var results = [];
        startWatch(phases, {'a|web/a.txt': 'a'}, writer).listen(results.add);

        await wait(200);
        expect(results.length, 1);
        checkOutputs({'a|web/a.txt.copy': 'a',}, results[0], writer.assets);

        await writer.writeAsString(makeAsset('a|web/a.txt', 'b'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.MODIFY, 'a/web/a.txt'));

        await wait(200);
        expect(results.length, 2);
        checkOutputs({'a|web/a.txt.copy': 'b',}, results[1], writer.assets);
      });

      test('rebuilds on new files', () async {
        var phases = [
          [
            new Phase([new CopyBuilder()], [new InputSet('a')]),
          ]
        ];
        var writer = new InMemoryAssetWriter();
        var results = [];
        startWatch(phases, {'a|web/a.txt': 'a'}, writer).listen(results.add);

        await wait(200);
        expect(results.length, 1);
        checkOutputs({'a|web/a.txt.copy': 'a',}, results[0], writer.assets);

        await writer.writeAsString(makeAsset('a|web/b.txt', 'b'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.ADD, 'a/web/b.txt'));

        await wait(200);
        expect(results.length, 2);
        checkOutputs({'a|web/a.txt.copy': 'a', 'a|web/b.txt.copy': 'b',},
            results[1], writer.assets);
      });

      test('rebuilds on deleted files', () async {
        var phases = [
          [
            new Phase([new CopyBuilder()], [new InputSet('a')]),
          ]
        ];
        var writer = new InMemoryAssetWriter();
        var results = [];
        startWatch(phases, {'a|web/a.txt': 'a', 'a|web/b.txt': 'b',}, writer)
            .listen(results.add);

        await wait(200);
        expect(results.length, 1);
        checkOutputs({'a|web/a.txt.copy': 'a', 'a|web/b.txt.copy': 'b',},
            results[0], writer.assets);

        await writer.delete(makeAssetId('a|web/a.txt'));
        FakeWatcher
            .notifyWatchers(new WatchEvent(ChangeType.REMOVE, 'a/web/a.txt'));

        await wait(200);
        expect(results.length, 2);
        checkOutputs({'a|web/b.txt.copy': 'b',}, results[1], writer.assets);
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
