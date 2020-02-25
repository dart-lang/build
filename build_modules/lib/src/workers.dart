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
import 'package:path/path.dart' as p;
import 'package:pedantic/pedantic.dart';

import 'scratch_space.dart';

final sdkDir = p.dirname(p.dirname(Platform.resolvedExecutable));

// If no terminal is attached, prevent a new one from launching.
final _processMode = stdin.hasTerminal
    ? ProcessStartMode.normal
    : ProcessStartMode.detachedWithStdio;

/// Completes once the dartdevk workers have been shut down.
Future<void> get dartdevkWorkersAreDone =>
    _dartdevkWorkersAreDoneCompleter?.future ?? Future.value();
Completer<void> _dartdevkWorkersAreDoneCompleter;

/// Completes once the dart2js workers have been shut down.
Future<void> get dart2jsWorkersAreDone =>
    _dart2jsWorkersAreDoneCompleter?.future ?? Future.value();
Completer<void> _dart2jsWorkersAreDoneCompleter;

/// Completes once the common frontend workers have been shut down.
Future<void> get frontendWorkersAreDone =>
    _frontendWorkersAreDoneCompleter?.future ?? Future.value();
Completer<void> _frontendWorkersAreDoneCompleter;

final int _defaultMaxWorkers = min((Platform.numberOfProcessors / 2).ceil(), 4);

const _maxWorkersEnvVar = 'BUILD_MAX_WORKERS_PER_TASK';

final int _maxWorkersPerTask = () {
  var toParse =
      Platform.environment[_maxWorkersEnvVar] ?? '$_defaultMaxWorkers';
  var parsed = int.tryParse(toParse);
  if (parsed == null) {
    log.warning('Invalid value for $_maxWorkersEnvVar environment variable, '
        'expected an int but got `$toParse`. Falling back to default value '
        'of $_defaultMaxWorkers.');
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
            '--kernel',
            '--persistent_worker'
          ],
          mode: _processMode,
          workingDirectory: scratchSpace.tempDir.path),
      maxWorkers: _maxWorkersPerTask);
}

BazelWorkerDriver __dartdevkDriver;

/// Resource for fetching the current [BazelWorkerDriver] for dartdevk.
final dartdevkDriverResource =
    Resource<BazelWorkerDriver>(() => _dartdevkDriver, beforeExit: () async {
  await _dartdevkDriver?.terminateWorkers();
  _dartdevkWorkersAreDoneCompleter.complete();
  _dartdevkWorkersAreDoneCompleter = null;
  __dartdevkDriver = null;
});

/// Manages a shared set of persistent common frontend workers.
BazelWorkerDriver get _frontendDriver {
  _frontendWorkersAreDoneCompleter ??= Completer<void>();
  return __frontendDriver ??= BazelWorkerDriver(
      () => Process.start(
          p.join(sdkDir, 'bin', 'dart'),
          [
            p.join(sdkDir, 'bin', 'snapshots', 'kernel_worker.dart.snapshot'),
            '--persistent_worker'
          ],
          mode: _processMode,
          workingDirectory: scratchSpace.tempDir.path),
      maxWorkers: _maxWorkersPerTask);
}

BazelWorkerDriver __frontendDriver;

/// Resource for fetching the current [BazelWorkerDriver] for common frontend.
final frontendDriverResource =
    Resource<BazelWorkerDriver>(() => _frontendDriver, beforeExit: () async {
  await _frontendDriver?.terminateWorkers();
  _frontendWorkersAreDoneCompleter.complete();
  _frontendWorkersAreDoneCompleter = null;
  __frontendDriver = null;
});

const _dart2jsVmArgsEnvVar = 'BUILD_DART2JS_VM_ARGS';
final _dart2jsVmArgs = () {
  var env = Platform.environment[_dart2jsVmArgsEnvVar];
  return env?.split(' ') ?? <String>[];
}();

/// Manages a shared set of persistent dart2js workers.
Dart2JsBatchWorkerPool get _dart2jsWorkerPool {
  _dart2jsWorkersAreDoneCompleter ??= Completer<void>();
  var librariesSpec = p.joinAll([sdkDir, 'lib', 'libraries.json']);
  return __dart2jsWorkerPool ??= Dart2JsBatchWorkerPool(() => Process.start(
      p.join(sdkDir, 'bin', 'dart'),
      [
        ..._dart2jsVmArgs,
        p.join(sdkDir, 'bin', 'snapshots', 'dart2js.dart.snapshot'),
        '--libraries-spec=$librariesSpec',
        '--batch',
      ],
      mode: _processMode,
      workingDirectory: scratchSpace.tempDir.path));
}

Dart2JsBatchWorkerPool __dart2jsWorkerPool;

/// Resource for fetching the current [Dart2JsBatchWorkerPool] for dart2js.
final dart2JsWorkerResource = Resource<Dart2JsBatchWorkerPool>(
    () => _dart2jsWorkerPool, beforeExit: () async {
  await _dart2jsWorkerPool.terminateWorkers();
  _dart2jsWorkersAreDoneCompleter.complete();
  _dart2jsWorkersAreDoneCompleter = null;
});

/// Manages a pool of persistent [_Dart2JsWorker]s running in batch mode and
/// schedules jobs among them.
class Dart2JsBatchWorkerPool {
  final Future<Process> Function() _spawnWorker;

  final _workQueue = Queue<_Dart2JsJob>();

  bool _queueIsActive = false;

  final _availableWorkers = Queue<_Dart2JsWorker>();

  final _allWorkers = <_Dart2JsWorker>[];

