// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build_daemon/src/daemon.dart';
import 'package:build_daemon/utilities.dart';
import 'package:build_runner/src/daemon/constants.dart';
import 'package:io/ansi.dart';

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
      if (validateOptions(workingDirectory, requestedOptions) &&
          validateVersion(workingDirectory)) {
        return 1;
      } else {
        notifyReady(workingDirectory);
        return 0;
      }
    } else {
      try {
        await overrideAnsiOutput(true, () async {
          var builder = await BuildRunnerDaemonBuilder.create(
            packageGraph,
            builderApplications,
            options,
          );
          var server = await AssetServer.run(builder, packageGraph.root.name);
          File(assetServerPortFilePath(workingDirectory))
              .writeAsStringSync('${server.port}');
          await daemon.start(requestedOptions, builder, builder.changes);
          notifyReady(workingDirectory);
          await daemon.onDone.whenComplete(server.stop);
        });
      } catch (e) {
        notifyError(workingDirectory, '$e');
        return 1;
      }
      return 0;
    }
  }
}
