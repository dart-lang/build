import 'dart:io';
import 'dart:math';

import 'package:build_daemon/client.dart';

void main(List<String> args) async {
  BuildDaemonClient client;
  var workingDirectory = Directory.current.path;
  try {
    client = await BuildDaemonClient.connect(workingDirectory);
  } on VersionSkew {
    print('Version skew. Please disconnect all other clients '
        'before trying to start a new one.');
    exit(1);
  }
  if (client == null) throw Exception('Error connecting');
  print('Connected to Dart Build Daemon');
  if (Random().nextBool()) {
    client.registerBuildTarget('/some/client/path', [r'.*_test\.dart$']);
    client.addBuildOptions(['--define=DART_CHECKS=none']);
    print('Registered example client target...');
  } else {
    client.registerBuildTarget('/some/test/path', []);
    print('Registered test target...');
  }
  client.buildResults.listen((status) => print('BUILD STATUS: $status'));
  client.startBuild();
  await client.finished;
}
