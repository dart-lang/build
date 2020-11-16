// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

Directory _generatedDir = Directory(p.join(_toolDir.path, 'generated'));
Directory _toolDir = Directory(p.join('.dart_tool', 'build'));

Process _process;
Stream<String> _stdOutLines;
Stream<String> get stdOutLines => _stdOutLines;

final String _pubBinary = Platform.isWindows ? 'pub.bat' : 'pub';

/// Runs a single build using `pub run build_runner build`, and returns the
/// [ProcessResult].
Future<ProcessResult> runBuild({List<String> trailingArgs = const []}) =>
    _runBuild(_pubBinary, ['run', 'build_runner', 'build', ...trailingArgs]);

/// Runs `pub run build_runner <args>`, and returns the [ProcessResult].
Future<ProcessResult> runCommand(List<String> args) =>
    _runBuild(_pubBinary, ['run', 'build_runner', ...args]);

/// Runs `pub run build_runner serve` in this package, and waits for the first
/// build to complete.
///
/// To ensure a clean build, set [ensureCleanBuild] to `true`.
///
/// This expects the first build to complete successfully, but you can add extra
/// expects that happen before that using [extraExpects]. All of these will be
/// invoked and awaited before awaiting the next successful build.
Future<void> startServer(
        {bool ensureCleanBuild,
        List<Function> extraExpects,
        List<String> buildArgs}) =>
    _startServer(
        'dart',
        [
          '--packages=.packages',
          p.join('..', 'build_runner', 'bin', 'build_runner.dart'),
          'serve',
          if (buildArgs != null) ...buildArgs,
        ],
        ensureCleanBuild: ensureCleanBuild,
        extraExpects: extraExpects);

Future<ProcessResult> _runBuild(String command, List<String> args,
    {bool ensureCleanBuild}) async {
  ensureCleanBuild ??= false;

  // Make sure this is a clean build
  if (ensureCleanBuild && await _toolDir.exists()) {
    await _toolDir.delete(recursive: true);
  }

  final result = await Process.run(command, args);
  printOnFailure('${result.stdout}');
  printOnFailure('${result.stderr}');
  return result;
}

Future<void> _startServer(String command, List<String> buildArgs,
    {bool ensureCleanBuild, List<Function> extraExpects}) async {
  ensureCleanBuild ??= false;
  extraExpects ??= [];

  // Make sure this is a clean build
  if (ensureCleanBuild && await _toolDir.exists()) {
    await _toolDir.delete(recursive: true);
  }

  _process = await Process.start(command, buildArgs);
  _stdOutLines = _process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .asBroadcastStream();

  var stdErrLines = _process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .asBroadcastStream();

  _stdOutLines.listen((line) => printOnFailure('StdOut: $line'));
  stdErrLines.listen((line) => printOnFailure('StdErr: $line'));

  extraExpects.add(() => nextSuccessfulBuild);
  await Future.wait(extraExpects.map((cb) async => await cb()));
}

/// Kills the current build script.
///
/// To clean up the `.dart_tool` directory as well, set [cleanUp] to `true`.
Future<void> stopServer({bool cleanUp}) async {
  cleanUp ??= false;
  if (_process != null) {
    expect(_process.kill(), true);
    await _process.exitCode;
    _process = null;
  }
  _stdOutLines = null;

  if (cleanUp && await _toolDir.exists()) {
    await _toolDir.delete(recursive: true);
  }
}

/// Checks whether the current git client is "clean" (no pending changes) for
/// this package directory.
bool _gitIsClean() {
  var gitStatus = Process.runSync('git', ['status', '.']).stdout as String;
  return gitStatus.contains('nothing to commit, working tree clean');
}

/// Ensures that the current directory is a "clean" git client (no pending
/// changes).
///
/// This also calls `addTearDown` with a method that will reset the current git
/// state for this directory after running the test.
void ensureCleanGitClient() {
  var gitWasClean = _gitIsClean();
  expect(gitWasClean, isTrue,
      reason: 'Not running on a clean git client, aborting test.\n');

  addTearDown(_resetGitClient);
}

