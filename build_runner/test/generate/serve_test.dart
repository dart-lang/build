// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:_test_common/common.dart';
import 'package:async/async.dart';
import 'package:build_runner/src/generate/watch_impl.dart' as watch_impl;
import 'package:build_runner/src/server/server.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('ServeHandler', () {
    final packageGraph = buildPackageGraph({
      rootPackage('a', path: path.absolute('a')): [],
    });
    late TestReaderWriter readerWriter;

    setUp(() async {
      _terminateServeController = StreamController();
      readerWriter = TestReaderWriter(rootPackage: packageGraph.root.name);
      await readerWriter.writeAsString(
        makeAssetId('a|.dart_tool/package_config.json'),
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {
              'name': 'a',
              'rootUri': 'file://fake/pkg/path',
              'packageUri': 'lib/',
            },
          ],
        }),
      );
    });

    tearDown(() async {
      FakeWatcher.watchers.clear();
      await terminateServe();
    });

    test('does basic builds', () async {
      var handler = await createHandler(
        [applyToRoot(TestBuilder())],
        {'a|web/a.txt': 'a'},
        packageGraph,
        readerWriter,
      );
      var results = StreamQueue(handler.buildResults);
      var result = await results.next;
      checkBuild(
        result,
        outputs: {'a|web/a.txt.copy': 'a'},
        readerWriter: readerWriter,
      );

      await readerWriter.writeAsString(makeAssetId('a|web/a.txt'), 'b');

      result = await results.next;
      checkBuild(
        result,
        outputs: {'a|web/a.txt.copy': 'b'},
        readerWriter: readerWriter,
      );
    });

    test('blocks serving files until the build is done', () async {
      var buildBlocker1 = Completer<void>();
      var nextBuildBlocker = buildBlocker1.future;

      var handler = await createHandler(
        [applyToRoot(TestBuilder(extraWork: (_, _) => nextBuildBlocker))],
        {'a|web/a.txt': 'a'},
        packageGraph,
        readerWriter,
      );
      var webHandler = handler.handlerFor('web');
      var results = StreamQueue(handler.buildResults);
      // Give the build enough time to get started.
      await wait(100);

      var request = Request('GET', Uri.parse('http://localhost:8000/a.txt'));
      unawaited(
        (webHandler(request) as Future<Response>).then(
          expectAsync1((Response response) {
            expect(
              buildBlocker1.isCompleted,
              isTrue,
              reason: 'Server shouldn\'t respond until builds are done.',
            );
          }),
        ),
      );
      await wait(250);
      buildBlocker1.complete();
      var result = await results.next;
      checkBuild(
        result,
        outputs: {'a|web/a.txt.copy': 'a'},
        readerWriter: readerWriter,
      );

      /// Next request completes right away.
      var buildBlocker2 = Completer<void>();
      unawaited(
        (webHandler(request) as Future<Response>).then(
          expectAsync1((response) {
            expect(buildBlocker1.isCompleted, isTrue);
            expect(buildBlocker2.isCompleted, isFalse);
          }),
        ),
      );

      /// Make an edit to force another build, and we should block again.
      nextBuildBlocker = buildBlocker2.future;
      await readerWriter.writeAsString(makeAssetId('a|web/a.txt'), 'b');
      // Give the build enough time to get started.
      await wait(500);
      var done = Completer<void>();
      unawaited(
        (webHandler(request) as Future<Response>).then(
          expectAsync1((response) {
            expect(buildBlocker1.isCompleted, isTrue);
            expect(buildBlocker2.isCompleted, isTrue);
            done.complete();
          }),
        ),
      );
      await wait(250);
      buildBlocker2.complete();
      result = await results.next;
      checkBuild(
        result,
        outputs: {'a|web/a.txt.copy': 'b'},
        readerWriter: readerWriter,
      );

      /// Make sure we actually see the final request finish.
      return done.future;
    });
  });
}

final _debounceDelay = const Duration(milliseconds: 10);
StreamController<ProcessSignal>? _terminateServeController;

/// Start serving files and running builds.
Future<ServeHandler> createHandler(
  List<BuilderApplication> builders,
  Map<String, String> inputs,
  PackageGraph packageGraph,
  TestReaderWriter readerWriter,
) async {
  await Future.wait(
    inputs.keys.map((serializedId) async {
      await readerWriter.writeAsString(
        makeAssetId(serializedId),
        inputs[serializedId]!,
      );
    }),
  );
  FakeWatcher watcherFactory(String path) => FakeWatcher(path);

  return watch_impl.watch(
    builders,
    deleteFilesByDefault: true,
    debounceDelay: _debounceDelay,
    directoryWatcherFactory: watcherFactory,
    reader: readerWriter,
    writer: readerWriter,
    packageGraph: packageGraph,
    terminateEventStream: _terminateServeController!.stream,
    onLog: (_) {},
    skipBuildScriptCheck: true,
  );
}

/// Tells the program to terminate.
Future terminateServe() {
  /// Can add any type of event.
  _terminateServeController!.add(ProcessSignal.sigabrt);
  return _terminateServeController!.close();
}
