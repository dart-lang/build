// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:build_daemon/client.dart';

void main(List<String> args) async {
  BuildDaemonClient client;
  var workingDirectory = Directory.current.path;
  try {
    client = await BuildDaemonClient.connect(workingDirectory,
        ['pub', 'run', 'build_daemon', workingDirectory, 'some-option']);
  } catch (e) {
    if (e is VersionSkew) {
      print('Version skew. Please disconnect all other clients '
          'before trying to start a new one: ${e.details}');
    } else if (e is OptionsSkew) {
      print('Options skew. Please disconnect all other clients '
          'before trying to start a new one: ${e.details}');
    } else {
      print('Unexpected error: $e');
    }

    exit(1);
  }
  if (client == null) throw Exception('Error connecting');
  print('Connected to Dart Build Daemon');
  if (Random().nextBool()) {
    client.registerBuildTarget('web', [r'.*_test\.dart$']);
    print('Registered example web target...');
  } else {
    client.registerBuildTarget('test', []);
    print('Registered test target...');
  }
  client.buildResults.listen((status) => print('BUILD STATUS: $status'));
  client.startBuild();
  await client.finished;
}
