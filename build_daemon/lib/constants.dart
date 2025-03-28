// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

const readyToConnectLog = 'READY TO CONNECT';
const versionSkew = 'DIFFERENT RUNNING VERSION';
const optionsSkew = 'DIFFERENT OPTIONS';

const buildModeFlag = 'build-mode';

/// Daemon shuts down after this timeout if there is no active connection.
const defaultIdleTimeout = Duration(seconds: 30);

const fileChangeEventErrorCode = 101;
const fileChangeStreamClosedErrorCode = 102;

enum BuildMode {
  // ignore: constant_identifier_names
  Manual,
  // ignore: constant_identifier_names
  Auto,
}

/// These are used when serializing log messages over stdout.
///
/// Serialized logs must be preceded with the [logStartMarker] on its own line,
/// and terminated with a [logEndMarker] also on its own line.
///
/// This allows multi-line logs to be sanely serialized via stdout, and mixed
/// with other generic messages.
const logStartMarker = 'BUILD DAEMON LOG START';
const logEndMarker = 'BUILD DAEMON LOG END';

// TODO(grouma) - use pubspec version when this is open sourced.
const currentVersion = '9';

var _username = Platform.environment['USER'] ?? '';
String daemonWorkspace(String workingDirectory) {
  var segments = [Directory.systemTemp.path];
  if (_username.isNotEmpty) segments.add(_username);
  final workingDirHash = base64UrlEncode(
    md5.convert(workingDirectory.codeUnits).bytes,
  );
  segments.add(workingDirHash);
  return p.joinAll(segments);
}

/// Used to ensure that only one instance of this daemon is running at a time.
String lockFilePath(String workingDirectory) =>
    p.join(daemonWorkspace(workingDirectory), '.dart_build_lock');

/// Used to signal to clients on what port the running daemon is listening.
String portFilePath(String workingDirectory) =>
    p.join(daemonWorkspace(workingDirectory), '.dart_build_daemon_port');

/// Used to signal to clients the current version of the build daemon.
String versionFilePath(String workingDirectory) =>
    p.join(daemonWorkspace(workingDirectory), '.dart_build_daemon_version');

/// Used to signal to clients the current set of options of the build daemon.
String optionsFilePath(String workingDirectory) =>
    p.join(daemonWorkspace(workingDirectory), '.dart_build_daemon_options');
