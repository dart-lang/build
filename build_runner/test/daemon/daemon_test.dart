// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@Timeout(Duration(minutes: 2))
@Tags(['integration'])
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:_test_common/common.dart';
import 'package:build_daemon/client.dart';
import 'package:build_daemon/constants.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:build_runner/src/daemon/constants.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

main() {
  Process daemonProcess;
  Stream<String> stdoutLines;

  String workspace() => p.join(d.sandbox, 'a');

  setUpAll(() async {
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
          'test',
        ],
        versionDependencies: {
          'build_web_compilers': 'any',
        },
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
    await runPub('a', 'run', args: ['build_runner', 'clean']);
  });

  Future<BuildDaemonClient> _startClient() =>
      BuildDaemonClient.connect(workspace(), [
        pubBinary.toString(),
        'run',
        'build_runner',
        'daemon',
      ]);

  Future<void> _startDaemon() async {
    daemonProcess =
        await startPub('a', 'run', args: ['build_runner', 'daemon']);
    stdoutLines = daemonProcess.stdout
        .transform(Utf8Decoder())
        .transform(LineSplitter())
        .asBroadcastStream();
    expect(await stdoutLines.contains(readyToConnectLog), isTrue);
  }

  group('Build Daemon', () {
    test('successfully starts', () async {
      await _startDaemon();
    });

    test('writes the asset server port', () async {
      await _startDaemon();
      expect(File(assetServerPortFilePath(workspace())).existsSync(), isTrue);
    });

    test('can complete builds', () async {
      await _startDaemon();
      var client = await _startClient();
      client.registerBuildTarget('web', []);
      client.startBuild();
      var buildResults = await client.buildResults.first;
      expect(buildResults.results.first.status, BuildStatus.succeeded);
    });

    test('allows multiple clients to connect and build', () async {
      await _startDaemon();

      var clientA = await _startClient();
      clientA.registerBuildTarget('web', []);

      var clientB = await _startClient();
      clientB.registerBuildTarget('test', []);

      clientB.startBuild();

      // Both clients should be notified.
      await clientA.buildResults.first;
      var buildResultsB = await clientB.buildResults.first;

      expect(buildResultsB.results.first.status, BuildStatus.succeeded);
      expect(buildResultsB.results.length, equals(2));
    });
  });
}
