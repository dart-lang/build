// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

  /// For `buildLog`, console output capabilities.
  ///
  /// If not already set, sets from the current process stdio on get.
  StdioCapabilities get stdio {
    _state['stdioCapabilities'] ??= StdioCapabilities().serialize();
    return StdioCapabilities.deserialize(
      _state['stdioCapabilities'] as Map<String, Object?>,
    );
  }

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

  /// For `buildLog`, the elapsed time since the process started.
  int get elapsedMillis => _state['elapsedMillis'] as int? ?? 0;
  set elapsedMillis(int elapsedMillis) =>
      _state['elapsedMillis'] = elapsedMillis;

  /// The package config URI.
  String get packageConfigUri =>
      (_state['packageConfigUri'] ??= Isolate.packageConfigSync!.toString())
          as String;

  void resetForTests() {
    _state.clear();
  }

  /// Registers [function] to be called before sending the state.
  void doBeforeSend(void Function() function) {
    _beforeSends.add(function);
  }

  String serialize() {
    // Set any unset values that should be set by the parent process.
    stdio;
    packageConfigUri;

    for (final beforeSend in _beforeSends) {
      beforeSend();
    }
    return json.encode(_state);
  }

  void doAfterReceive(void Function() function) {
    _afterReceives.add(function);
  }

  void deserializeAndSet(String serialized) async {
    var data = <String, Object?>{};
    try {
      data = json.decode(serialized) as Map<String, Object?>;
    } catch (_) {}
    _state
      ..clear()
      ..addAll(data);
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

/// The stdio capabilities of the parent process.
///
/// The child can't interact directly with parent stdio but should render
/// output for it.
class StdioCapabilities {
  final bool hasTerminal;
  final bool supportsAnsiEscapes;
  final int terminalLines;
  final int terminalColumns;

  StdioCapabilities()
    : hasTerminal = stdout.hasTerminal,
      supportsAnsiEscapes = stdout.supportsAnsiEscapes,
      terminalLines = stdout.hasTerminal ? stdout.terminalLines : 0,
      terminalColumns = stdout.hasTerminal ? stdout.terminalColumns : 80;

  StdioCapabilities.deserialize(Map<String, Object?> serialized)
    : hasTerminal = serialized['hasTerminal'] as bool,
      supportsAnsiEscapes = serialized['supportsAnsiEscapes'] as bool,
      terminalLines = serialized['terminalLines'] as int,
      terminalColumns = serialized['terminalColumns'] as int;

  Map<String, Object?> serialize() => {
    'hasTerminal': hasTerminal,
    'supportsAnsiEscapes': supportsAnsiEscapes,
    'terminalLines': terminalLines,
    'terminalColumns': terminalColumns,
  };
}
