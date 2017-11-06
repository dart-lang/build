// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _generatedDir = new Directory(p.join(_toolDir.path, 'generated'));
Directory _toolDir = new Directory(p.join('.dart_tool', 'build'));

Process _process;
Stream<String> _stdErrLines;
Stream<String> _stdOutLines;

/// Runs the build script in this package, and waits for the first build to
/// complete.
///
/// By default, this ensures a brand new build by deleting the `.dart_tool`
/// directory, but you can disable this by setting [ensureCleanBuild] to
/// `false`.
///
/// This expects the first build to complete successfully, but you can add extra
/// expects that happen before that using [extraExpects]. All of these will be
/// invoked and awaited before awaiting the next successful build.
///
/// For debugging purposes you can enable printing of the build script output by
/// setting [verbose] to `true`.
Future<Null> startServer(
    {bool ensureCleanBuild, bool verbose, List<Function> extraExpects}) async {
  ensureCleanBuild ??= true;
  verbose ??= false;
  extraExpects ??= [];

  // Make sure this is a clean build
  if (ensureCleanBuild && await _toolDir.exists()) {
    await _toolDir.delete(recursive: true);
  }

  _process = await Process.start('dart', ['tool/build.dart']);
  _stdOutLines = _process.stdout
      .transform(UTF8.decoder)
      .transform(const LineSplitter())
      .asBroadcastStream();

  _stdErrLines = _process.stderr
      .transform(UTF8.decoder)
      .transform(const LineSplitter())
      .asBroadcastStream();

  if (verbose) {
    _stdOutLines.listen((line) => print('StdOut: $line'));
    _stdErrLines.listen((line) => print('StdErr: $line'));
  }

  await Future.wait(extraExpects.map((cb) async => await cb()));
  await nextSuccessfulBuild;
}

/// Kills the current build script.
///
/// By default this will clean up the `.dart_tool` directory, but you can
/// disable this by setting [cleanUp] to `false`.
Future<Null> stopServer({bool cleanUp}) async {
  cleanUp ??= true;
  expect(_process.kill(), true);
  await _process.exitCode;
  _process = null;

  if (cleanUp) await _toolDir.delete(recursive: true);
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
  // Delete the untracked files.
  var gitStatus =
      Process.runSync('git', ['status', '--porcelain', '.']).stdout as String;

  Future<Null> nextBuild;
  if (_process != null) nextBuild = nextSuccessfulBuild;
  var untracked = gitStatus
      .split('\n')
      .where((line) => line.startsWith('??'))
      .map((line) => line.split(' ')[1])
      .map((path) {
    var parts = p.split(path);
    assert(parts[0] == 'e2e_example');
    return p.joinAll(parts.skip(1));
  });
  for (var path in untracked) {
    Process.runSync('rm', [path]);
  }
  if (nextBuild != null) await nextBuild;
}

Future<Null> get nextSuccessfulBuild async {
  await _stdOutLines
      .firstWhere((line) => line.contains('Build: Succeeded after'));
}

Future<Null> get nextFailedBuild async {
  await _stdErrLines.firstWhere((line) => line.contains('Build: Failed after'));
}

Future<String> nextStdErrLine(String message) =>
    _stdErrLines.firstWhere((line) => line.contains(message)) as Future<String>;

Future<String> nextStdOutLine(String message) =>
    _stdOutLines.firstWhere((line) => line.contains(message)) as Future<String>;

Future<ProcessResult> runTests() =>
    Process.run('pub', ['run', 'test', '--pub-serve', '8081', '-p', 'chrome']);

Future<Null> expectTestsFail() async {
  var result = await runTests();
  expect(result.stdout, contains('Some tests failed'));
}

Future<Null> expectTestsPass([int numRan]) async {
  var result = await runTests();
  expect(result.stdout, contains('All tests passed!'));
  if (numRan != null) {
    expect(result.stdout, contains('+$numRan'));
    expect(result.stdout, isNot(contains('+${numRan + 1}')));
  }
}

Future<Null> createFile(String path, String contents) async {
  var file = new File(path);
  expect(await file.exists(), isFalse);
  await file.create(recursive: true);
  await file.writeAsString(contents);
}

Future<Null> deleteFile(String path) async {
  var file = new File(path);
  expect(await file.exists(), isTrue);
  await file.delete();
}

Future<String> readGeneratedFileAsString(String path) async {
  var file = new File(p.join(_generatedDir.path, path));
  return file.readAsString();
}

Future<Null> replaceAllInFile(String path, String from, String replace) async {
  var file = new File(path);
  expect(await file.exists(), isTrue);
  var content = await file.readAsString();
  await file.writeAsString(content.replaceAll(from, replace));
}
