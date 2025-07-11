// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
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
import 'package:build_runner_core/build_runner_core.dart';

import '../build_script_generate/build_process_state.dart';
import '../daemon/asset_server.dart';
import '../daemon/constants.dart';
import '../daemon/daemon_builder.dart';
import 'options.dart';
import 'watch.dart';

/// A command that starts the Build Daemon.
class DaemonCommand extends WatchCommand {
  @override
  String get description => 'Starts the build daemon.';

  @override
  bool get hidden => true;

  @override
  String get name => 'daemon';

  DaemonCommand() {
    argParser
      ..addOption(
        buildModeFlag,
        help: 'Specify the build mode of the daemon, e.g. auto or manual.',
        defaultsTo: 'BuildMode.Auto',
      )
      ..addFlag(
        logRequestsOption,
        defaultsTo: false,
        negatable: false,
        help: 'Enables logging for each request to the server.',
      );
  }

  @override
  DaemonOptions readOptions() => DaemonOptions.fromParsedArgs(
    argResults!,
    argResults!.rest,
    packageGraph.root.name,
    this,
  );

  @override
  Future<int> run() async {
    buildLog.configuration = buildLog.configuration.rebuild((b) {
      b.mode = BuildLogMode.daemon;
    });
    var options = readOptions();
    return withEnabledExperiments(
      () => _run(options),
      options.enableExperiments,
    );
  }

  Future<int> _run(DaemonOptions options) async {
    var workingDirectory = Directory.current.path;
    var daemon = Daemon(workingDirectory);
    var requestedOptions = argResults!.arguments.toSet();
    if (!daemon.hasLock) {
      var runningOptions = await daemon.currentOptions();
      var version = await daemon.runningVersion();
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
      BuildRunnerDaemonBuilder builder;
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
      builder = await BuildRunnerDaemonBuilder.create(
        packageGraph,
        builderApplications,
        options,
      );

      // Forward server logs to daemon command STDIO.
      var logSub = builder.logs.listen((log) {
        if (log.level > Level.INFO || options.verbose) {
          var buffer = StringBuffer(log.message);
          if (log.error != null) buffer.writeln(log.error);
          if (log.stackTrace != null) buffer.writeln(log.stackTrace);
          stderr.writeln(buffer);
        } else {
          stdout.writeln(log.message);
        }
      });
      var server = await AssetServer.run(
        options,
        builder,
        packageGraph.root.name,
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
