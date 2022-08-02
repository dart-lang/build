// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:bazel_worker/bazel_worker.dart';

export 'src/async_message_grouper.dart';
export 'src/sync_message_grouper.dart';
export 'src/utils.dart' show protoToDelimitedBuffer;

/// Interface for a mock [Stdin] object that allows you to add bytes manually.
abstract class TestStdin implements Stdin {
  void addInputBytes(List<int> bytes);

  void close();
}

/// A [Stdin] mock object which only implements `readByteSync`.
class TestStdinSync implements TestStdin {
  /// Pending bytes to be delivered synchronously.
  final Queue<int> pendingBytes = Queue<int>();

  /// Adds all the [bytes] to this stream.
  @override
  void addInputBytes(List<int> bytes) {
    pendingBytes.addAll(bytes);
  }

  /// Add a -1 to signal EOF.
  @override
  void close() {
    pendingBytes.add(-1);
  }

  @override
  int readByteSync() {
    return pendingBytes.removeFirst();
  }

  @override
  bool get isBroadcast => false;

  @override
  void noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected invocation ${invocation.memberName}.');
  }
}

/// A mock [Stdin] object which only implements `listen`.
///
/// Note: You must call [close] in order for the loop to exit properly.
class TestStdinAsync implements TestStdin {
  /// Controls the stream for async delivery of bytes.
  final StreamController<Uint8List> _controller = StreamController();
  StreamController<Uint8List> get controller => _controller;

  /// Adds all the [bytes] to this stream.
  @override
  void addInputBytes(List<int> bytes) {
    _controller.add(Uint8List.fromList(bytes));
  }

  /// Closes this stream. This is necessary for the [AsyncWorkerLoop] to exit.
  @override
  void close() {
    _controller.close();
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List bytes)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  bool get isBroadcast => false;

  @override
  void noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected invocation ${invocation.memberName}.');
  }
}

/// A [Stdout] mock object.
class TestStdoutStream implements Stdout {
  final List<List<int>> writes = <List<int>>[];

  @override
  void add(List<int> bytes) {
    writes.add(bytes);
  }

  @override
  void noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected invocation ${invocation.memberName}.');
  }
}

/// Interface for a [TestWorkerConnection] which records its responses
abstract class TestWorkerConnection implements WorkerConnection {
  List<WorkResponse> get responses;
}

/// Interface for a [TestWorkerLoop] which allows you to enqueue responses.
abstract class TestWorkerLoop implements WorkerLoop {
  void enqueueResponse(WorkResponse response);

  /// If set, this message will be printed during the call to `performRequest`.
  String? get printMessage;
}

/// A [StdSyncWorkerConnection] which records its responses.
class TestSyncWorkerConnection extends StdSyncWorkerConnection
    implements TestWorkerConnection {
  @override
  final List<WorkResponse> responses = <WorkResponse>[];

  TestSyncWorkerConnection(Stdin stdinStream, Stdout stdoutStream)
      : super(stdinStream: stdinStream, stdoutStream: stdoutStream);

  @override
  void writeResponse(WorkResponse response) {
    super.writeResponse(response);
    responses.add(response);
  }
}

/// A [SyncWorkerLoop] for testing.
class TestSyncWorkerLoop extends SyncWorkerLoop implements TestWorkerLoop {
  final List<WorkRequest> requests = <WorkRequest>[];
  final Queue<WorkResponse> _responses = Queue<WorkResponse>();

  @override
  final String? printMessage;

  TestSyncWorkerLoop(SyncWorkerConnection connection, {this.printMessage})
      : super(connection: connection);

  @override
  WorkResponse performRequest(WorkRequest request) {
    requests.add(request);
    if (printMessage != null) print(printMessage);
    return _responses.removeFirst();
  }

  /// Adds [response] to the queue. These will be returned from
  /// [performResponse] in the order they are added, otherwise it will throw
  /// if the queue is empty.
  @override
  void enqueueResponse(WorkResponse response) {
    _responses.addLast(response);
  }
}

/// A [StdAsyncWorkerConnection] which records its responses.
class TestAsyncWorkerConnection extends StdAsyncWorkerConnection
    implements TestWorkerConnection {
  @override
  final List<WorkResponse> responses = <WorkResponse>[];

  TestAsyncWorkerConnection(
      Stream<List<int>> inputStream, StreamSink<List<int>> outputStream)
      : super(inputStream: inputStream, outputStream: outputStream);

  @override
  void writeResponse(WorkResponse response) {
    super.writeResponse(response);
    responses.add(response);
  }
}

/// A [AsyncWorkerLoop] for testing.
class TestAsyncWorkerLoop extends AsyncWorkerLoop implements TestWorkerLoop {
  final List<WorkRequest> requests = <WorkRequest>[];
  final Queue<WorkResponse> _responses = Queue<WorkResponse>();

  @override
  final String? printMessage;

  TestAsyncWorkerLoop(AsyncWorkerConnection connection, {this.printMessage})
      : super(connection: connection);

  @override
  Future<WorkResponse> performRequest(WorkRequest request) async {
    requests.add(request);
    if (printMessage != null) print(printMessage);
    return _responses.removeFirst();
  }

  /// Adds [response] to the queue. These will be returned from
  /// [performResponse] in the order they are added, otherwise it will throw
  /// if the queue is empty.
  @override
  void enqueueResponse(WorkResponse response) {
    _responses.addLast(response);
  }
}
