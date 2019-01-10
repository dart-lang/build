// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_daemon/constants.dart';
import 'package:build_daemon/src/daemon.dart';
import 'package:build_daemon/daemon_builder.dart';
import 'package:watcher/watcher.dart';

/// Entrypoint for the Dart Build Daemon.
Future main(List<String> args) async {
  var workingDirectory = args.first;
  var requestedOptions = args.sublist(1).toSet();

  var daemon = Daemon(workingDirectory);

  if (!daemon.tryGetLock()) {
    var runningOptions = currentOptions(workingDirectory);
    var version = runningVersion(workingDirectory);
    if (version != currentVersion) {
      print('Running Version: $version');
      print('Current Version: $currentVersion');
      print(versionSkew);
    } else if (!(runningOptions.containsAll(requestedOptions) &&
        runningOptions.length == requestedOptions.length)) {
      print('Running Options: $runningOptions');
      print('Requested Options: $requestedOptions');
      print(optionsSkew);
    } else {
      print('Daemon is already running.');
      print(readyToConnectLog);
    }
  } else {
    print('Starting daemon...');
    // TODO(grouma) - Create a real builder for package:build
    var builder = DaemonBuilder();
    var watcher = Watcher(workingDirectory);
    await daemon.start(requestedOptions, builder, watcher.events);
    print(readyToConnectLog);
    await daemon.onDone;
  }
}
