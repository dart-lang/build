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
    readerWriter =
        InternalTestReaderWriter(outputRootPackage: 'example')
          ..testing.writeString(
            AssetId('example', 'web/initial.txt'),
            'initial',
          )
          ..testing.writeString(
            AssetId('example', 'web/large.txt'),
            'large' * 10000,
          )
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
    final server =
        (await WatchCommand(
          builderFactories: BuilderFactories({
            '': [(_) => const UppercaseBuilder()],
          }),
          buildOptions: BuildOptions.forTests(verbose: true),
          testingOverrides: TestingOverrides(
            builderDefinitions: [BuilderDefinition('')].build(),
            buildPackages: buildPackages,
            readerWriter: readerWriter,
            onLog:
                (record) => printOnFailure(
                  '[${record.level}] '
                  '${record.loggerName}: ${record.message}',
                ),
            directoryWatcherFactory: FakeWatcher.new,
            terminateEventStream: terminateController.stream,
          ),
        ).watch())!;
    handler = server.handlerFor('web', logRequests: true);

    nextBuild = Completer<BuildResult>();
    subscription = server.buildResults.listen((result) {
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
}

class UppercaseBuilder implements Builder {
  const UppercaseBuilder();

  @override
  Future<void> build(BuildStep buildStep) async {
    final content = await buildStep.readAsString(buildStep.inputId);
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
