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
import 'package:path/path.dart' as p;
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

main() {
  Process daemonProcess;
  Stream<String> stdoutLines;
  String workspace() => p.join(d.sandbox, 'a');
  final webTarget = DefaultBuildTarget((b) => b..target = 'web');
  final testTarget = DefaultBuildTarget((b) => b..target = 'test');
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
          'test',
        ],
      ),
      d.dir('test', [
        d.file('hello_test.dart', '''
import 'package:test/test.dart';
main() {
  test('hello', () {});
}'''),
      ]),
      d.dir('web', [
        d.file('main.dart', '''
main() {
  print('hello world');
}'''),
      ]),
    ]).create();

    await pubGet('a', offline: false);
  });

  tearDown(() async {
    stdoutLines = null;
    daemonProcess?.kill(ProcessSignal.sigkill);
    await daemonProcess?.exitCode;
  });

  Future<BuildDaemonClient> _startClient(
      {BuildMode buildMode, List<String> options}) {
    options ??= [];
    buildMode ??= BuildMode.Auto;
    var args = ['run', 'build_runner', 'daemon', ...options];
    return BuildDaemonClient.connect(
        workspace(),
        [
          pubBinary.toString(),
        ]..addAll(args),
        buildMode: buildMode);
  }

  Future<void> _startDaemon({BuildMode buildMode, List<String> options}) async {
    options ??= [];
    buildMode ??= BuildMode.Auto;
    var args = [
      'build_runner',
      'daemon',
      '--$buildModeFlag=$buildMode',
      ...options
    ];
    daemonProcess = await startPub('a', 'run', args: args);
    stdoutLines = daemonProcess.stdout
        .transform(Utf8Decoder())
        .transform(LineSplitter())
        .map((line) {
      printOnFailure(line);
      return line;
    }).asBroadcastStream();
    expect(await stdoutLines.contains(readyToConnectLog), isTrue);
  }

  group('Build Daemon', () {
    test('successfully starts', () async {
      await _startDaemon();
    });

    test('shuts down on build script change', () async {
      await _startDaemon();
      var client = await _startClient()
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
    });

    test('does not shut down down on build script change when configured',
        () async {
      await _startDaemon(options: ['--skip-build-script-check']);
      var client = await _startClient(options: ['--skip-build-script-check'])
        ..registerBuildTarget(webTarget)
        ..startBuild();
      ShutdownNotification notification;
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
      await Future.delayed(Duration(seconds: 4));
      expect(notification, isNull);
    });

    test('errors if build modes conflict', () async {
      await _startDaemon();
      expect(_startClient(buildMode: BuildMode.Manual),
          throwsA(TypeMatcher<OptionsSkew>()));
    });

    test('can build in manual mode', () async {
      await _startDaemon(buildMode: BuildMode.Manual);
      var client = await _startClient(buildMode: BuildMode.Manual)
        ..registerBuildTarget(webTarget)
        ..startBuild();
      var buildResults = await client.buildResults.first;
      expect(buildResults.results.first.status, BuildStatus.started);
    });

    test('auto build mode automatically builds on file change', () async {
      await _startDaemon();
      var client = await _startClient()
        ..registerBuildTarget(webTarget);
      // Let the target request propagate.
      await Future.delayed(Duration(seconds: 2));
      // Trigger a file change.
      await d.dir('a', [
        d.dir('web', [
          d.file('main.dart', '''
                main() {
                  print('hello world');
                }'''),
        ])
      ]).create();
      var buildResults = await client.buildResults.first;
      expect(buildResults.results.first.status, BuildStatus.started);
    });

    test('manual build mode does not automatically build on file change',
        () async {
      await _startDaemon(buildMode: BuildMode.Manual);
      var client = await _startClient(buildMode: BuildMode.Manual)
        ..registerBuildTarget(webTarget);
      // Let the target request propagate.
      await Future.delayed(Duration(seconds: 2));
      // Trigger a file change.
      await d.dir('a', [
        d.dir('web', [
          d.file('main.dart', '''
                main() {
                  print('hello world');
                }'''),
        ])
      ]).create();
      // There shouldn't be any build results.
      var buildResults = await client.buildResults.first
          .timeout(Duration(seconds: 2), onTimeout: () => null);
      expect(buildResults, isNull);
    });

    test('can build to outputs', () async {
      var outputDir = Directory(p.join(d.sandbox, 'a', 'deploy'));
      expect(outputDir.existsSync(), isFalse);
      await _startDaemon();
      // Start the client with the same options to prevent OptionSkew.
      // In the future this should be an option on the target.
      var client = await _startClient()
        ..registerBuildTarget(DefaultBuildTarget((b) => b
          ..target = 'web'
          ..outputLocation = OutputLocation((b) => b
            ..output = 'deploy'
            ..hoist = true
            ..useSymlinks = false).toBuilder()))
        ..startBuild();
      await client.buildResults
          .firstWhere((b) => b.results.first.status != BuildStatus.started);
      expect(outputDir.existsSync(), isTrue);
    });

    test('writes the asset server port', () async {
      await _startDaemon();
      expect(File(assetServerPortFilePath(workspace())).existsSync(), isTrue);
    });

    test('notifies upon build start', () async {
      await _startDaemon();
      var client = await _startClient()
        ..registerBuildTarget(webTarget)
        ..startBuild();
      var buildResults = await client.buildResults.first;
      expect(buildResults.results.first.status, BuildStatus.started);
    });

    test('can complete builds', () async {
      await _startDaemon();
      var client = await _startClient()
        ..registerBuildTarget(webTarget)
        ..startBuild();
      var buildResults = await client.buildResults
          .firstWhere((b) => b.results.first.status != BuildStatus.started);
      expect(buildResults.results.first.status, BuildStatus.succeeded);
    });

    test('allows multiple clients to connect and build', () async {
      await _startDaemon();

      var clientA = await _startClient();
      clientA.registerBuildTarget(webTarget);

      var clientB = await _startClient()
        ..registerBuildTarget(testTarget)
        ..startBuild();

      // Both clients should be notified.
      await clientA.buildResults.first;
      var buildResultsB = await clientB.buildResults
          .firstWhere((b) => b.results.first.status != BuildStatus.started);

      expect(buildResultsB.results.first.status, BuildStatus.succeeded);
      expect(buildResultsB.results.length, equals(2));
    });
  });
}
