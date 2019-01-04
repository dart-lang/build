import 'dart:async';

import 'package:build_daemon/constants.dart';
import 'package:build_daemon/src/daemon.dart';
import 'package:build_daemon/daemon_builder.dart';
import 'package:watcher/watcher.dart';

/// Entrypoint for the Dart Build Daemon.
Future main(List<String> args) async {
  var workingDirectory = args[0];

  var daemon = Daemon(workingDirectory);

  if (!daemon.tryGetLock()) {
    if (runningVersion(workingDirectory) == currentVersion) {
      print('Daemon is already running.');
      print(readyToConnectLog);
    } else {
      print(versionSkew);
    }
  } else {
    print('Starting daemon...');
    // TODO(grouma) - Create a real builder for package:build
    var builder = DaemonBuilder();
    var watcher = Watcher(workingDirectory);
    await daemon.start(builder, watcher.events);
    print(readyToConnectLog);
    await daemon.onDone;
  }
}
