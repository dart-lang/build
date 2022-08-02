// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../async_message_grouper.dart';
import '../sync_message_grouper.dart';
import '../utils.dart';
import '../worker_protocol.pb.dart';

/// A connection from a worker to a driver (driver could be bazel, a dart
/// program using `BazelWorkerDriver`, or any other process that speaks the
/// protocol).
abstract class WorkerConnection {
  /// Reads a [WorkRequest] or returns [null] if there are none left.
  ///
  /// See [AsyncWorkerConnection] and [SyncWorkerConnection] for more narrow
  /// interfaces.
  FutureOr<WorkRequest?> readRequest();

  void writeResponse(WorkResponse response);
}

abstract class AsyncWorkerConnection implements WorkerConnection {
  /// Creates a [StdAsyncWorkerConnection] with the specified [inputStream]
  /// and [outputStream], unless [sendPort] is specified, in which case
  /// creates a [SendPortAsyncWorkerConnection].
  factory AsyncWorkerConnection(
          {Stream<List<int>>? inputStream,
          StreamSink<List<int>>? outputStream,
          SendPort? sendPort}) =>
      sendPort == null
          ? StdAsyncWorkerConnection(
              inputStream: inputStream, outputStream: outputStream)
          : SendPortAsyncWorkerConnection(sendPort);

  @override
  Future<WorkRequest?> readRequest();
}

abstract class SyncWorkerConnection implements WorkerConnection {
  @override
  WorkRequest? readRequest();
}

/// Default implementation of [AsyncWorkerConnection] that works with [Stdin]
/// and [Stdout].
class StdAsyncWorkerConnection implements AsyncWorkerConnection {
  final AsyncMessageGrouper _messageGrouper;
  final StreamSink<List<int>> _outputStream;

  StdAsyncWorkerConnection(
      {Stream<List<int>>? inputStream, StreamSink<List<int>>? outputStream})
      : _messageGrouper = AsyncMessageGrouper(inputStream ?? stdin),
        _outputStream = outputStream ?? stdout;

  @override
  Future<WorkRequest?> readRequest() async {
    var buffer = await _messageGrouper.next;
    if (buffer == null) return null;

    return WorkRequest.fromBuffer(buffer);
  }

  @override
  void writeResponse(WorkResponse response) {
    _outputStream.add(protoToDelimitedBuffer(response));
  }
}

/// Implementation of [AsyncWorkerConnection] for running in an isolate.
class SendPortAsyncWorkerConnection implements AsyncWorkerConnection {
  final ReceivePort receivePort;
  final StreamIterator<Uint8List> receivePortIterator;
  final SendPort sendPort;

  factory SendPortAsyncWorkerConnection(SendPort sendPort) {
    var receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    return SendPortAsyncWorkerConnection._(receivePort, sendPort);
  }

  SendPortAsyncWorkerConnection._(this.receivePort, this.sendPort)
      : receivePortIterator = StreamIterator(receivePort.cast());

  @override
  Future<WorkRequest?> readRequest() async {
    if (!await receivePortIterator.moveNext()) return null;
    return WorkRequest.fromBuffer(receivePortIterator.current);
  }

  @override
  void writeResponse(WorkResponse response) {
    sendPort.send(response.writeToBuffer());
  }
}

/// Default implementation of [SyncWorkerConnection] that works with [Stdin] and
/// [Stdout].
class StdSyncWorkerConnection implements SyncWorkerConnection {
  final SyncMessageGrouper _messageGrouper;
  final Stdout _stdoutStream;

  StdSyncWorkerConnection({Stdin? stdinStream, Stdout? stdoutStream})
      : _messageGrouper = SyncMessageGrouper(stdinStream ?? stdin),
        _stdoutStream = stdoutStream ?? stdout;

  @override
  WorkRequest? readRequest() {
    var buffer = _messageGrouper.next;
    if (buffer == null) return null;

    return WorkRequest.fromBuffer(buffer);
  }

  @override
  void writeResponse(WorkResponse response) {
    _stdoutStream.add(protoToDelimitedBuffer(response));
  }
}
