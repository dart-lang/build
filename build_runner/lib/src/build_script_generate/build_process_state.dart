// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

/// State for the whole build process.
///
/// It's passed from the entrypoint to the spawned build script isolate, then
/// updated in the host when the isolate exits.
final BuildProcessState buildProcessState = BuildProcessState({});

extension type BuildProcessState(Map<String, Object?> state) {
  /// The exit code of the most recent build script isolate, or `null` if there
  /// was none or it is currently running.
  int? get isolateExitCode => state['isolateExitCode'] as int?;
  set isolateExitCode(int? value) => state['isolateExitCode'] = value;

  /// Sends `this` to [sendPort].
  Future<void> send(SendPort? sendPort) async {
    sendPort?.send(state);
  }

  /// Receives `this` from [sendPort], by sending a `SendPort` then listening
  /// on its corresponding `ReceivePort`.
  Future<void> receive(SendPort? sendPort) async {
    if (sendPort == null) {
      state.clear();
      return;
    }
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    final received = await receivePort.first;
    state
      ..clear()
      ..addAll(received as Map<String, Object?>);
  }

  /// Receives `this` from [receivePort].
  StreamSubscription<void> listen(ReceivePort receivePort) {
    StreamSubscription<void>? result;
    result = receivePort.listen((isolateState) {
      if (isolateState is Map<String, Object?>) {
        state
          ..clear()
          ..addAll(isolateState);
      } else {
        throw StateError(
          'Bad response from isolate, expected Map but got $isolateState',
        );
      }
      result!.cancel();
    });
    return result;
  }
}
