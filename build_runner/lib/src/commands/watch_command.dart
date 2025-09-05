// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/experiments.dart';
import 'package:built_collection/built_collection.dart';
import 'package:io/io.dart';

import '../build_plan.dart';
import '../build_script_generate/build_process_state.dart';
import '../generate/build_result.dart';
import '../generate/exceptions.dart';
import '../generate/terminator.dart';
import '../generate/watch_impl.dart';
import '../logging/build_log.dart';
import '../options/testing_overrides.dart';
import '../package_graph/apply_builders.dart';
import '../server/server.dart';
import 'build_options.dart';
import 'build_runner_command.dart';

class WatchCommand implements BuildRunnerCommand {
  final BuiltList<BuilderApplication> builders;
  final BuildOptions buildOptions;
  final TestingOverrides testingOverrides;

  WatchCommand({
    required this.builders,
    required this.buildOptions,
    this.testingOverrides = const TestingOverrides(),
  });

  @override
  Future<int> run() =>
      withEnabledExperiments(_run, buildOptions.enableExperiments.asList());

  Future<int> _run() async {
    final handler = await watch();
    final completer = Completer<int>();
    handleBuildResultsStream(handler.buildResults, completer);
    return completer.future;
  }

  Future<ServeHandler> watch() async {
    buildLog.configuration = buildLog.configuration.rebuild((b) {
      b.mode = BuildLogMode.build;
      b.verbose = buildOptions.verbose;
      b.onLog = testingOverrides.onLog;
    });
    final buildPlan = await BuildPlan.load(
      builders: builders,
      buildOptions: buildOptions,
      testingOverrides: testingOverrides,
    );
    final terminator = Terminator(testingOverrides.terminateEventStream);

    final watcher = Watcher(
      buildPlan: buildPlan,
      until: terminator.shouldTerminate,
      willCreateOutputDirs: buildOptions.buildDirs.any(
        (target) => target.outputLocation?.path.isNotEmpty ?? false,
      ),
    );

    unawaited(
      watcher.buildResults.drain<void>().then((_) async {
        await terminator.cancel();
      }),
    );

    return createServeHandler(watcher);
  }
}

/// Listens to [buildResults], handling certain types of errors and completing
/// [completer] appropriately.
void handleBuildResultsStream(
  Stream<BuildResult> buildResults,
  Completer<int> completer,
) async {
  final subscription = buildResults.listen((result) {
    if (completer.isCompleted) return;
    if (result.status == BuildStatus.failure) {
      if (result.failureType == FailureType.buildScriptChanged) {
        completer.completeError(const BuildScriptChangedException());
      } else if (result.failureType == FailureType.buildConfigChanged) {
        completer.completeError(const BuildConfigChangedException());
      }
    }
  });
  await subscription.asFuture<void>();
  if (!completer.isCompleted) completer.complete(ExitCode.success.code);
}
