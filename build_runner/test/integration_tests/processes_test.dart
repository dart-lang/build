// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration4'])
library;

import 'dart:io';

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('processes', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      files: {},
    );

    // `stdout.write` is used instead of print to avoid introducing a line
    // ending difference on Windows.

    // Message passing.
    tester.write('root_pkg/bin/parent.dart', r'''
import 'dart:io';
import 'package:build_runner/src/bootstrap/processes.dart';
Future<void> main() async {
  stdout.write('Parent is running.\n');
  final processResult = await ParentProcess.runAndSend(
      script: 'bin/child.dart',
      arguments: [],
      jitVmArgs: [],
      message: 'payload');
  stdout.write(
      'Parent received: '
      '${processResult.exitCode} ${processResult.message}\n');
}
''');
    tester.write('root_pkg/bin/child.dart', r'''
import 'dart:io';
import 'package:build_runner/src/bootstrap/processes.dart';
void main() async {
  stdout.write('Child is running.\n');
  final message = await ChildProcess.receive();
  stdout.write('Child received: $message\n');
  ChildProcess.exitWithMessage(exitCode: 7, message: 'result');
}
''');
    final output = await tester.run('root_pkg', 'dart run root_pkg:parent');
    expect(
      output,
      contains('''
Parent is running.
Child is running.
Child received: payload
Parent received: 7 result
'''),
    );

    // Succeeds without `dart` on the path.
    final dart = Platform.resolvedExecutable;
    await tester.run(
      'root_pkg',
      '$dart run root_pkg:parent',
      environment: {'PATH': ''},
    );

    // ParentProcess.runAndSend: killing parent kills the child.
    tester.write('root_pkg/bin/parent.dart', r'''
import 'dart:io';
import 'package:build_runner/src/bootstrap/processes.dart';
Future<void> main() async {
  stdout.write('Parent is running. $pid\n');
  await ParentProcess.runAndSend(
      script: 'bin/child.dart',
      arguments: [],
      jitVmArgs: [],
      message: 'payload');
}
''');
    tester.write('root_pkg/bin/child.dart', r'''
import 'dart:io';
import 'package:build_runner/src/bootstrap/processes.dart';
void main() async {
  final message = await ChildProcess.receive();
  stdout.write('Child is waiting. $pid\n');
  await Future.delayed(Duration(seconds: 60));
}
''');
    var process = await tester.start('root_pkg', 'dart run root_pkg:parent');
    var parentLine = await process.expectAndGetLine(
      RegExp(r'Parent is running\. \d+'),
    );
    var parentPid = int.parse(parentLine.split(' ').last);
    final childLine = await process.expectAndGetLine(
      RegExp(r'Child is waiting\. \d+'),
    );
    var childPid = int.parse(childLine.split(' ').last);

    expect(processIsRunning(parentPid), true);
    expect(processIsRunning(childPid), true);

    // Check that `processIsRunning` is not changing the state of the process.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(processIsRunning(parentPid), true);
    expect(processIsRunning(childPid), true);

    await process.kill();

    expect(processIsRunning(parentPid), false);
    expect(processIsRunning(childPid), false);

    // ParentProcess.run: killing parent kills the child.
    tester.write('root_pkg/bin/parent.dart', r'''
import 'dart:io';
import 'package:build_runner/src/bootstrap/processes.dart';
Future<void> main() async {
  stdout.write('Parent is running. $pid\n');
  await ParentProcess.run('dart', ['bin/child.dart']);
}
''');
    tester.write('root_pkg/bin/child.dart', r'''
import 'dart:io';
void main() async {
  File('pid.txt').writeAsStringSync('$pid');
  await Future.delayed(Duration(seconds: 60));
}
''');
    process = await tester.start('root_pkg', 'dart run root_pkg:parent');
    parentLine = await process.expectAndGetLine(
      RegExp(r'Parent is running\. \d+'),
    );
    parentPid = int.parse(parentLine.split(' ').last);

    while (tester.read('root_pkg/pid.txt') == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    childPid = int.parse(tester.read('root_pkg/pid.txt')!);

    expect(processIsRunning(parentPid), true);
    expect(processIsRunning(childPid), true);
    await process.kill();
    expect(processIsRunning(parentPid), false);
    expect(processIsRunning(childPid), false);
  });
}

bool processIsRunning(int pid) {
  if (Platform.isWindows) {
    return Process.runSync('powershell', [
          '-Command',
          'Get-Process -Id $pid',
        ]).exitCode ==
        0;
  } else {
    return Process.runSync('kill', ['-0', '$pid']).exitCode == 0;
  }
}
