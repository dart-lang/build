// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build_daemon/constants.dart';
import 'package:build_daemon/src/daemon.dart';

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
      var runningOptions = currentOptions(workingDirectory);
      var version = runningVersion(workingDirectory);
      if (version != currentVersion) {
        print('Running Version: $version');
        print('Current Version: $currentVersion');
        print(versionSkew);
      } else if (!(runningOptions.length == requestedOptions.length &&
          runningOptions.containsAll(requestedOptions))) {
        print('Running Options: $runningOptions');
        print('Requested Options: $requestedOptions');
        print(optionsSkew);
      } else {
        print('Daemon is already running.');
        print(readyToConnectLog);
      }
    } else {
      print('Starting daemon...');
      var builder = await BuildRunnerDaemonBuilder.create(
        packageGraph,
        builderApplications,
        options,
      );
      await daemon.start(requestedOptions, builder, builder.changes);
      print(readyToConnectLog);
      await daemon.onDone;
    }
    return 0;
  }
}
