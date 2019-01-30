// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as p;

const readyToConnectLog = 'READY TO CONNECT';
const versionSkew = 'DIFFERENT RUNNING VERSION';
const optionsSkew = 'DIFFERENT OPTIONS';
const errorLog = 'ERROR';

// TODO(grouma) - use pubspec version when this is open sourced.
const currentVersion = '5.0.0';

var _username = Platform.environment['USER'] ?? '';
String daemonWorkspace(String workingDirectory) {
  var segments = [Directory.systemTemp.path];
  if (_username.isNotEmpty) segments.add(_username);
  segments.add(workingDirectory
      .replaceAll('/', '_')
      .replaceAll(':', '_')
      .replaceAll('\\', '_'));
  return p.joinAll(segments);
}

/// Used to ensure that only one instance of this daemon is running at a time.
String lockFilePath(String workingDirectory) =>
    p.join(daemonWorkspace(workingDirectory), '.dart_build_lock');

/// Used to communicate between daemon and client.
///
/// Unfortunate work around for https://github.com/dart-lang/sdk/issues/35809.
String communicationFilePath(String workingDirectory) => p.join(
    daemonWorkspace(workingDirectory), '.dart_build_daemon_communication');

/// Used to signal to clients on what port the running daemon is listening.
String portFilePath(String workingDirectory) =>
    p.join(daemonWorkspace(workingDirectory), '.dart_build_daemon_port');

/// Used to signal to clients the current version of the build daemon.
String versionFilePath(String workingDirectory) =>
    p.join(daemonWorkspace(workingDirectory), '.dart_build_daemon_version');

/// Used to signal to clients the current set of options of the build daemon.
String optionsFilePath(String workingDirectory) =>
    p.join(daemonWorkspace(workingDirectory), '.dart_build_daemon_options');
