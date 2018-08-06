// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _generatedDir = Directory(p.join(_toolDir.path, 'generated'));
Directory _toolDir = Directory(p.join('.dart_tool', 'build'));

Process _process;
Stream<String> _stdOutLines;

final String _pubBinary = Platform.isWindows ? 'pub.bat' : 'pub';

/// Runs a single build using `pub run build_runner build`, and returns the
/// [ProcessResult].
Future<ProcessResult> runBuild({List<String> trailingArgs = const []}) =>
    _runBuild(
        _pubBinary, ['run', 'build_runner', 'build']..addAll(trailingArgs));

/// Runs `pub run build_runner <args>`, and returns the [ProcessResult].
Future<ProcessResult> runCommand(List<String> args) =>
    _runBuild(_pubBinary, ['run', 'build_runner']..addAll(args));

/// Runs `pub run build_runner serve` in this package, and waits for the first
/// build to complete.
///
/// To ensure a clean build, set [ensureCleanBuild] to `true`.
///
/// This expects the first build to complete successfully, but you can add extra
/// expects that happen before that using [extraExpects]. All of these will be
/// invoked and awaited before awaiting the next successful build.
Future<Null> startServer(
        {bool ensureCleanBuild,
        List<Function> extraExpects,
        List<String> buildArgs}) =>
    _startServer(_pubBinary,
        ['run', 'build_runner', 'serve']..addAll(buildArgs ?? const []),
        ensureCleanBuild: ensureCleanBuild, extraExpects: extraExpects);

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

Future<Null> _startServer(String command, List<String> buildArgs,
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
Future<Null> stopServer({bool cleanUp}) async {
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

Future<Null> _resetGitClient() async {
  if (_gitIsClean()) return;

  // Reset our state after each test, assuming we didn't abandon tests due
  // to a non-pristine git environment.
  Process.runSync('git', ['checkout', 'HEAD', '--', '.']);

  Future<Null> nextBuild;
  if (_process != null) nextBuild = nextSuccessfulBuild;
  // Delete the untracked files.
  await Process.run('git', ['clean', '-df', '.']);
  if (nextBuild != null) await nextBuild;
}

Future<Null> get nextSuccessfulBuild async {
  await _stdOutLines.firstWhere((line) => line.contains('Succeeded after'));
}

Future<Null> get nextFailedBuild async {
  await _stdOutLines.firstWhere((line) => line.contains('Failed after'));
}

Future<String> nextStdOutLine(String message) =>
    _stdOutLines.firstWhere((line) => line.contains(message));

/// Runs tests using the auto build script.
Future<ProcessResult> runTests(
    {bool usePrecompiled, List<String> buildArgs, List<String> testArgs}) {
  return _runTests(_pubBinary, ['run', 'build_runner'],
      usePrecompiled: usePrecompiled, buildArgs: buildArgs, testArgs: testArgs);
}

Future<ProcessResult> _runTests(String executable, List<String> scriptArgs,
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
    return Process.run(executable, args);
  } else {
    var args = ['run', 'test', '--pub-serve', '8081']..addAll(testArgs);
    return Process.run(_pubBinary, args);
  }
}

Future<Null> expectTestsFail() async {
  var result = await runTests();
  printOnFailure('${result.stderr}');
  expect(result.stdout, contains('Some tests failed'));
  expect(result.exitCode, isNot(0));
}

Future<Null> expectTestsPass(
    {int expectedNumRan, bool usePrecompiled, List<String> args}) async {
  var result = await runTests(usePrecompiled: usePrecompiled, buildArgs: args);
  printOnFailure('${result.stderr}');
  expect(result.stdout, contains('All tests passed!'));
  if (expectedNumRan != null) {
    expect(result.stdout, contains('+$expectedNumRan'));
    expect(result.stdout, isNot(contains('+${expectedNumRan + 1}')));
  }
}

Future<Null> createFile(String path, String contents) async {
  var file = File(path);
  expect(await file.exists(), isFalse);
  await file.create(recursive: true);
  await file.writeAsString(contents);
}

Future<Null> deleteFile(String path) async {
  var file = File(path);
  expect(await file.exists(), isTrue);
  await file.delete();
}

Future<String> readGeneratedFileAsString(String path) async {
  var file = File(p.join(_generatedDir.path, path));
  expect(await file.exists(), isTrue);
  return file.readAsString();
}

Future<Null> replaceAllInFile(String path, Pattern from, String replace) async {
  var file = File(path);
  expect(await file.exists(), isTrue);
  var content = await file.readAsString();
  await file.writeAsString(content.replaceAll(from, replace));
}
