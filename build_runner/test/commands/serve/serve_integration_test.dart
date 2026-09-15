// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner/src/build/build_result.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/builder_definition.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/commands/serve/server.dart';
import 'package:build_runner/src/commands/watch_command.dart';
import 'package:built_collection/built_collection.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import '../../common/common.dart';

void main() {
  late FutureOr<Response> Function(Request) handler;
  late InternalTestReaderWriter readerWriter;
  late StreamSubscription subscription;
  late Completer<BuildResult> nextBuild;
  late StreamController<ProcessSignal> terminateController;

  final path = p.absolute('example');

  setUp(() async {
    final buildPackages = BuildPackages.singlePackageBuild('example', [
      BuildPackage(name: 'example', path: path, isOutput: true, watch: true),
    ]);
    readerWriter = InternalTestReaderWriter(outputRootPackage: 'example')
      ..testing.writeString(AssetId('example', 'web/initial.txt'), 'initial')
      ..testing.writeString(
        AssetId('example', 'web/large.txt'),
        'large' * 10000,
      )
      ..testing.writeString(AssetId('example', 'web/index.html'), 'hello')
      ..testing.writeString(
        AssetId('example', 'web/undiscovered.html'),
        'undiscovered',
      )
      ..testing.writeString(AssetId('example', 'web/page.html'), 'page')
      ..testing.writeString(
        makeAssetId('example|.dart_tool/package_config.json'),
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {
              'name': 'example',
              'rootUri': 'file://fake/pkg/path',
              'packageUri': 'lib/',
            },
          ],
        }),
      );

    terminateController = StreamController<ProcessSignal>();
    final watchCommnd = WatchCommand(
      builderFactories: BuilderFactories({
        '': [(_) => const UppercaseBuilder()],
      }),
      buildOptions: BuildOptions.forTests(verbose: true),
      testingOverrides: TestingOverrides(
        builderDefinitions: [BuilderDefinition('')].build(),
        buildPackages: buildPackages,
        readerWriter: readerWriter,
        onLog: (record) => printOnFailure(
          '[${record.level}] '
          '${record.loggerName}: ${record.message}',
        ),
        directoryWatcherFactory: FakeWatcher.new,
        terminateEventStream: terminateController.stream,
      ),
    );
    final watcher = (await watchCommnd.watch())!;
    final serveHandler = ServeHandler(watcher);
    handler = serveHandler.handlerFor('web', logRequests: true);

    nextBuild = Completer<BuildResult>();
    subscription = serveHandler.buildResults.listen((result) {
      nextBuild.complete(result);
      nextBuild = Completer<BuildResult>();
    });
    await nextBuild.future;
  });

  tearDown(() async {
    await subscription.cancel();
    terminateController.add(ProcessSignal.sigabrt);
    await terminateController.close();
  });

  test('should serve original files', () async {
    final getHello = Uri.parse('http://localhost/initial.txt');
    final response = await handler(Request('GET', getHello));
    expect(await response.readAsString(), 'initial');
  });

  test('should serve original files in parallel', () async {
    final getHello = Uri.parse('http://localhost/large.txt');
    final futures = [
      for (var i = 0; i < 512; i++)
        (() async => await handler(Request('GET', getHello)))(),
    ];
    final responses = await Future.wait(futures);
    for (final response in responses) {
      expect(await response.readAsString(), startsWith('large'));
    }
  });

  test('should serve built files', () async {
    final getHello = Uri.parse('http://localhost/initial.g.txt');
    readerWriter.testing.writeString(
      AssetId('example', 'web/initial.g.txt'),
      'INITIAL',
    );
    final response = await handler(Request('GET', getHello));
    expect(await response.readAsString(), 'INITIAL');
  });

  test('should 404 on missing files', () async {
    final get404 = Uri.parse('http://localhost/404.txt');
    final response = await handler(Request('GET', get404));
    expect(await response.readAsString(), 'Not Found');
  });

  test('should serve newly added files', () async {
    final getNew = Uri.parse('http://localhost/new.txt');
    readerWriter.testing.writeString(AssetId('example', 'web/new.txt'), 'New');
    await Future<void>.value();
    FakeWatcher.notifyWatchers(WatchEvent(ChangeType.ADD, '$path/web/new.txt'));
    await nextBuild.future;
    final response = await handler(Request('GET', getNew));
    expect(await response.readAsString(), 'New');
  });

  test('should serve built newly added files', () async {
    final getNew = Uri.parse('http://localhost/new.g.txt');
    readerWriter.testing.writeString(AssetId('example', 'web/new.txt'), 'New');
    await Future<void>.value();
    FakeWatcher.notifyWatchers(WatchEvent(ChangeType.ADD, '$path/web/new.txt'));
    await nextBuild.future;
    final response = await handler(Request('GET', getNew));
    expect(await response.readAsString(), 'NEW');
  });

  test('emits build result when unbuilt file consumed outside build '
      'changes', () async {
    readerWriter.testing.writeString(
      AssetId('example', 'web/index.html'),
      'hello',
    );
    readerWriter.testing.writeString(
      AssetId('example', 'web/unconsumed.html'),
      'unconsumed',
    );
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/index.html')),
    );
    expect(await response.readAsString(), 'hello');

    readerWriter.testing.writeString(
      AssetId('example', 'web/index.html'),
      'hello modified',
    );
    await Future<void>.value();
    FakeWatcher.notifyWatchers(
      WatchEvent(ChangeType.MODIFY, '$path/web/index.html'),
    );
    final result = await nextBuild.future;
    expect(result.status, BuildStatus.success);
    expect(result.outputs, isEmpty);

    readerWriter.testing.writeString(
      AssetId('example', 'web/unconsumed.html'),
      'unconsumed modified',
    );
    await Future<void>.value();
    FakeWatcher.notifyWatchers(
      WatchEvent(ChangeType.MODIFY, '$path/web/unconsumed.html'),
    );
    expect(
      nextBuild.future.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () => throw TimeoutException('timeout'),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('emits build result when unbuilt file consumed outside build is '
      'deleted', () async {
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/index.html')),
    );
    expect(await response.readAsString(), 'hello');

    readerWriter.testing.delete(AssetId('example', 'web/index.html'));
    await Future<void>.value();
    FakeWatcher.notifyWatchers(
      WatchEvent(ChangeType.REMOVE, '$path/web/index.html'),
    );
    final result = await nextBuild.future;
    expect(result.status, BuildStatus.success);
    expect(result.outputs, isEmpty);

    final notFoundResponse = await handler(
      Request('GET', Uri.parse('http://localhost/index.html')),
    );
    expect(await notFoundResponse.readAsString(), 'Not Found');
  });

  test('emits build result with only built outputs when both built and '
      'unbuilt files change', () async {
    readerWriter.testing.writeString(
      AssetId('example', 'web/page.html'),
      'page',
    );
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/page.html')),
    );
    expect(await response.readAsString(), 'page');

    readerWriter.testing.writeString(
      AssetId('example', 'web/page.html'),
      'page modified',
    );
    readerWriter.testing.writeString(
      AssetId('example', 'web/new2.txt'),
      'content',
    );
    await Future<void>.value();
    FakeWatcher.notifyWatchers(
      WatchEvent(ChangeType.ADD, '$path/web/new2.txt'),
    );
    FakeWatcher.notifyWatchers(
      WatchEvent(ChangeType.MODIFY, '$path/web/page.html'),
    );
    final result = await nextBuild.future;
    expect(result.status, BuildStatus.success);
    expect(result.outputs, [AssetId('example', 'web/new2.g.txt')]);
  });

  test(
    'synthetic build result retains failure status if previous build failed',
    () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/index.html')),
      );
      expect(await response.readAsString(), 'hello');

      // Trigger a failing build.
      readerWriter.testing.writeString(
        AssetId('example', 'web/initial.txt'),
        'FAIL',
      );
      await Future<void>.value();
      FakeWatcher.notifyWatchers(
        WatchEvent(ChangeType.MODIFY, '$path/web/initial.txt'),
      );
      final failedResult = await nextBuild.future;
      expect(failedResult.status, BuildStatus.failure);

      // Now modify an unbuilt file consumed outside the build.
      readerWriter.testing.writeString(
        AssetId('example', 'web/index.html'),
        'hello modified again',
      );
      await Future<void>.value();
      FakeWatcher.notifyWatchers(
        WatchEvent(ChangeType.MODIFY, '$path/web/index.html'),
      );
      final syntheticResult = await nextBuild.future;
      expect(syntheticResult.status, BuildStatus.failure);
      expect(syntheticResult.outputs, isEmpty);
    },
  );
}

class UppercaseBuilder implements Builder {
  const UppercaseBuilder();

  @override
  Future<void> build(BuildStep buildStep) async {
    final content = await buildStep.readAsString(buildStep.inputId);
    if (content == 'FAIL') throw StateError('Build failed');
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.g.txt'),
      content.toUpperCase(),
    );
  }

  @override
  final buildExtensions = const {
    'txt': ['g.txt'],
  };
}
