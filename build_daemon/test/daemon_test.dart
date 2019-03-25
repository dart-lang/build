// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build_daemon/constants.dart';
import 'package:build_daemon/daemon_builder.dart';
import 'package:build_daemon/src/daemon.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package:test/test.dart';
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
      var daemon = Daemon('$workspace');
      expect(daemon.tryGetLock(), isTrue);
      var timeout = Duration(seconds: 30);
      await daemon
          .start(<String>{}, DaemonBuilder(), Stream.empty(), timeout: timeout);
      expect(daemon.onDone, completes);
      await daemon.stop();
    });

    test('can run if no other daemon is running', () async {
      var workspace = uuid.v1();
      var daemon = await _runDaemon(workspace);
      testDaemons.add(daemon);
      expect(await getOutput(daemon), 'RUNNING');
    });

    test('shuts down if no client connects', () async {
      var workspace = uuid.v1();
      var daemon = await _runDaemon(workspace, timeout: 1);
      testDaemons.add(daemon);
      expect(await daemon.exitCode, isNotNull);
    });

    test('can not run if another daemon is running in the same workspace',
        () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      var daemonOne = await _runDaemon(workspace);
      expect(await getOutput(daemonOne), 'RUNNING');
      var daemonTwo = await _runDaemon(workspace);
      testDaemons.addAll([daemonOne, daemonTwo]);
      expect(await getOutput(daemonTwo), 'ALREADY RUNNING');
    });

    test('can run if another daemon is running in a different workspace',
        () async {
      var workspace1 = uuid.v1();
      var workspace2 = uuid.v1();
      testWorkspaces.addAll([workspace1, workspace2]);
      var daemonOne = await _runDaemon(workspace1);
      expect(await getOutput(daemonOne), 'RUNNING');
      var daemonTwo = await _runDaemon(workspace2);
      testDaemons.addAll([daemonOne, daemonTwo]);
      expect(await getOutput(daemonTwo), 'RUNNING');
    });

    test('logs the version when running', () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      var daemon = await _runDaemon(workspace);
      testDaemons.add(daemon);
      expect(await getOutput(daemon), 'RUNNING');
      expect(runningVersion(workspace), currentVersion);
    });

    test('does not set the current version if not running', () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      expect(runningVersion(workspace), null);
    });

    test('logs the options when running', () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      var daemon = await _runDaemon(workspace);
      testDaemons.add(daemon);
      expect(await getOutput(daemon), 'RUNNING');
      expect(currentOptions(workspace).contains('foo'), isTrue);
    });

    test('does not log the options if not running', () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      expect(currentOptions(workspace).isEmpty, isTrue);
    });

    test('cleans up after itself', () async {
      var workspace = uuid.v1();
      testWorkspaces.add(workspace);
      var daemon = await _runDaemon(workspace);
      // Wait for the daemon to be running before checking the workspace exits.
      expect(await getOutput(daemon), 'RUNNING');
      expect(Directory(daemonWorkspace(workspace)).existsSync(), isTrue);
      // Daemon expects sigint twice before quitting.
      daemon..kill(ProcessSignal.sigint)..kill(ProcessSignal.sigint);
      await daemon.exitCode;
      expect(Directory(daemonWorkspace(workspace)).existsSync(), isFalse);
    });
  });
}

Future<String> getOutput(Process daemon) async {
  return await daemon.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .firstWhere((line) => line == 'RUNNING' || line == 'ALREADY RUNNING');
}

Future<Process> _runDaemon(var workspace, {int timeout = 30}) async {
  await d.file('test.dart', '''
    import 'package:build_daemon/src/daemon.dart';
    import 'package:build_daemon/daemon_builder.dart';

    main() async {
      var daemon = Daemon('$workspace');
      if (daemon.tryGetLock()) {
        var options = ['foo'].toSet();
        var timeout = Duration(seconds: $timeout);
        await daemon.start(options, DaemonBuilder(), Stream.empty(),
        timeout: timeout);
        print('RUNNING');
      } else {
        print('ALREADY RUNNING');
      }
    }
      ''').create();

  var packageArg = await PackageResolver.current.processArgument;

  var process = await Process.start(
      Platform.resolvedExecutable, [packageArg, 'test.dart'],
      workingDirectory: d.sandbox);

  return process;
}
