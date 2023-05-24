// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:_test_common/common.dart';
import 'package:build_daemon/client.dart';
import 'package:build_daemon/constants.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:build_daemon/data/shutdown_notification.dart';
import 'package:build_runner/src/daemon/constants.dart';
import 'package:build_runner_core/src/util/constants.dart' show dartBinary;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  Process? daemonProcess;
  Stream<String>? stdoutLines;
  String workspace() => p.join(d.sandbox, 'a');
  final webTarget = DefaultBuildTarget((b) => b
    ..target = 'web'
    ..reportChangedAssets = true);
  final testTarget = DefaultBuildTarget((b) => b..target = 'test');
  var clients = <BuildDaemonClient>[];

  setUp(() async {
    await d.dir('a', [
      await pubspec(
        'a',
        currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_modules',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
          'build_test',
          'build_web_compilers',
          'code_builder',
          'test',
        ],
      ),
      d.dir('test', [
        d.file('hello.dart', '''
main() {
  // Don't actually use test package to speed up tests
  print('hello');
}'''),
      ]),
      d.dir('lib', [
        d.file('message.dart', '''
const message = 'hello world';
      '''),
      ]),
      d.dir('web', [
        d.file('main.dart', '''
import 'package:a/message.dart';

main() {
  print(message);
}'''),
      ]),
    ]).create();

    await pubGet('a', offline: false);

    // We use `addTearDown` to ensure this runs before the temp dir gets
    // cleaned up, otherwise there is a race condition that causes flaky tests.
    addTearDown(() async {
      for (var client in clients) {
        await client.close();
      }
      clients.clear();
      stdoutLines = null;
      daemonProcess?.kill(ProcessSignal.sigkill);
      await daemonProcess?.exitCode;
    });
  });

  Future<BuildDaemonClient> startClient(
      {BuildMode buildMode = BuildMode.Auto, List<String> options = const []}) {
    var args = ['run', 'build_runner', 'daemon', ...options];
    printOnFailure('Starting client in: ${workspace()}');
    return BuildDaemonClient.connect(
        workspace(),
        [
          dartBinary,
          ...args,
        ],
        logHandler: (log) => printOnFailure('Client: ${log.message}'),
        buildMode: buildMode);
  }

  Future<void> startDaemon(
      {BuildMode buildMode = BuildMode.Auto,
      List<String> options = const [],
      bool expectFailure = false}) async {
    var args = [
      'build_runner',
      'daemon',
      '--$buildModeFlag=$buildMode',
      ...options
    ];
    printOnFailure('Starting daemon in: ${workspace()}');
    var daemon = daemonProcess = await startPub('a', 'run', args: args);
    stdoutLines = daemon.stdout
        .transform(Utf8Decoder())
        .transform(LineSplitter())
        .asBroadcastStream()
      ..listen((line) {
        printOnFailure('Daemon: $line');
      });
    daemon.stderr
        .transform(Utf8Decoder())
        .transform(LineSplitter())
        .listen((line) {
      printOnFailure('Daemon Error: $line');
    });
    unawaited(daemon.exitCode.then((exitCode) {
      printOnFailure('GOT EXIT CODE: $exitCode');
    }));
    if (expectFailure) {
      expect(await daemon.exitCode, isNot(0));
    } else {
      expect(await stdoutLines!.contains(readyToConnectLog), isTrue);
    }
  }

  group('Build Daemon', () {
    test('successfully starts', () async {
      await startDaemon();
    });

    test('shuts down on build script change', () async {
      await startDaemon();
      var client = await startClient()
        ..registerBuildTarget(webTarget)
        ..startBuild();
      // We need to add a listener otherwise we won't get the event.
      unawaited(expectLater(client.shutdownNotifications.first, isNotNull));
      // Force a build script change.
      await d.dir('a', [
        d.dir('.dart_tool', [
          d.dir('build', [
            d.dir('entrypoint', [d.file('build.dart', '\n')])
          ])
        ])
      ]).create();
    }, skip: 'https://github.com/dart-lang/build/issues/3438');

    test('supports --enable-experiment option', () async {
      // TODO: Check for specific message about a bad experiment
      await startDaemon(
          options: ['--enable-experiment=fake-experiment'],
          expectFailure: true);
    });

    test('does not shut down down on build script change when configured',
        () async {
      await startDaemon(options: ['--skip-build-script-check']);
      var client = await startClient(options: ['--skip-build-script-check'])
        ..registerBuildTarget(webTarget)
        ..startBuild();
      clients.add(client);
      ShutdownNotification? notification;
      // We need to add a listener otherwise we won't get the event.
      unawaited(client.shutdownNotifications.first
          .then((value) => notification = value));
      // Force a build script change.
      await d.dir('a', [
        d.dir('.dart_tool', [
          d.dir('build', [
            d.dir('entrypoint', [d.file('build.dart', '\n')])
          ])
        ])
      ]).create();
      // Give time for the notification to propogate if there was one.
      await Future<void>.delayed(Duration(seconds: 4));
      expect(notification, isNull);
    });

    test('errors if build modes conflict', () async {
      await startDaemon();
      expect(startClient(buildMode: BuildMode.Manual),
          throwsA(TypeMatcher<OptionsSkew>()));
    });

    test('can build in manual mode', () async {
      await startDaemon(buildMode: BuildMode.Manual);
      var client = await startClient(buildMode: BuildMode.Manual)
        ..registerBuildTarget(webTarget)
        ..startBuild();
      clients.add(client);
      expect(
          client.buildResults,
          emitsThrough((BuildResults b) =>
              b.results.first.status == BuildStatus.succeeded));
    });

    test('auto build mode automatically builds on file change', () async {
      await startDaemon();
      var client = await startClient()
        ..registerBuildTarget(webTarget);
      clients.add(client);
      // Let the target request propagate.
      await Future<void>.delayed(Duration(seconds: 2));
      // Trigger a file change.
      await d.dir('a', [
        d.dir('web', [
          d.file('main.dart', '''
main() {
  print('goodbye world');
}'''),
        ])
      ]).create();
      expect(
          client.buildResults,
          emitsThrough((BuildResults b) =>
              b.results.first.status == BuildStatus.succeeded));
    });

    test('manual build mode does not automatically build on file change',
        () async {
      await startDaemon(buildMode: BuildMode.Manual);
      var client = await startClient(buildMode: BuildMode.Manual)
        ..registerBuildTarget(webTarget);
      clients.add(client);
      // Let the target request propagate.
      await Future<void>.delayed(Duration(seconds: 2));
      // Trigger a file change.
      await d.dir('a', [
        d.dir('web', [
          d.file('main.dart', '''
// @dart=2.12
main() {
  print('goodbye world');
}'''),
        ])
      ]).create();
      // There shouldn't be any build results.
      var buildResults = await client.buildResults.first
          .then<BuildResults?>((r) => r)
          .timeout(Duration(seconds: 2), onTimeout: () => null);
      expect(buildResults, isNull);
      client.startBuild();
      var startedResult = await client.buildResults.first;
      expect(startedResult.results.first.status, BuildStatus.started,
          reason: 'Should do a build once requested');
      var succeededResult = await client.buildResults.first;
      expect(succeededResult.results.first.status, BuildStatus.succeeded);
      var ddcContent = await File(p.join(d.sandbox, 'a', '.dart_tool', 'build',
              'generated', 'a', 'web', 'main.ddc.js'))
          .readAsString();
      expect(ddcContent, contains('goodbye world'));
    });

    test('can build to outputs', () async {
      var outputDir = Directory(p.join(d.sandbox, 'a', 'deploy'));
      expect(outputDir.existsSync(), isFalse);
      await startDaemon();
      // Start the client with the same options to prevent OptionSkew.
      // In the future this should be an option on the target.
      var client = await startClient()
        ..registerBuildTarget(DefaultBuildTarget((b) => b
          ..target = 'web'
          ..outputLocation = OutputLocation((b) => b
            ..output = 'deploy'
            ..hoist = true
            ..useSymlinks = false).toBuilder()))
        ..startBuild();
      clients.add(client);
      await client.buildResults
          .firstWhere((b) => b.results.first.status == BuildStatus.succeeded);
      expect(outputDir.existsSync(), isTrue);
    });

    test('writes the asset server port', () async {
      await startDaemon();
      expect(File(assetServerPortFilePath(workspace())).existsSync(), isTrue);
    });

    test('notifies upon build start', () async {
      await startDaemon();
      var client = await startClient()
        ..registerBuildTarget(webTarget)
        ..startBuild();
      clients.add(client);
      expect(
          client.buildResults,
          emitsThrough((BuildResults b) =>
              b.results.first.status == BuildStatus.started));
      // Wait for the build to finish before exiting to prevent flakiness.
      expect(
          client.buildResults,
          emitsThrough((BuildResults b) =>
              b.results.first.status == BuildStatus.succeeded));
    });

    test('can complete builds', () async {
      await startDaemon();
      var client = await startClient()
        ..registerBuildTarget(webTarget)
        ..startBuild();
      clients.add(client);

      expect(
        client.buildResults,
        emitsThrough(
          isA<BuildResults>()
              .having((e) => e.results.first.status, 'results.first.status',
                  BuildStatus.succeeded)
              .having((e) => e.changedAssets, 'changedAsssets',
                  contains(Uri.parse('asset:a/web/main.dart.js'))),
        ),
      );
    });

    test('allows multiple clients to connect and build', () async {
      await startDaemon();

      var clientA = await startClient();
      clientA.registerBuildTarget(webTarget);
      clients.add(clientA);

      var clientB = await startClient()
        ..registerBuildTarget(testTarget)
        ..startBuild();
      clients.add(clientB);

      // Both clients should be notified.
      await clientA.buildResults.first;
      var buildResultsB = await clientB.buildResults
          .firstWhere((b) => b.results.first.status != BuildStatus.started);

      expect(buildResultsB.results.first.status, BuildStatus.succeeded);
      expect(buildResultsB.results.length, equals(2));
    });

    group('build filters', () {
      setUp(() async {
        // Adds an additional entrypoint.
        await d.dir('a', [
          d.dir('web', [
            d.file('other.dart', '''
main() {
  print('goodbye world');
}'''),
          ])
        ]).create();
      });

      test('can build specific outputs', () async {
        await startDaemon(buildMode: BuildMode.Manual);
        var client = await startClient(buildMode: BuildMode.Manual)
          ..registerBuildTarget(DefaultBuildTarget((b) => b
            ..target = 'web'
            ..buildFilters.add('web/other.dart.js')))
          ..startBuild();
        clients.add(client);
        await client.buildResults
            .firstWhere((b) => b.results.first.status == BuildStatus.succeeded);

        await d.dir('a', [
          d.dir('.dart_tool', [
            d.dir('build', [
              d.dir('generated', [
                d.dir('a', [
                  d.dir('web', [
                    d.file('other.dart.js', isNotEmpty),
                    d.nothing('main.dart.js'),
                  ]),
                ])
              ])
            ])
          ])
        ]).validate();
      });
    });
  });
}
