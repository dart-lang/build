// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import '../constants.dart';
import '../worker_protocol.pb.dart';
import 'driver_connection.dart';

typedef SpawnWorker = Future<Process> Function();

/// A driver for talking to a bazel worker.
///
/// This allows you to use any binary that supports the bazel worker protocol in
/// the same way that bazel would, but from another dart process instead.
class BazelWorkerDriver {
  /// Idle worker processes.
  final _idleWorkers = <Process>[];

  /// The maximum number of idle workers at any given time.
  final int _maxIdleWorkers;

  /// The maximum number of times to retry a [WorkAttempt] if there is an error.
  final int _maxRetries;

  /// The maximum number of concurrent workers to run at any given time.
  final int _maxWorkers;

  /// The number of currently active workers.
  int get _numWorkers => _readyWorkers.length + _spawningWorkers.length;

  /// All workers that are fully spawned and ready to handle work.
  final _readyWorkers = <Process>[];

  /// All workers that are in the process of being spawned.
  final _spawningWorkers = <Future<Process>>[];

  /// Work requests that haven't been started yet.
  final _workQueue = Queue<_WorkAttempt>();

  /// Factory method that spawns a worker process.
  final SpawnWorker _spawnWorker;

  BazelWorkerDriver(this._spawnWorker,
      {int? maxIdleWorkers, int? maxWorkers, int? maxRetries})
      : _maxIdleWorkers = maxIdleWorkers ?? 4,
        _maxWorkers = maxWorkers ?? 4,
        _maxRetries = maxRetries ?? 4;

  /// Waits for an available worker, and then sends [WorkRequest] to it.
  ///
  /// If [trackWork] is provided it will be invoked with a [Future] once the
  /// [request] has been actually sent to the worker. This allows the caller
  /// to determine when actual work is being done versus just waiting for an
  /// available worker.
  Future<WorkResponse> doWork(WorkRequest request,
      {Function(Future<WorkResponse?>)? trackWork}) {
    var attempt = _WorkAttempt(request, trackWork: trackWork);
    _workQueue.add(attempt);
    _runWorkQueue();
    return attempt.response;
  }

  /// Calls `kill` on all worker processes.
  Future terminateWorkers() async {
    for (var worker in _readyWorkers.toList()) {
      _killWorker(worker);
    }
    await Future.wait(_spawningWorkers.map((worker) async {
      _killWorker(await worker);
    }));
  }

  /// Runs as many items in [_workQueue] as possible given the number of
  /// available workers.
  ///
  /// Will spawn additional workers until [_maxWorkers] has been reached.
  ///
  /// This method synchronously drains the [_workQueue] and [_idleWorkers], but
  /// some tasks may not actually start right away if they need to wait for a
  /// worker to spin up.
  void _runWorkQueue() {
    // Bail out conditions, we will continue to call ourselves indefinitely
    // until one of these is met.
    if (_workQueue.isEmpty) return;
    if (_numWorkers == _maxWorkers && _idleWorkers.isEmpty) return;
    if (_numWorkers > _maxWorkers) {
      throw StateError('Internal error, created to many workers. Please '
          'file a bug at https://github.com/dart-lang/bazel_worker/issues/new');
    }

    // At this point we definitely want to run a task, we just need to decide
    // whether or not we need to start up a new worker.
    var attempt = _workQueue.removeFirst();
    if (_idleWorkers.isNotEmpty) {
      _runWorker(_idleWorkers.removeLast(), attempt);
    } else {
      // No need to block here, we want to continue to synchronously drain the
      // work queue.
      var futureWorker = _spawnWorker();
      _spawningWorkers.add(futureWorker);
      futureWorker.then((worker) {
        _spawningWorkers.remove(futureWorker);
        _readyWorkers.add(worker);
        var connection = StdDriverConnection.forWorker(worker);
        _workerConnections[worker] = connection;
        _runWorker(worker, attempt);

        // When the worker exits we should retry running the work queue in case
        // there is more work to be done. This is primarily just a defensive
        // thing but is cheap to do.
        //
        // We don't use `exitCode` because it is null for detached processes (
        // which is common for workers).
        connection.done.then((_) {
          _idleWorkers.remove(worker);
          _readyWorkers.remove(worker);
          _runWorkQueue();
        });
      });
    }
    // Recursively calls itself until one of the bail out conditions are met.
    _runWorkQueue();
  }

