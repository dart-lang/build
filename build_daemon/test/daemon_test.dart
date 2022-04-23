// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@OnPlatform({
  'windows': Skip('Directories cant be deleted while processes are still open')
})
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:build_daemon/constants.dart';
import 'package:build_daemon/daemon.dart';
import 'package:build_daemon/src/fakes/fake_builder.dart';
import 'package:build_daemon/src/fakes/fake_change_provider.dart';
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:uuid/uuid.dart';

void main() {
  var testDaemons = <Process>[];
  var testWorkspaces = <String>[];
  var uuid = Uuid();

  group('Daemon', () {
    setUp(() {
      testDaemons.clear();
      testWorkspaces.clear();
    });

    tearDown(() async {
      for (var testDaemon in testDaemons) {
        testDaemon.kill(ProcessSignal.sigkill);
      }
      for (var testWorkspace in testWorkspaces) {
        var workspace = Directory(daemonWorkspace(testWorkspace));
        if (workspace.existsSync()) {
          workspace.deleteSync(recursive: true);
        }
      }
    });

    test('can be stopped', () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      var daemon = Daemon(workspace);
      await daemon.start(
        <String>{},
        FakeDaemonBuilder(),
        FakeChangeProvider(),
      );
      // TODO add back byEndOfTest
      unawaited(checkThat(daemon.onDone).completes()); //.byEndOfTest();
      await daemon.stop();
    });

    test('can run if no other daemon is running', () async {
      var workspace = uuid.v1();
      var daemon = await _runDaemon(workspace);
      testDaemons.add(daemon);
      checkThat(await _statusOf(daemon)).equals('RUNNING');
    });

    test('shuts down if no client connects', () async {
      var workspace = uuid.v1();
      var daemon = await _runDaemon(workspace, timeout: 1);
      testDaemons.add(daemon);
      checkThat(await daemon.exitCode).isNotNull();
    });

    test('can not run if another daemon is running in the same workspace',
        () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      var daemonOne = await _runDaemon(workspace);
      checkThat(await _statusOf(daemonOne)).equals('RUNNING');
      var daemonTwo = await _runDaemon(workspace);
      testDaemons.addAll([daemonOne, daemonTwo]);
      checkThat(await _statusOf(daemonTwo)).equals('ALREADY RUNNING');
    });

    test('can run if another daemon is running in a different workspace',
        () async {
      var workspace1 = uuid.v1();
      var workspace2 = uuid.v1();
      testWorkspaces.addAll([workspace1, workspace2]);
      var daemonOne = await _runDaemon(workspace1);
      checkThat(await _statusOf(daemonOne)).equals('RUNNING');
      var daemonTwo = await _runDaemon(workspace2);
      testDaemons.addAll([daemonOne, daemonTwo]);
      checkThat(await _statusOf(daemonTwo)).equals('RUNNING');
    }, timeout: Timeout.factor(2));

    test('can start two daemons at the same time', () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      var daemonOne = await _runDaemon(workspace);
      var daemonTwo = await _runDaemon(workspace);
      // TODO add back containsAll
      // checkThat([await _statusOf(daemonOne), await _statusOf(daemonTwo)])
      //     .containsAll(['Nope', 'ALREADY RUNNING']);
      testDaemons.addAll([daemonOne, daemonTwo]);
    }, timeout: Timeout.factor(2));

    test('logs the version when running', () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      var daemon = await _runDaemon(workspace);
      testDaemons.add(daemon);
      checkThat(await _statusOf(daemon)).equals('RUNNING');
      checkThat(await Daemon(workspace).runningVersion())
          .equals(currentVersion);
    });

    test('does not set the current version if not running', () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      checkThat(await Daemon(workspace).runningVersion()).isNull();
    });

    test('logs the options when running', () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      var daemon = await _runDaemon(workspace);
      testDaemons.add(daemon);
      checkThat(await _statusOf(daemon)).equals('RUNNING');
      checkThat((await Daemon(workspace).currentOptions()).contains('foo'))
          .isTrue();
    });

    test('does not log the options if not running', () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      checkThat(await Daemon(workspace).currentOptions()).isEmpty();
    });

    test('cleans up after itself', () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      var daemon = await _runDaemon(workspace);
      // Wait for the daemon to be running before checking the workspace exits.
      checkThat(await _statusOf(daemon)).equals('RUNNING');
      checkThat(Directory(daemonWorkspace(workspace)).existsSync()).isTrue();
      // Sending an interrupt signal will let the daemon gracefully exit.
      daemon.kill(ProcessSignal.sigint);
      await daemon.exitCode;
      checkThat(Directory(daemonWorkspace(workspace)).existsSync()).isFalse();
    });
  });
}

/// Returns the daemon status.
///
/// If the status is null, the stderr ir returned.
Future<String> _statusOf(Process daemon) async {
  String? status;
  try {
    status = await daemon.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .firstWhere((line) => line == 'RUNNING' || line == 'ALREADY RUNNING');
  } catch (_) {}
  status ??= (await daemon.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .toList())
      .join('\n');
  return status;
}

Future<Process> _runDaemon(var workspace, {int timeout = 30}) async {
  await d.file('test.dart', '''
    // @dart=2.9
    import 'package:build_daemon/daemon.dart';
    import 'package:build_daemon/daemon_builder.dart';
    import 'package:build_daemon/client.dart';
    import 'package:build_daemon/src/fakes/fake_builder.dart';
    import 'package:build_daemon/src/fakes/fake_change_provider.dart';

    main() async {
      var options = ['foo'].toSet();
      var timeout = Duration(seconds: $timeout);
      var daemon = Daemon('$workspace');
      if(daemon.hasLock) {
        await daemon.start(
          options,
          FakeDaemonBuilder(),
          FakeChangeProvider(),
          timeout: timeout);
        // Real implementations of the daemon usually have
        // non-trivial set up time.
        await Future.delayed(Duration(seconds: 1));
        print('RUNNING');
      }else{
        // Mimic the behavior of actual daemon implementations.
        var version = await daemon.runningVersion();
        if(version != '$currentVersion') throw VersionSkew();
        print('ALREADY RUNNING');
      }
    }
      ''').create();

  var args = [
    ...Platform.executableArguments,
    if (!Platform.executableArguments
        .any((arg) => arg.startsWith('--packages')))
      '--packages=${(await Isolate.packageConfig)!.path}',
    'test.dart'
  ];
  var process = await Process.start(Platform.resolvedExecutable, args,
      workingDirectory: d.sandbox);

  return process;
}
