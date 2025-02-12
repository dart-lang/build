// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_runner_core/build_runner_core.dart';
import 'package:logging/logging.dart';

import 'common.dart';
import 'in_memory_reader_writer.dart';

/// A [BuildEnvironment] for testing.
///
/// Defaults to an empty [InMemoryRunnerAssetReaderWriter].
///
/// To handle prompts you must first set `nextPromptResponse`. Alternatively
/// you can set `throwOnPrompt` to `true` to emulate a
/// [NonInteractiveBuildException].
class TestBuildEnvironment extends BuildEnvironment {
  final InMemoryRunnerAssetReaderWriter _readerWriter;

  @override
  RunnerAssetReader get reader => _readerWriter;
  @override
  RunnerAssetWriter get writer => _readerWriter;

  /// If true, this will throw a [NonInteractiveBuildException] for all calls to
  /// [prompt].
  final bool throwOnPrompt;

  final logRecords = <LogRecord>[];

  /// The next response for calls to [prompt]. Must be set before calling
  /// [prompt].
  set nextPromptResponse(int next) {
    assert(_nextPromptResponse == null);
    _nextPromptResponse = next;
  }

  int? _nextPromptResponse;

  TestBuildEnvironment(
      {InMemoryRunnerAssetReaderWriter? readerWriter,
      this.throwOnPrompt = false})
      : _readerWriter = readerWriter ?? InMemoryRunnerAssetReaderWriter();

  @override
  void onLog(LogRecord record) => logRecords.add(record);

  /// Prompt the user for input.
  ///
  /// The message and choices are displayed to the user and the index of the
  /// chosen option is returned.
  ///
  /// If this environmment is non-interactive (such as when running in a test)
  /// this method should throw [NonInteractiveBuildException].
  @override
  Future<int> prompt(String message, List<String> choices) {
    if (throwOnPrompt) throw NonInteractiveBuildException();

    assert(_nextPromptResponse != null);
    return Future.value(_nextPromptResponse);
  }
}
