// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/server/server.dart' as server;
import 'package:build_test/build_test.dart';

import '../common/common.dart';

void main() {
  group('serve', () {
    InMemoryRunnerAssetWriter writer;
    CopyBuilder copyBuilder;
    BuildAction copyABuildAction;

    setUp(() {
      _terminateServeController = new StreamController();
      writer = new InMemoryRunnerAssetWriter();

      /// Basic phases/phase groups which get used in many tests
      copyBuilder = new CopyBuilder();
      copyABuildAction = new BuildAction(copyBuilder, 'a');
    });

    tearDown(() async {
      FakeWatcher.watchers.clear();
      await terminateServe();
    });

    test('does basic builds', () async {
      var results = <BuildResult>[];
      startServe([copyABuildAction], {'a|web/a.txt': 'a'}, writer)
          .listen(results.add);
      var result = await nextResult(results);
      checkBuild(result, outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

      await writer.writeAsString(makeAssetId('a|web/a.txt'), 'b');
      FakeWatcher.notifyWatchers(new WatchEvent(
          ChangeType.MODIFY, path.absolute('a', 'web', 'a.txt')));

      result = await nextResult(results);
      checkBuild(result, outputs: {'a|web/a.txt.copy': 'b'}, writer: writer);
    });

    test('blocks serving files until the build is done', () async {
      var buildBlocker1 = new Completer();
      copyBuilder.blockUntil = buildBlocker1.future;

      var results = <BuildResult>[];
      startServe([copyABuildAction], {'a|web/a.txt': 'a'}, writer)
          .listen(results.add);
      // Give the build enough time to get started.
      await wait(100);

      var request =
          new Request('GET', Uri.parse('http://localhost:8000/CHANGELOG.md'));
      server.blockingHandler(request).then((Response response) {
        expect(buildBlocker1.isCompleted, isTrue,
            reason: 'Server shouldn\'t respond until builds are done.');
      });
      await wait(250);
      buildBlocker1.complete();
      var result = await nextResult(results);
      checkBuild(result, outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

      /// Next request completes right away.
      var buildBlocker2 = new Completer();
      server.blockingHandler(request).then((response) {
        expect(buildBlocker1.isCompleted, isTrue);
        expect(buildBlocker2.isCompleted, isFalse);
      });

      /// Make an edit to force another build, and we should block again.
      copyBuilder.blockUntil = buildBlocker2.future;
      await writer.writeAsString(makeAssetId('a|web/a.txt'), 'b');
      FakeWatcher.notifyWatchers(new WatchEvent(
          ChangeType.MODIFY, path.absolute('a', 'web', 'a.txt')));
      // Give the build enough time to get started.
      await wait(500);
      var done = new Completer();
      server.blockingHandler(request).then((response) {
        expect(buildBlocker1.isCompleted, isTrue);
        expect(buildBlocker2.isCompleted, isTrue);
        done.complete();
      });
      await wait(250);
      buildBlocker2.complete();
      result = await nextResult(results);
      checkBuild(result, outputs: {'a|web/a.txt.copy': 'b'}, writer: writer);

      /// Make sure we actually see the final request finish.
      return done.future;
    });
  });
}

final _debounceDelay = new Duration(milliseconds: 10);
StreamController _terminateServeController;

/// Start serving files and running builds.
Stream<BuildResult> startServe(List<BuildAction> buildActions,
    Map<String, String> inputs, InMemoryRunnerAssetWriter writer) {
  inputs.forEach((serializedId, contents) {
    writer.writeAsString(makeAssetId(serializedId), contents);
  });
  final actualAssets = writer.assets;
  final reader = new InMemoryRunnerAssetReader(actualAssets);
  final rootPackage = new PackageNode('a', null, null, new Uri.file('a/'));
  final packageGraph = new PackageGraph.fromRoot(rootPackage);
  final watcherFactory = (String path) => new FakeWatcher(path);

  return serve(buildActions,
      deleteFilesByDefault: true,
      debounceDelay: _debounceDelay,
      directoryWatcherFactory: watcherFactory,
      reader: reader,
      writer: writer,
      packageGraph: packageGraph,
      terminateEventStream: _terminateServeController.stream,
      logLevel: Level.OFF);
}

/// Tells the program to terminate.
Future terminateServe() {
  assert(_terminateServeController != null);

  /// Can add any type of event.
  _terminateServeController.add(null);
  return _terminateServeController.close();
}