Future<void> _resetGitClient() async {
  if (_gitIsClean()) return;

  // Reset our state after each test, assuming we didn't abandon tests due
  // to a non-pristine git environment.
  Process.runSync('git', ['checkout', 'HEAD', '--', '.']);

  Future<void> nextBuild;
  if (_process != null) nextBuild = nextSuccessfulBuild;
  // Delete the untracked files.
  await Process.run('git', ['clean', '-df', '.']);
  if (nextBuild != null) await nextBuild;
}

Future<void> get nextSuccessfulBuild async {
  await _stdOutLines.firstWhere((line) => line.contains('Succeeded after'));
}

Future<void> get nextFailedBuild async {
  await _stdOutLines.firstWhere((line) => line.contains('Failed after'));
}

Future<String> nextStdOutLine(String message) =>
    _stdOutLines.firstWhere((line) => line.contains(message));

/// Runs tests using the auto build script.
Future<TestProcess> runTests(
    {bool usePrecompiled,
    List<String> buildArgs,
    List<String> testArgs}) async {
  return _runTests(_pubBinary, ['run', 'build_runner'],
      usePrecompiled: usePrecompiled, buildArgs: buildArgs, testArgs: testArgs);
}

Future<TestProcess> _runTests(String executable, List<String> scriptArgs,
    {bool usePrecompiled,
    List<String> buildArgs,
    List<String> testArgs}) async {
  usePrecompiled ??= true;
  testArgs ??= [];
  testArgs.addAll(['-p', 'chrome']);
  if (usePrecompiled) {
    var args = scriptArgs.toList()
      ..add('test')
      ..add('--verbose')
      ..addAll(buildArgs ?? [])
      ..add('--')
      ..addAll(testArgs);
    return TestProcess.start(executable, args);
  } else {
    var args = ['run', 'test', '--pub-serve', '8081', ...testArgs];
    return TestProcess.start(_pubBinary, args);
  }
}

Future<void> expectTestsFail(
    {bool usePrecompiled,
    List<String> buildArgs,
    List<String> testArgs}) async {
  var result = await runTests(
      usePrecompiled: usePrecompiled, buildArgs: buildArgs, testArgs: testArgs);
  expect(result.stdout, emitsThrough(contains('Some tests failed')));
  expect(await result.exitCode, isNot(0));
}

Future<void> expectTestsPass(
    {int expectedNumRan,
    bool usePrecompiled,
    List<String> buildArgs,
    List<String> testArgs}) async {
  var result = await runTests(
      usePrecompiled: usePrecompiled, buildArgs: buildArgs, testArgs: testArgs);
  var allLines = await result.stdout.rest.toList();
  expect(allLines, contains(contains('All tests passed!')));
  if (expectedNumRan != null) {
    expect(allLines, contains(contains('+$expectedNumRan')));
    expect(allLines, isNot(contains(contains('+${expectedNumRan + 1}'))));
  }
  expect(await result.exitCode, 0);
}

Future<void> createFile(String path, String contents) async {
  var file = File(path);
  expect(await file.exists(), isFalse);
  await file.create(recursive: true);
  await file.writeAsString(contents);
}

Future<void> deleteFile(String path) async {
  var file = File(path);
  expect(await file.exists(), isTrue);
  await file.delete();
}

Future<String> readGeneratedFileAsString(String path) async {
  var file = File(p.join(_generatedDir.path, path));
  expect(await file.exists(), isTrue);
  return file.readAsString();
}

Future<void> replaceAllInFile(String path, Pattern from, String replace) async {
  var file = File(path);
  expect(await file.exists(), isTrue);
  var content = await file.readAsString();
  await file.writeAsString(content.replaceAll(from, replace));
}
