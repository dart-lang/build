// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

import '../asset/reader.dart';
import '../asset/writer.dart';
import '../generate/directory_watcher_factory.dart';

/// Utilities to interact with the environment in which a build is running.
///
/// All side effects and user interaction should go through the build
/// environment. An IO based environment can write to disk and interact through
/// stdout/stdin, while a theoretical web or remote environment might interact
/// over HTTP.
abstract class BuildEnvironment {
  RunnerAssetReader get reader;
  RunnerAssetWriter get writer;
  DirectoryWatcherFactory get directoryWatcherFactory;

  void onLog(LogRecord record);

  /// Prompt the user for input.
  ///
  /// The message and choices are displayed to the user and the index of the
  /// chosen option is returned.
  ///
  /// If this environmment is non-interactive (such as when running in a test)
  /// this method should throw [NonInteractiveBuildException].
  Future<int> prompt(String message, List<String> choices);
}

/// Thrown when the build attempts to prompt the users but no prompt is
/// possible.
class NonInteractiveBuildException implements Exception {}
