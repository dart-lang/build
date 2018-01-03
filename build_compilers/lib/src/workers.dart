// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' show min;

import 'package:bazel_worker/driver.dart';
import 'package:build/build.dart';
import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:path/path.dart' as p;

import 'scratch_space.dart';

/// Completes once the analyzer workers have been shut down.
Future<Null> get analyzerWorkersAreDone =>
    _analyzerWorkersAreDoneCompleter?.future ?? new Future.value(null);
Completer<Null> _analyzerWorkersAreDoneCompleter;

/// Completes once the dartdevc workers have been shut down.
Future<Null> get dartdevcWorkersAreDone =>
    _dartdevcWorkersAreDoneCompleter?.future ?? new Future.value(null);
Completer<Null> _dartdevcWorkersAreDoneCompleter;

/// Completes once the dartdevk workers have been shut down.
Future<Null> get dartdevkWorkersAreDone =>
    _dartdevkWorkersAreDoneCompleter?.future ?? new Future.value(null);
Completer<Null> _dartdevkWorkersAreDoneCompleter;

/// Completes once the common frontend workers have been shut down.
Future<Null> get frontendWorkersAreDone =>
    _frontendWorkersAreDoneCompleter?.future ?? new Future.value(null);
Completer<Null> _frontendWorkersAreDoneCompleter;

String get _scriptExtension => Platform.isWindows ? '.bat' : '';

final int _defaultMaxWorkers = min((Platform.numberOfProcessors / 2).ceil(), 4);

const _maxWorkersEnvVar = 'BUILD_MAX_WORKERS_PER_TASK';

final int _maxWorkersPerTask = int
    .parse(Platform.environment[_maxWorkersEnvVar] ?? '$_defaultMaxWorkers',
        onError: (value) {
  log.warning('Invalid value for $_maxWorkersEnvVar environment variable, '
      'expected an int but got `$value`. Falling back to default value '
      'of $_defaultMaxWorkers.');
  return _defaultMaxWorkers;
});

/// Manages a shared set of persistent analyzer workers.
BazelWorkerDriver get _analyzerDriver {
  _analyzerWorkersAreDoneCompleter ??= new Completer<Null>();
  return __analyzerDriver ??= new BazelWorkerDriver(
      () => Process.start(
          p.join(sdkDir, 'bin', 'dartanalyzer$_scriptExtension'),
          ['--build-mode', '--persistent_worker'],
          workingDirectory: scratchSpace.tempDir.path),
      maxWorkers: _maxWorkersPerTask);
}

BazelWorkerDriver __analyzerDriver;

/// Resource for fetching the current [BazelWorkerDriver] for dartanalyzer.
final analyzerDriverResource = new Resource<BazelWorkerDriver>(
    () => _analyzerDriver, beforeExit: () async {
  await _analyzerDriver?.terminateWorkers();
  _analyzerWorkersAreDoneCompleter.complete();
  _analyzerWorkersAreDoneCompleter = null;
  __analyzerDriver = null;
});

/// Manages a shared set of persistent dartdevc workers.
BazelWorkerDriver get _dartdevcDriver {
  _dartdevcWorkersAreDoneCompleter ??= new Completer<Null>();
  return __dartdevcDriver ??= new BazelWorkerDriver(
      () => Process.start(p.join(sdkDir, 'bin', 'dartdevc$_scriptExtension'),
          ['--persistent_worker'],
          workingDirectory: scratchSpace.tempDir.path),
      maxWorkers: _maxWorkersPerTask);
}

BazelWorkerDriver __dartdevcDriver;

/// Resource for fetching the current [BazelWorkerDriver] for dartdevc.
final dartdevcDriverResource = new Resource<BazelWorkerDriver>(
    () => _dartdevcDriver, beforeExit: () async {
  await _dartdevcDriver?.terminateWorkers();
  _dartdevcWorkersAreDoneCompleter.complete();
  _dartdevcWorkersAreDoneCompleter = null;
  __dartdevcDriver = null;
});

/// Manages a shared set of persistent dartdevk workers.
BazelWorkerDriver get _dartdevkDriver {
  _dartdevkWorkersAreDoneCompleter ??= new Completer<Null>();
  return __dartdevkDriver ??= new BazelWorkerDriver(
      () => Process.start(p.join(sdkDir, 'bin', 'dartdevk$_scriptExtension'),
          ['--persistent_worker'],
          workingDirectory: scratchSpace.tempDir.path),
      maxWorkers: _maxWorkersPerTask);
}

BazelWorkerDriver __dartdevkDriver;

/// Resource for fetching the current [BazelWorkerDriver] for dartdevk.
final dartdevkDriverResource = new Resource<BazelWorkerDriver>(
    () => _dartdevkDriver, beforeExit: () async {
  await _dartdevkDriver?.terminateWorkers();
  _dartdevkWorkersAreDoneCompleter.complete();
  _dartdevkWorkersAreDoneCompleter = null;
  __dartdevkDriver = null;
});

/// Manages a shared set of persistent common frontend workers.
BazelWorkerDriver get _frontendDriver {
  _frontendWorkersAreDoneCompleter ??= new Completer<Null>();
  return __frontendDriver ??= new BazelWorkerDriver(
      () => Process.start(
          p.join(sdkDir, 'bin', 'dart'),
          [
            p.join(
                sdkDir, 'bin', 'snapshots', 'kernel_summary_worker.dart.snapshot'),
            '--persistent_worker'
          ],
          workingDirectory: scratchSpace.tempDir.path),
      maxWorkers: _maxWorkersPerTask);
}

BazelWorkerDriver __frontendDriver;

/// Resource for fetching the current [BazelWorkerDriver] for common frontend.
final frontendDriverResource = new Resource<BazelWorkerDriver>(
    () => _frontendDriver, beforeExit: () async {
  await _frontendDriver?.terminateWorkers();
  _frontendWorkersAreDoneCompleter.complete();
  _frontendWorkersAreDoneCompleter = null;
  __frontendDriver = null;
});

final sdkDir = cli_util.getSdkPath();
