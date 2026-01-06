// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/experiments.dart';
import 'package:build_daemon/constants.dart';
import 'package:build_daemon/daemon.dart';
import 'package:build_daemon/data/serializers.dart';
import 'package:build_daemon/data/server_log.dart';
import 'package:built_collection/built_collection.dart';
import 'package:io/io.dart';

import '../bootstrap/build_process_state.dart';
import '../build_plan/build_options.dart';
import '../build_plan/build_plan.dart';
import '../build_plan/builder_factories.dart';
import '../build_plan/testing_overrides.dart';
import '../logging/build_log.dart';
import 'build_runner_command.dart';
import 'daemon/asset_server.dart';
import 'daemon/constants.dart';
import 'daemon/daemon_builder.dart';
import 'daemon_options.dart';

class DaemonCommand implements BuildRunnerCommand {
  final BuilderFactories builderFactories;
  final BuiltList<String> arguments;
  final BuildOptions buildOptions;
  final DaemonOptions daemonOptions;
  final TestingOverrides testingOverrides;

  DaemonCommand({
    required this.builderFactories,
    required this.arguments,
    required this.buildOptions,
    required this.daemonOptions,
    this.testingOverrides = const TestingOverrides(),
  });

  @override
  Future<int> run() =>
      withEnabledExperiments(_run, buildOptions.enableExperiments.asList());

  Future<int> _run() async {
    buildLog.configuration = buildLog.configuration.rebuild((b) {
      b.mode = BuildLogMode.daemon;
      b.verbose = buildOptions.verbose;
    });
    final workingDirectory = Directory.current.path;
    final daemon = Daemon(workingDirectory);
    final requestedOptions = arguments.toSet();
    if (!daemon.hasLock) {
      final runningOptions = await daemon.currentOptions();
      final version = await daemon.runningVersion();
      if (version != currentVersion) {
        stdout
          ..writeln('Running Version: $version')
          ..writeln('Current Version: $currentVersion')
          ..writeln(versionSkew);
        return 1;
      } else if (!(runningOptions.length == requestedOptions.length &&
          runningOptions.containsAll(requestedOptions))) {
        stdout
          ..writeln('Running Options: $runningOptions')
          ..writeln('Requested Options: $requestedOptions')
          ..writeln(optionsSkew);
        return 1;
      } else {
        stdout.writeln('Daemon is already running.');
        print(readyToConnectLog);
        return 0;
      }
    } else {
      stdout.writeln('Starting daemon...');
      // Ensure we capture any logs that happen during startup.
      //
      // These are serialized between special `<log-record>` and `</log-record>`
      // tags to make parsing them on stdout easier. They can have multiline
      // strings so we can't just serialize the json on a single line.
      //
      // `BuildRunnerDaemonBuilder` sets its own `onLog` replacing this one.
      buildLog.configuration = buildLog.configuration.rebuild((b) {
        b.onLog =
            (record) => stdout.writeln('''
$logStartMarker
${jsonEncode(serializers.serialize(ServerLog.fromLogRecord(record)))}
$logEndMarker''');
      });

      final buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      await buildPlan.deleteFilesAndFolders();
      if (buildPlan.restartIsNeeded) return ExitCode.tempFail.code;

      final builder = await BuildRunnerDaemonBuilder.create(
        buildPlan: buildPlan,
        daemonOptions: daemonOptions,
      );

      // Forward server logs to daemon command STDIO.
      final logSub = builder.logs.listen((log) {
        if (log.level > Level.INFO || buildOptions.verbose) {
          final buffer = StringBuffer(log.message);
          if (log.error != null) buffer.writeln(log.error);
          if (log.stackTrace != null) buffer.writeln(log.stackTrace);
          stderr.writeln(buffer);
        } else {
          stdout.writeln(log.message);
        }
      });
      final server = await AssetServer.run(
        daemonOptions,
        builder,
        buildPlan.packageGraph.currentPackage.name,
      );
      File(
        assetServerPortFilePath(workingDirectory),
      ).writeAsStringSync('${server.port}');
      unawaited(
        builder.buildScriptUpdated.then((_) async {
          await daemon.stop(
            message: 'Build script updated. Shutting down the Build Daemon.',
            failureType: 75,
          );
        }),
      );
      await daemon.start(
        requestedOptions,
        builder,
        builder.changeProvider,
        timeout: const Duration(seconds: 60),
      );
      stdout.writeln(readyToConnectLog);
      await logSub.cancel();
      await daemon.onDone.whenComplete(() async {
        await server.stop();
      });
      // Clients can disconnect from the daemon mid build.
      // As a result we try to relinquish resources which can
      // cause the build to hang. To ensure there are no ghost processes
      // fast exit.
      exit(0);
    }
  }
}
