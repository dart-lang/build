// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' show min;

import 'package:bazel_worker/driver.dart';
import 'package:build/build.dart';
import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'scratch_space.dart';

/// On windows some tools have to be executed with the `.bat` extension.
final String _scriptExtension = Platform.isWindows ? '.bat' : '';

/// Returns the path to the SDK.
final String sdkDir = cli_util.getSdkPath();

/// Returns the path to a binary in the SDK.
String _sdkBin(String name) => p.join(sdkDir, 'bin', '$name$_scriptExtension');

final int _defaultMaxWorkers = min((Platform.numberOfProcessors / 2).ceil(), 4);
const _maxWorkersEnvVar = 'BUILD_MAX_WORKERS_PER_TASK';
final int _maxWorkersPerTask = int.parse(
  Platform.environment[_maxWorkersEnvVar] ?? '$_defaultMaxWorkers',
  onError: (value) {
    log.warning('Invalid value for $_maxWorkersEnvVar environment variable, '
        'expected an int but got `$value`. Falling back to default value '
        'of $_defaultMaxWorkers.');
    return _defaultMaxWorkers;
  },
);

/// Encapsulates running an external tool in a sandbox as a compiler.
///
/// TODO: Consider making this public in build_compilers(?) in the future.
abstract class BatchWorker {
  BazelWorkerDriver _driver;
  Completer<Null> _onDone;
  Resource<BatchWorker> _resource;

  /// Returns a unified interface around a worker process.
  BazelWorkerDriver _createDriver() {
    return _driver ??= new BazelWorkerDriver(
      () => startProcess(scratchSpace.tempDir.path),
      maxWorkers: _maxWorkersPerTask,
    );
  }

  /// Executes the following command [args] against the worker.
  ///
  /// Returns a [WorkResponse] object from `package:bazel_worker`.
  Future<WorkResponse> execute(List<String> args) async {
    return _driver.doWork(new WorkRequest()..arguments.addAll(args));
  }

  /// Completes when the worker is considered complete and shut down.
  ///
  /// A worker that has not started is always considered "done".
  ///
  /// TODO: Consider different naming, i.e. is/isNotActive(?).
  Future<Null> get isDone => _onDone?.future ?? new Future.value();

  /// Resource for accessing the spawned process.
  ///
  /// Can be used with [BuildStep.fetchResource].
  Resource<BatchWorker> get resource {
    return _resource ??= new Resource<BatchWorker>(
      () {
        _createDriver();
        return this;
      },
      beforeExit: () async {
        await _driver?.terminateWorkers();
        _driver = null;
        _onDone?.complete();
        _onDone = null;
      },
    );
  }

  /// Starts a persistent worker in [workingDirectory].
  @protected
  Future<Process> startProcess(String workingDirectory);
}

final BatchWorker analyzerWorker = new _AnalyzerWorker();

class _AnalyzerWorker extends BatchWorker {
  static final _defaultPath = _sdkBin('dartanalyzer');

  @override
  Future<Process> startProcess(String workingDirectory) {
    return Process.start(
      _defaultPath,
      const [
        '--build-mode',
        '--persistent_worker',
      ],
      workingDirectory: workingDirectory,
    );
  }
}

final BatchWorker dartdevcWorker = new _DartDevCWorker();

class _DartDevCWorker extends BatchWorker {
  static final _defaultPath = _sdkBin('dartdevc');

  @override
  Future<Process> startProcess(String workingDirectory) {
    return Process.start(
      _defaultPath,
      const ['--persistent_worker'],
      workingDirectory: workingDirectory,
    );
  }
}

final BatchWorker dart2jsWorker = new _Dart2JsWorker();

// TODO: Actually use in a builder.
//
// It's here to make the point that refactoring the common code into
// "BatchWorker" was worth it, but it will be used momentarily to power a
// builder.
class _Dart2JsWorker extends BatchWorker {
  static final _defaultPath = _sdkBin('dartj2s');

  @override
  Future<Process> startProcess(String workingDirectory) {
    return Process.start(
      _defaultPath,
      const ['--batch'],
      workingDirectory: workingDirectory,
    );
  }
}
