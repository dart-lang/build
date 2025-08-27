// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/experiments.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:built_collection/built_collection.dart';
import 'package:io/io.dart';

import '../build_script_generate/build_process_state.dart';
import '../generate/terminator.dart';
import '../generate/watch_impl.dart';
import '../package_graph/build_config_overrides.dart';
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
    final packageGraph =
        testingOverrides.packageGraph ?? await PackageGraph.forThisPackage();
    final environment = BuildEnvironment(
      packageGraph,
      outputSymlinksOnly: buildOptions.outputSymlinksOnly,
      reader: testingOverrides.reader,
      writer: testingOverrides.writer,
    );
    buildLog.configuration = buildLog.configuration.rebuild((b) {
      b.mode = BuildLogMode.build;
      b.verbose = buildOptions.verbose;
      b.onLog = testingOverrides.onLog;
    });
    final options = await BuildConfiguration.create(
      packageGraph: packageGraph,
      reader: environment.reader,
      overrideBuildConfig:
          testingOverrides.buildConfig ??
          await findBuildConfigOverrides(
            packageGraph,
            environment.reader,
            configKey: buildOptions.configKey,
          ),
      debounceDelay: testingOverrides.debounceDelay,
      skipBuildScriptCheck: buildOptions.skipBuildScriptCheck,
      enableLowResourcesMode: buildOptions.enableLowResourcesMode,
      trackPerformance: buildOptions.trackPerformance,
      logPerformanceDir: buildOptions.logPerformanceDir,
      resolvers: testingOverrides.resolvers,
    );
    var terminator = Terminator(testingOverrides.terminateEventStream);

    var watch = runWatch(
      options,
      environment,
      builders,
      buildOptions.builderConfigOverrides,
      terminator.shouldTerminate,
      testingOverrides.directoryWatcherFactory,
      buildOptions.configKey,
      buildOptions.buildDirs.any(
        (target) => target.outputLocation?.path.isNotEmpty ?? false,
      ),
      buildOptions.buildDirs,
      buildOptions.buildFilters,
      isReleaseMode: buildOptions.isReleaseBuild,
    );

    unawaited(
      watch.buildResults.drain<void>().then((_) async {
        await terminator.cancel();
      }),
    );

    return createServeHandler(watch);
  }
}

/// Listens to [buildResults], handling certain types of errors and completing
/// [completer] appropriately.
void handleBuildResultsStream(
  Stream<BuildResult> buildResults,
  Completer<int> completer,
) async {
  var subscription = buildResults.listen((result) {
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
