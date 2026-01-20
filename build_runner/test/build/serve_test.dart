// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/builder_definition.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/commands/serve/server.dart';
import 'package:build_runner/src/commands/watch_command.dart';
import 'package:built_collection/built_collection.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  group('ServeHandler', () {
    final buildPackages = BuildPackages.fromPackages([
      BuildPackage(
        name: 'a',
        path: path.absolute('a'),
        isInBuild: true,
        watch: true,
      ),
    ], current: 'a');
    late InternalTestReaderWriter readerWriter;

    setUp(() async {
      _terminateServeController = StreamController();
      readerWriter = InternalTestReaderWriter(
        outputRootPackage: buildPackages.outputRoot.name,
      );
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
      final handler = await createHandler(
        BuilderFactories({
          '': [(_) => TestBuilder()],
        }),
        [BuilderDefinition('')],
        {'a|web/a.txt': 'a'},
        buildPackages,
        readerWriter,
      );
      final results = StreamQueue(handler.buildResults);
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
      final buildBlocker1 = Completer<void>();
      var nextBuildBlocker = buildBlocker1.future;

      final handler = await createHandler(
        BuilderFactories({
          '': [(_) => TestBuilder(extraWork: (_, _) => nextBuildBlocker)],
        }),
        [BuilderDefinition('')],
        {'a|web/a.txt': 'a'},
        buildPackages,
        readerWriter,
      );
      final webHandler = handler.handlerFor('web');
      final results = StreamQueue(handler.buildResults);
      // Give the build enough time to get started.
      await wait(100);

      final request = Request('GET', Uri.parse('http://localhost:8000/a.txt'));
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
      final buildBlocker2 = Completer<void>();
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
      final done = Completer<void>();
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
  BuilderFactories builderFactories,
  Iterable<BuilderDefinition> builders,
  Map<String, String> inputs,
  BuildPackages buildPackages,
  InternalTestReaderWriter readerWriter,
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

  final watchCommand = WatchCommand(
    builderFactories: builderFactories,
    buildOptions: BuildOptions.forTests(),
    testingOverrides: TestingOverrides(
      builderDefinitions: builders.toBuiltList(),
      directoryWatcherFactory: watcherFactory,
      debounceDelay: _debounceDelay,
      onLog: (_) {},
      buildPackages: buildPackages,
      readerWriter: readerWriter,
      terminateEventStream: _terminateServeController!.stream,
    ),
  );

  return (await watchCommand.watch())!;
}

/// Tells the program to terminate.
Future terminateServe() {
  /// Can add any type of event.
  _terminateServeController!.add(ProcessSignal.sigabrt);
  return _terminateServeController!.close();
}
