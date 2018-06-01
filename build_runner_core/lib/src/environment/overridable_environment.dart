// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

import '../asset/reader.dart';
import '../asset/writer.dart';
import 'build_environment.dart';

/// A [BuildEnvironment] which can have individual features overridden.
class OverrideableEnvironment implements BuildEnvironment {
  final BuildEnvironment _default;

  final RunnerAssetReader _reader;
  final RunnerAssetWriter _writer;

  final void Function(LogRecord) _onLog;

  OverrideableEnvironment(
    this._default, {
    RunnerAssetReader reader,
    RunnerAssetWriter writer,
    void Function(LogRecord) onLog,
  })  : _reader = reader,
        _writer = writer,
        _onLog = onLog;

  @override
  RunnerAssetReader get reader => _reader ?? _default.reader;

  @override
  RunnerAssetWriter get writer => _writer ?? _default.writer;

  @override
  void onLog(LogRecord record) {
    if (_onLog != null) {
      _onLog(record);
    } else {
      _default.onLog(record);
    }
  }

  @override
  Future<int> prompt(String message, List<String> choices) =>
      _default.prompt(message, choices);
}
