// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'constants.dart';
import 'src/file_wait.dart';

/// Returns the current version of the running build daemon.
///
/// Null if one isn't running.
Future<String> runningVersion(String workingDirectory) async {
  var versionFile = File(versionFilePath(workingDirectory));
  if (!await waitForFile(versionFile)) return null;
  return versionFile.readAsStringSync();
}

/// Returns the current options of the running build daemon.
///
/// Null if one isn't running.
Future<Set<String>> currentOptions(String workingDirectory) async {
  var optionsFile = File(optionsFilePath(workingDirectory));
  if (!await waitForFile(optionsFile)) return Set();
  return optionsFile.readAsLinesSync().toSet();
}
