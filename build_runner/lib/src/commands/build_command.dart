// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/experiments.dart';
import 'package:built_collection/built_collection.dart';
import 'package:io/io.dart';

import '../build_plan.dart';
import '../build_script_generate/build_process_state.dart';
import '../generate/build_result.dart';
import '../generate/build_series.dart';
import '../logging/build_log.dart';
import '../options/testing_overrides.dart';
import '../package_graph/apply_builders.dart';
import 'build_options.dart';
import 'build_runner_command.dart';

class BuildCommand implements BuildRunnerCommand {
  final BuiltList<BuilderApplication> builders;
  final BuildOptions buildOptions;
  final TestingOverrides testingOverrides;

  BuildCommand({
    required this.builders,
    required this.buildOptions,
    this.testingOverrides = const TestingOverrides(),
  });

  @override
  Future<int> run() =>
      withEnabledExperiments(_run, buildOptions.enableExperiments.asList());

  Future<int> _run() async {
    final result = await build();
    if (result.status == BuildStatus.success) {
      return ExitCode.success.code;
    } else {
      return result.failureType?.exitCode ?? 1;
    }
  }

  Future<BuildResult> build() async {
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
    final build = await BuildSeries.create(buildPlan: buildPlan);
    final result = await build.run({});
    await build.beforeExit();
    return result;
  }
}
