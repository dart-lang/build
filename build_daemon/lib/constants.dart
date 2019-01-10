// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

const readyToConnectLog = 'READY TO CONNECT';
const versionSkew = 'DIFFERENT RUNNING VERSION';
const optionsSkew = 'DIFFERENT OPTIONS';

// TODO(grouma) - use pubspec version when this is open sourced.
const currentVersion = '2.0.0';

String daemonWorkspace(String workingDirectory) =>
    '${Directory.systemTemp.path}/dart_build_daemon/'
    '${workingDirectory.replaceAll("/", "_")}';

/// Used to ensure that only one instance of this daemon is running at a time.
String lockFilePath(String workingDirectory) =>
    '${daemonWorkspace(workingDirectory)}/.dart_build_lock';

/// Used to signal to clients on what port the running daemon is listening.
String portFilePath(String workingDirectory) =>
    '${daemonWorkspace(workingDirectory)}/.dart_build_daemon_port';

/// Used to signal to clients the current version of the build daemon.
String versionFilePath(String workingDirectory) =>
    '${daemonWorkspace(workingDirectory)}/.dart_build_daemon_version';

/// Used to signal to clients the current set of options of the build daemon.
String optionsFilePath(String workingDirectory) =>
    '${daemonWorkspace(workingDirectory)}/.dart_build_daemon_options';
