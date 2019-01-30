// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'constants.dart';

/// Returns the current options of the running build daemon.
///
/// Null if one isn't running.
Set<String> currentOptions(String workingDirectory) {
  var optionsFile = File(optionsFilePath(workingDirectory));
  if (!optionsFile.existsSync()) return Set();
  return optionsFile.readAsLinesSync().toSet();
}

/// Notifies the initiating client that there was an error
/// starting the daemon.
void notifyError(String workingDirectory, String error) =>
    File(communicationFilePath(workingDirectory))
        .writeAsStringSync('$errorLog\n$error');

/// Notifies the initiating client that the daemon is ready
/// for connections.
void notifyReady(String workingDirectory) =>
    File(communicationFilePath(workingDirectory))
        .writeAsStringSync(readyToConnectLog);

/// Returns the current version of the running build daemon.
///
/// Null if one isn't running.
String runningVersion(String workingDirectory) {
  var versionFile = File(versionFilePath(workingDirectory));
  if (!versionFile.existsSync()) return null;
  return versionFile.readAsStringSync();
}

/// Creates a file for communication between client and daemon.
///
/// Unfortunate work around for https://github.com/dart-lang/sdk/issues/35809.
File createCommunicationFile(String workingDirectory) =>
    File(communicationFilePath(workingDirectory))..createSync(recursive: true);

/// Returns true if the options are valid with the current running daemon.
bool validateOptions(String workingDirectory, Set<String> requestedOptions) {
  var runningOptions = currentOptions(workingDirectory);
  if (!(runningOptions.length == requestedOptions.length &&
      runningOptions.containsAll(requestedOptions))) {
    var output = '$optionsSkew\n';
    output += 'Running Options: $runningOptions\n';
    output += 'Requested Options: $requestedOptions';
    File(communicationFilePath(workingDirectory)).writeAsStringSync(output);
    return false;
  }
  return true;
}

/// Returns true if the current running daemon version matches.
bool validateVersion(String workingDirectory) {
  var version = runningVersion(workingDirectory);
  var output = '';
  var comFile = File(communicationFilePath(workingDirectory));
  if (version != currentVersion) {
    output += '$versionSkew\n';
    output += 'Running Version: $version\n';
    output += 'Current Version: $currentVersion\n';
    comFile.writeAsStringSync(output);
    return false;
  }
  return true;
}
