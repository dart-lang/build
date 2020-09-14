// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'package:build_runner_core/src/util/constants.dart';

String _dartBinary = p.join(sdkBin, 'dart');

/// Runs `pub get` on [package] (which is assumed to be in a directory with
/// that name under the [d.sandbox] directory).
Future<ProcessResult> pubGet(String package, {bool offline}) async {
  offline ??= true;
  var pubGetresult =
      await runPub(package, 'get', args: offline ? ['--offline'] : []);
  expect(pubGetresult.exitCode, 0, reason: pubGetresult.stderr as String);
  return pubGetresult;
}

/// Runs the `pub` [command] on [package] with [args].
Future<ProcessResult> runPub(String package, String command,
        {Iterable<String> args}) =>
    Process.run(pubBinary, [command, ...?args],
        workingDirectory: p.join(d.sandbox, package));

/// Starts the `pub` [command] on [package] with [args].
Future<Process> startPub(String package, String command,
        {Iterable<String> args}) =>
    Process.start(pubBinary, [command, ...args ?? []],
        workingDirectory: p.join(d.sandbox, package));

/// Runs the `dart` script [script] in [package] with [args].
///
/// The [script] should be a relative path under [package].
Future<ProcessResult> runDart(String package, String script,
        {Iterable<String> args}) =>
    Process.run(_dartBinary, [script, ...?args],
        workingDirectory: p.join(d.sandbox, package));

/// Starts the `dart` script [script] in [package] with [args].
///
/// The [script] should be a relative path under [package].
Future<Process> startDart(String package, String script,
        {Iterable<String> args}) =>
    Process.start(_dartBinary, [script, ...?args],
        workingDirectory: p.join(d.sandbox, package));
