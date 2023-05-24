// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:io/ansi.dart' as ansi;
import 'package:io/io.dart' show ExitCode;

import '../build_script_generate/build_script_generate.dart';
import 'clean.dart';
import 'runner.dart';

/// A common entry point to parse command line arguments and build or serve with
/// [builders].
///
/// Returns the exit code that should be set when the calling process exits. `0`
/// implies success.
Future<int> run(List<String> args, List<BuilderApplication> builders) async {
  var runner = BuildCommandRunner(builders, await PackageGraph.forThisPackage())
    ..addCommand(CleanCommand());
  try {
    var result = await runner.run(args);
    return result ?? 0;
  } on UsageException catch (e) {
    print(ansi.red.wrap(e.message));
    print('');
    print(e.usage);
    return ExitCode.usage.code;
  } on ArgumentError // ignore: avoid_catching_errors
  catch (e) {
    print(ansi.red.wrap(e.toString()));
    return ExitCode.usage.code;
  } on CannotBuildException {
    // A message should have already been logged.
    return ExitCode.config.code;
  } on BuildScriptChangedException {
    _deleteAssetGraph();
    if (_runningFromKernel) _invalidateSelf();
    return ExitCode.tempFail.code;
  } on BuildConfigChangedException {
    return ExitCode.tempFail.code;
  }
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
void _invalidateSelf() {
  var kernelPath = Platform.script.toFilePath();
  var kernelFile = File(kernelPath);
  if (kernelFile.existsSync()) {
    kernelFile.renameSync('$kernelPath$scriptKernelCachedSuffix');
  }
}

bool get _runningFromKernel =>
    !Platform.script.path.endsWith(scriptKernelSuffix);
