// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:build_daemon/client.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  BuildDaemonClient client;
  var workingDirectory =
      p.normalize(p.join(Directory.current.path + '/../example'));

  try {
    client = await BuildDaemonClient.connect(
        workingDirectory,
        [
          'pub',
          'run',
          'build_runner',
          'daemon',
          '--delete-conflicting-outputs',
        ],
        logHandler: print);
  } catch (e) {
    if (e is VersionSkew) {
      print('Version skew. Please disconnect all other clients '
          'before trying to start a new one.');
    } else if (e is OptionsSkew) {
      print('Options skew. Please disconnect all other clients '
          'before trying to start a new one.');
    } else {
      print('Unexpected error: $e');
    }

    exit(1);
  }
  if (client == null) throw Exception('Error connecting');
  print('Connected to Dart Build Daemon');
  if (Random().nextBool()) {
    client.registerBuildTarget(DefaultBuildTarget((b) => b
      ..target = 'web'
      ..outputLocation = OutputLocation((b) => b
        ..output = 'web_output'
        ..outputSymlinks = false
        ..hoist = true).toBuilder()
      ..blackListPatterns.replace([RegExp(r'.*_test\.dart$')])));
    print('Registered example web target...');
  } else {
    client.registerBuildTarget(DefaultBuildTarget((b) => b
      ..target = 'test'
      ..outputLocation = OutputLocation((b) => b
        ..output = 'test_output'
        ..outputSymlinks = true
        ..hoist = false).toBuilder()));

    print('Registered test target...');
  }
  client.buildResults.listen((status) => print('BUILD STATUS: $status'));
  client.startBuild();
  await client.finished;
}
