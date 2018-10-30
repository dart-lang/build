// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:io/ansi.dart' as ansi;
import 'package:io/io.dart' show ExitCode;
import 'package:pedantic/pedantic.dart';

import 'runner.dart';

/// A common entry point to parse command line arguments and build or serve with
/// [builders].
///
/// Returns the exit code that should be set when the calling process exits. `0`
/// implies success.
Future<int> run(List<String> args, List<BuilderApplication> builders) async {
  var runner = BuildCommandRunner(builders);
  var resultCompleter = Completer<int>();

  void safeComplete(int exitCode) {
    if (resultCompleter.isCompleted) return;
    resultCompleter.complete(exitCode);
  }

  unawaited(runZoned(() async {
    try {
      var result = await runner.run(args);
      safeComplete(result ?? 0);
    } on UsageException catch (e) {
      print(ansi.red.wrap(e.message));
      print('');
      print(e.usage);
      safeComplete(ExitCode.usage.code);
    } on ArgumentError catch (e) {
      print(ansi.red.wrap(e.toString()));
      safeComplete(ExitCode.usage.code);
    } on CannotBuildException {
      // A message should have already been logged.
      safeComplete(ExitCode.config.code);
    }
  }, onError: (Object e, StackTrace s) {
    if (e is BuildScriptChangedException) {
      _deleteAssetGraph();
      _deleteSelf();
      safeComplete(ExitCode.tempFail.code);
    } else if (e is BuildConfigChangedException) {
      safeComplete(ExitCode.tempFail.code);
    } else if (!resultCompleter.isCompleted) {
      resultCompleter.completeError(e, s);
    }
  }));

  return resultCompleter.future;
}

/// Deletes the asset graph for the current build script from disk.
void _deleteAssetGraph() {
  var graph = File(assetGraphPath);
  if (graph.existsSync()) {
    graph.deleteSync();
  }
}

/// Deletes the current running script.
///
/// This should only happen if the current script is a snapshot, and it has
/// been invalidated.
void _deleteSelf() {
  var self = File(Platform.script.toFilePath());
  if (self.existsSync()) {
    self.deleteSync();
  }
}