  Dart2JsBatchWorkerPool(this._spawnWorker);

  Future<Dart2JsResult> compile(List<String> args) async {
    var job = _Dart2JsJob(args);
    _workQueue.add(job);
    if (!_queueIsActive) _startWorkQueue();
    return job.result;
  }

  void _startWorkQueue() {
    assert(!_queueIsActive);
    _queueIsActive = true;
    () async {
      while (_workQueue.isNotEmpty) {
        _Dart2JsWorker worker;
        if (_availableWorkers.isEmpty &&
            _allWorkers.length < _maxWorkersPerTask) {
          worker = _Dart2JsWorker(_spawnWorker);
          _allWorkers.add(worker);
        }

        _Dart2JsWorker nextWorker() => _availableWorkers.isNotEmpty
            ? _availableWorkers.removeFirst()
            : null;

        worker ??= nextWorker();
        while (worker == null) {
          // TODO: something smarter here? in practice this seems to work
          // reasonably well though and simplifies things a lot ¯\_(ツ)_/¯.
          await Future.delayed(Duration(seconds: 1));
          worker = nextWorker();
        }
        unawaited(worker
            .doJob(_workQueue.removeFirst())
            .whenComplete(() => _availableWorkers.add(worker)));
      }
      _queueIsActive = false;
    }();
  }

  Future<void> terminateWorkers() async {
    var allWorkers = _allWorkers.toList();
    _allWorkers.clear();
    _availableWorkers.clear();
    await Future.wait(allWorkers.map((w) => w.terminate()));
  }
}

/// A single dart2js worker process running in batch mode.
///
/// This may actually spawn multiple processes over time, if a running worker
/// dies or it decides that it should be restarted for some reason.
class _Dart2JsWorker {
  final Future<Process> Function() _spawnWorker;

  int _jobsSinceLastRestartCount = 0;
  static const int _jobsBeforeRestartMax = 5;
  static const int _retryCountMax = 2;

  Stream<String> __workerStderrLines;
  Stream<String> get _workerStderrLines {
    assert(__worker != null);
    return __workerStderrLines ??= __worker.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
  }

  Stream<String> __workerStdoutLines;
  Stream<String> get _workerStdoutLines {
    assert(__worker != null);
    return __workerStdoutLines ??= __worker.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
  }

  Process __worker;
  Future<Process> _spawningWorker;
  Future<Process> get _worker {
    if (__worker != null) return Future.value(__worker);
    return _spawningWorker ??= () async {
      if (__worker == null) {
        _jobsSinceLastRestartCount = 0;
        __worker ??= await _spawnWorker();
        _spawningWorker = null;
        unawaited(_workerStdoutLines.drain().whenComplete(() {
          __worker = null;
          __workerStdoutLines = null;
          __workerStderrLines = null;
          _currentJobResult
              ?.completeError('Dart2js exited with an unknown error');
        }));
      }
      return __worker;
    }();
  }

  Completer<Dart2JsResult> _currentJobResult;

  _Dart2JsWorker(this._spawnWorker);

  /// Performs [job], gracefully handling worker failures by retrying
  /// [_retryCountMax] times and restarting the worker between jobs based on
  /// [_jobsBeforeRestartMax] to limit memory consumption.
  ///
  /// Only one job may be performed at a time.
  Future<void> doJob(_Dart2JsJob job) async {
    assert(_currentJobResult == null);
    var tryCount = 0;
    var succeeded = false;
    while (tryCount < _retryCountMax && !succeeded) {
      tryCount++;
      _jobsSinceLastRestartCount++;
      var worker = await _worker;
      var output = StringBuffer();
      _currentJobResult = Completer<Dart2JsResult>();
      var sawError = false;
      var stderrListener = _workerStderrLines.listen((line) {
        if (line == '>>> EOF STDERR') {
          _currentJobResult?.complete(
              Dart2JsResult(!sawError, 'Dart2Js finished with:\n\n$output'));
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

      log.info('Running dart2js with ${job.args.join(' ')}\n');
      worker.stdin.writeln(job.args.join(' '));

      Dart2JsResult result;
      try {
        result = await _currentJobResult.future;
        job.resultCompleter.complete(result);
        succeeded = true;
      } catch (e) {
        log.warning('Dart2Js failure: $e');
        succeeded = false;
        if (tryCount >= _retryCountMax) {
          job.resultCompleter.complete(_currentJobResult.future);
        }
      } finally {
        _currentJobResult = null;
        // TODO: Remove this hack once dart-lang/sdk#33708 is resolved.
        if (_jobsSinceLastRestartCount >= _jobsBeforeRestartMax) {
          await terminate();
        }
        await stderrListener.cancel();
        await stdoutListener.cancel();
      }
    }
  }

  Future<void> terminate() async {
    var worker = __worker ?? await _spawningWorker;
    var oldStdout = __workerStdoutLines;
    __worker = null;
    __workerStdoutLines = null;
    __workerStderrLines = null;
    if (worker != null) {
      worker.kill();
      await worker.stdin.close();
    }
    await oldStdout?.drain();
  }
}

/// A single dart2js job, consisting of [args] and a [result].
class _Dart2JsJob {
  final List<String> args;

  final resultCompleter = Completer<Dart2JsResult>();
  Future<Dart2JsResult> get result => resultCompleter.future;

  _Dart2JsJob(this.args);
}

/// The result of a [_Dart2JsJob]
class Dart2JsResult {
  final bool succeeded;
  final String output;

  Dart2JsResult(this.succeeded, this.output);
}
