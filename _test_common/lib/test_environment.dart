// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:build_runner_core/src/asset/reader.dart';
import 'package:build_runner_core/src/asset/writer.dart';
import 'package:build_runner_core/src/environment/build_environment.dart';

import 'common.dart';

/// A [BuildEnvironment] for testing.
///
/// Defaults to using an [InMemoryRunnerAssetReader] and
/// [InMemoryRunnerAssetWriter].
///
/// To handle prompts you must first set `nextPromptResponse`. Alternatively
/// you can set `throwOnPrompt` to `true` to emulate a
/// [NonInteractiveBuildException].
class TestBuildEnvironment extends BuildEnvironment {
  @override
  final RunnerAssetReader reader;
  @override
  final RunnerAssetWriter writer;

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

  int _nextPromptResponse;

  TestBuildEnvironment(
      {RunnerAssetReader reader,
      RunnerAssetWriter writer,
      this.throwOnPrompt = false})
      : reader = reader ?? InMemoryRunnerAssetReader(),
        writer = writer ?? InMemoryRunnerAssetWriter();

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
