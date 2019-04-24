// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build_daemon/constants.dart';
import 'package:build_daemon/src/daemon.dart';
import 'package:build_runner/src/daemon/constants.dart';
import 'package:logging/logging.dart';

import '../daemon/asset_server.dart';
import '../daemon/daemon_builder.dart';
import 'base_command.dart';

/// A command that starts the Build Daemon.
class DaemonCommand extends BuildRunnerCommand {
  @override
  String get description => 'Starts the build daemon.';

  @override
  bool get hidden => true;

  @override
  String get name => 'daemon';

  @override
  Future<int> run() async {
    var workingDirectory = Directory.current.path;
    var options = readOptions();
    var daemon = Daemon(workingDirectory);
    var requestedOptions = argResults.arguments.toSet();
    if (!daemon.tryGetLock()) {
      var runningOptions = await currentOptions(workingDirectory);
      var version = await runningVersion(workingDirectory);
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
      var startupLogSub =
          Logger.root.onRecord.listen((record) => stdout.writeln('$record\n'));
      builder = await BuildRunnerDaemonBuilder.create(
        packageGraph,
        builderApplications,
        options,
      );
      await startupLogSub.cancel();

      // Forward server logs to daemon command STDIO.
      var logSub =
          builder.logs.listen((serverLog) => stdout.writeln(serverLog.log));
      var server = await AssetServer.run(builder, packageGraph.root.name);
      File(assetServerPortFilePath(workingDirectory))
          .writeAsStringSync('${server.port}');
      await daemon.start(requestedOptions, builder, builder.changes);
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
    return 0;
  }
}
