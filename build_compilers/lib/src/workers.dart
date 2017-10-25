// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math' show min;

import 'package:bazel_worker/driver.dart';
import 'package:build/build.dart';
import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:path/path.dart' as p;

import 'scratch_space.dart';

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
BazelWorkerDriver get _analyzerDriver => __analyzerDriver ??=
    new BazelWorkerDriver(
        () => Process.start(
            p.join(sdkDir, 'bin', 'dartanalyzer$_scriptExtension'),
            ['--build-mode', '--persistent_worker'],
            workingDirectory: scratchSpace.tempDir.path),
        maxWorkers: _maxWorkersPerTask);
BazelWorkerDriver __analyzerDriver;

/// Resource for fetching the current [BazelWorkerDriver] for dartanalyzer.
final analyzerDriverResource = new Resource<BazelWorkerDriver>(
    () => _analyzerDriver, beforeExit: () async {
  await _analyzerDriver?.terminateWorkers();
  __analyzerDriver = null;
});

/// Manages a shared set of persistent dartdevc workers.
BazelWorkerDriver get _dartdevcDriver => __dartdevcDriver ??=
    new BazelWorkerDriver(
        () => Process.start(p.join(sdkDir, 'bin', 'dartdevc$_scriptExtension'),
            ['--persistent_worker'],
            workingDirectory: scratchSpace.tempDir.path),
        maxWorkers: _maxWorkersPerTask);
BazelWorkerDriver __dartdevcDriver;

/// Resource for fetching the current [BazelWorkerDriver] for dartdevc.
final dartdevcDriverResource = new Resource<BazelWorkerDriver>(
    () => _dartdevcDriver, beforeExit: () async {
  await _dartdevcDriver?.terminateWorkers();
  __dartdevcDriver = null;
});

final sdkDir = cli_util.getSdkPath();
