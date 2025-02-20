// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' show min;

import 'package:bazel_worker/driver.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'scratch_space.dart';

final sdkDir = p.dirname(p.dirname(Platform.resolvedExecutable));

// If no terminal is attached, prevent a new one from launching.
final _processMode =
    stdin.hasTerminal
        ? ProcessStartMode.normal
        : ProcessStartMode.detachedWithStdio;

/// Completes once the dartdevk workers have been shut down.
Future<void> get dartdevkWorkersAreDone =>
    _dartdevkWorkersAreDoneCompleter?.future ?? Future.value();
Completer<void>? _dartdevkWorkersAreDoneCompleter;

/// Completes once the common frontend workers have been shut down.
Future<void> get frontendWorkersAreDone =>
    _frontendWorkersAreDoneCompleter?.future ?? Future.value();
Completer<void>? _frontendWorkersAreDoneCompleter;

final int _defaultMaxWorkers = min((Platform.numberOfProcessors / 2).ceil(), 4);

const _maxWorkersEnvVar = 'BUILD_MAX_WORKERS_PER_TASK';

final int maxWorkersPerTask = () {
  var toParse =
      Platform.environment[_maxWorkersEnvVar] ?? '$_defaultMaxWorkers';
  var parsed = int.tryParse(toParse);
  if (parsed == null) {
    log.warning(
      'Invalid value for $_maxWorkersEnvVar environment variable, '
      'expected an int but got `$toParse`. Falling back to default value '
      'of $_defaultMaxWorkers.',
    );
    return _defaultMaxWorkers;
  }
  return parsed;
}();

/// Manages a shared set of persistent dartdevk workers.
BazelWorkerDriver get _dartdevkDriver {
  _dartdevkWorkersAreDoneCompleter ??= Completer<void>();
  return __dartdevkDriver ??= BazelWorkerDriver(
    () => Process.start(
      p.join(sdkDir, 'bin', 'dart'),
      [
        p.join(sdkDir, 'bin', 'snapshots', 'dartdevc.dart.snapshot'),
        '--persistent_worker',
      ],
      mode: _processMode,
      workingDirectory: scratchSpace.tempDir.path,
    ),
    maxWorkers: maxWorkersPerTask,
  );
}

BazelWorkerDriver? __dartdevkDriver;

/// Resource for fetching the current [BazelWorkerDriver] for dartdevk.
final dartdevkDriverResource = Resource<BazelWorkerDriver>(
  () => _dartdevkDriver,
  beforeExit: () async {
    await __dartdevkDriver?.terminateWorkers();
    _dartdevkWorkersAreDoneCompleter?.complete();
    _dartdevkWorkersAreDoneCompleter = null;
    __dartdevkDriver = null;
  },
);

/// Manages a shared set of persistent common frontend workers.
BazelWorkerDriver get _frontendDriver {
  _frontendWorkersAreDoneCompleter ??= Completer<void>();
  return __frontendDriver ??= BazelWorkerDriver(
    () => Process.start(
      p.join(sdkDir, 'bin', 'dart'),
      [
        p.join(sdkDir, 'bin', 'snapshots', 'kernel_worker.dart.snapshot'),
        '--persistent_worker',
      ],
      mode: _processMode,
      workingDirectory: scratchSpace.tempDir.path,
    ),
    maxWorkers: maxWorkersPerTask,
  );
}

BazelWorkerDriver? __frontendDriver;

/// Resource for fetching the current [BazelWorkerDriver] for common frontend.
final frontendDriverResource = Resource<BazelWorkerDriver>(
  () => _frontendDriver,
  beforeExit: () async {
    await __frontendDriver?.terminateWorkers();
    _frontendWorkersAreDoneCompleter?.complete();
    _frontendWorkersAreDoneCompleter = null;
    __frontendDriver = null;
  },
);
