// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../worker_protocol.pb.dart';

/// Interface for a [WorkerLoop].
///
/// This interface should not generally be implemented directly, instead use
/// the [SyncWorkerLoop] or [AsyncWorkerLoop] implementations.
abstract class WorkerLoop {
  /// Perform a single [WorkRequest], and return either a [WorkResponse] or
  /// a [Future<WorkResponse>].
  dynamic performRequest(WorkRequest request);

  /// Run the worker loop. Should return either a [Future] or [null].
  dynamic run();
}