  /// Sends [request] to [worker].
  ///
  /// Once the worker responds then it will be added back to the pool of idle
  /// workers.
  void _runWorker(Process worker, _WorkAttempt attempt) {
    var rescheduled = false;

    runZonedGuarded(() async {
      var connection = _workerConnections[worker]!;

      connection.writeRequest(attempt.request);
      var responseFuture = connection.readResponse();
      if (attempt.trackWork != null) {
        attempt.trackWork!(responseFuture);
      }
      var response = await responseFuture;

      // It is possible for us to complete with an error response due to an
      // unhandled async error before we get here.
      if (!attempt.responseCompleter.isCompleted) {
        if (response.exitCode == EXIT_CODE_BROKEN_PIPE) {
          rescheduled = _tryReschedule(attempt);
          if (rescheduled) return;
          stderr.writeln('Failed to run request ${attempt.request}');
          response = WorkResponse()
            ..exitCode = EXIT_CODE_ERROR
            ..output =
                'Invalid response from worker, this probably means it wrote '
                    'invalid output or died.';
        }
        attempt.responseCompleter.complete(response);
        _cleanUp(worker);
      }
    }, (e, s) {
      // Note that we don't need to do additional cleanup here on failures. If
      // the worker dies that is already handled in a generic fashion, we just
      // need to make sure we complete with a valid response.
      if (!attempt.responseCompleter.isCompleted) {
        rescheduled = _tryReschedule(attempt);
        if (rescheduled) return;
        var response = WorkResponse()
          ..exitCode = EXIT_CODE_ERROR
          ..output = 'Error running worker:\n$e\n$s';
        attempt.responseCompleter.complete(response);
        _cleanUp(worker);
      }
    });
  }

  /// Performs post-work cleanup for [worker].
  void _cleanUp(Process worker) {
    // If the worker crashes, it won't be in `_readyWorkers` any more, and
    // we don't want to add it to _idleWorkers.
    if (_readyWorkers.contains(worker)) {
      _idleWorkers.add(worker);
    }

    // Do additional work if available.
    _runWorkQueue();

    // If the worker wasn't immediately used we might have to many idle
    // workers now, kill one if necessary.
    if (_idleWorkers.length > _maxIdleWorkers) {
      // Note that whenever we spawn a worker we listen for its exit code
      // and clean it up so we don't need to do that here.
      var worker = _idleWorkers.removeLast();
      _killWorker(worker);
    }
  }

  /// Attempts to reschedule a failed [attempt].
  ///
  /// Returns whether or not the job was successfully rescheduled.
  bool _tryReschedule(_WorkAttempt attempt) {
    if (attempt.timesRetried >= _maxRetries) return false;
    stderr.writeln('Rescheduling failed request...');
    attempt.timesRetried++;
    _workQueue.add(attempt);
    _runWorkQueue();
    return true;
  }

  void _killWorker(Process worker) {
    _workerConnections[worker]!.cancel();
    _readyWorkers.remove(worker);
    _idleWorkers.remove(worker);
    worker.kill();
  }
}

/// Encapsulates an attempt to fulfill a [WorkRequest], a completer for the
/// [WorkResponse], and the number of times it has been retried.
class _WorkAttempt {
  final WorkRequest request;
  final responseCompleter = Completer<WorkResponse>();
  final Function(Future<WorkResponse?>)? trackWork;

  Future<WorkResponse> get response => responseCompleter.future;

  int timesRetried = 0;

  _WorkAttempt(this.request, {this.trackWork});
}

final _workerConnections = Expando<DriverConnection>('connection');
