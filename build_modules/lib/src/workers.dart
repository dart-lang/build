// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

import 'package:bazel_worker/driver.dart';
import 'package:build/build.dart';
import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:path/path.dart' as p;

import 'scratch_space.dart';

final sdkDir = cli_util.getSdkPath();

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

/// Completes once the dart2js workers have been shut down.
Future<Null> get dart2jsWorkersAreDone =>
    _dart2jsWorkersAreDoneCompleter?.future ?? new Future.value(null);
Completer<Null> _dart2jsWorkersAreDoneCompleter;

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
            p.join(sdkDir, 'bin', 'snapshots',
                'kernel_summary_worker.dart.snapshot'),
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

/// Manages a shared set of persistent dart2js workers.
Dart2JsBatchWorker get _dart2jsWorker {
  _dart2jsWorkersAreDoneCompleter ??= new Completer<Null>();
  return __dart2jsWorker ??= new Dart2JsBatchWorker(() => Process.start(
      p.join(sdkDir, 'bin', 'dart2js$_scriptExtension'), ['--batch'],
      workingDirectory: scratchSpace.tempDir.path));
}

Dart2JsBatchWorker __dart2jsWorker;

/// Resource for fetching the current [Dart2JsBatchWorker] for dart2js.
final dart2JsWorkerResource = new Resource<Dart2JsBatchWorker>(
    () => _dart2jsWorker, beforeExit: () async {
  await _dart2jsWorker.terminateWorkers();
  _dart2jsWorkersAreDoneCompleter.complete();
  _dart2jsWorkersAreDoneCompleter = null;
});

/// Manages a persistent dart2js worker running in batch mode and schedules jobs
/// one at a time.
class Dart2JsBatchWorker {
  final Future<Process> Function() _spawnWorker;

  Stream<String> __workerStderrLines;
  Stream<String> get _workerStderrLines {
    assert(__worker != null);
    return __workerStderrLines ??= __worker.stderr
        .transform(UTF8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
  }

  Stream<String> __workerStdoutLines;
  Stream<String> get _workerStdoutLines {
    assert(__worker != null);
    return __workerStdoutLines ??= __worker.stdout
        .transform(UTF8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
  }

  Process __worker;
  Future<Process> get _worker async {
    __worker ??= await _spawnWorker();
    return __worker;
  }

  final _workQueue = new Queue<_Dart2JsJob>();

  bool _queueIsActive = false;

  Dart2JsBatchWorker(this._spawnWorker);

  Future<Dart2JsResult> compile(List<String> args) async {
    var job = new _Dart2JsJob(args);
    _workQueue.add(job);
    if (!_queueIsActive) _startWorkQueue();
    return job.result;
  }

  void _startWorkQueue() {
    assert(!_queueIsActive);
    _queueIsActive = true;
    () async {
      while (_workQueue.isNotEmpty) {
        var worker = await _worker;
        var next = _workQueue.removeFirst();
        var output = new StringBuffer();
        var sawError = false;
        var stderrListener = _workerStderrLines.listen((line) {
          if (line == '>>> EOF STDERR') {
            next.resultCompleter.complete(new Dart2JsResult(
                !sawError, 'Dart2Js finished with:\n\n$output'));
          }
          if (!line.startsWith('>>> ')) {
            output.writeln(line);
          }
        });
        var stdoutListener = _workerStdoutLines.listen((line) {
          if (line.contains('>>> TEST FAIL')) {
            sawError = true;
          }
          if (!line.startsWith('>>> ')) {
            output.writeln(line);
          }
        });

        log.info('Running dart2js with ${next.args.join(' ')}\n');
        worker.stdin.writeln(next.args.join(' '));

        await next.result;
        await stderrListener.cancel();
        await stdoutListener.cancel();
      }
      _queueIsActive = false;
    }();
  }

  Future<Null> terminateWorkers() async {
    var worker = await _worker;
    __worker = null;
    __workerStdoutLines = null;
    __workerStderrLines = null;
    worker.kill();
    await worker.exitCode;
  }
}

/// A single dart2js job, consisting of [args] and a [result].
class _Dart2JsJob {
  final List<String> args;

  final resultCompleter = new Completer<Dart2JsResult>();
  Future<Dart2JsResult> get result => resultCompleter.future;

  _Dart2JsJob(this.args);
}

/// The result of a [_Dart2JsJob]
class Dart2JsResult {
  final bool succeeded;
  final String output;

  Dart2JsResult(this.succeeded, this.output);
}
