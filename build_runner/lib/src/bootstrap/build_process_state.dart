// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

/// State for the whole build process.
///
/// It's passed from the entrypoint to the spawned build script isolate, then
/// updated in the host when the isolate exits.
final BuildProcessState buildProcessState = BuildProcessState();

class BuildProcessState {
  final Map<String, Object?> _state = {};
  final List<void Function()> _beforeSends = [];
  final List<void Function()> _afterReceives = [];

  /// The exit code of the most recent build script isolate, or `null` if there
  /// was none or it is currently running.
  int? get isolateExitCode => _state['isolateExitCode'] as int?;
  set isolateExitCode(int? value) => _state['isolateExitCode'] = value;

  /// For `buildLog`, the log mode.
  BuildLogMode get buildLogMode => BuildLogMode.values.singleWhere(
    (mode) => mode.name == _state['buildLogMode'],
    orElse: () => BuildLogMode.simple,
  );
  set buildLogMode(BuildLogMode mode) => _state['buildLogMode'] = mode.name;

  /// For `buildLog` console display, the number of displayed lines that should
  /// be overwritten by the next display.
  int get displayedLines => (_state['displayedLines'] as int?) ?? 0;
  set displayedLines(int? value) => _state['displayedLines'] = value;

  /// For `buildLog`, the reason why a full build was needed.
  FullBuildReason get fullBuildReason => FullBuildReason.values.singleWhere(
    (v) => v.name == _state['fullBuildReason'],
    orElse: () => FullBuildReason.clean,
  );
  set fullBuildReason(FullBuildReason buildType) =>
      _state['fullBuildReason'] = buildType.name;

  /// For `buildLog`, the elapsed time since the process started.
  int get elapsedMillis => _state['elapsedMillis'] as int? ?? 0;
  set elapsedMillis(int elapsedMillis) =>
      _state['elapsedMillis'] = elapsedMillis;

  void resetForTests() {
    _state.clear();
  }

  /// Registers [function] to be called before sending the state.
  void doBeforeSend(void Function() function) {
    _beforeSends.add(function);
  }

  /// Sends `this` to [sendPort].
  Future<void> send(SendPort? sendPort) async {
    for (final beforeSend in _beforeSends) {
      beforeSend();
    }
    sendPort?.send(_state);
  }

  void doAfterReceive(void Function() function) {
    _afterReceives.add(function);
  }

  /// Receives `this` from [sendPort], by sending a `SendPort` then listening
  /// on its corresponding `ReceivePort`.
  Future<void> receive(SendPort? sendPort) async {
    if (sendPort == null) {
      _state.clear();
      return;
    }
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    final received = await receivePort.first;
    _state
      ..clear()
      ..addAll(received as Map<String, Object?>);
    for (final afterReceive in _afterReceives) {
      afterReceive();
    }
  }

  /// Receives `this` from [receivePort].
  StreamSubscription<void> listen(ReceivePort receivePort) {
    StreamSubscription<void>? result;
    result = receivePort.listen((isolateState) {
      if (isolateState is Map<String, Object?>) {
        _state
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

/// Reason why `build_runner` will do a full build; or `none` for an
/// incremental build.
enum FullBuildReason {
  clean('full build'),
  incompatibleScript('full build because builders changed'),
  incompatibleAssetGraph('full build because there is no valid asset graph'),
  incompatibleBuild('full build because target changed'),
  none('incremental build');

  const FullBuildReason(this.message);

  final String message;
}

/// The `BuildLog` mode for the process.
enum BuildLogMode {
  /// Line by line logging.
  simple,

  /// For `build_daemon`, as `simple` but log errors to stderr.
  daemon,

  /// Advanced log mode for builds.
  ///
  /// If a console is available, progress is shown and updated in place instead
  /// of line by line logging.
  build,
}
