// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:logging/logging.dart';

import 'package:build_runner/src/build_script_generate/build_script_generate.dart';
import 'package:build_runner/src/entrypoint/options.dart';
import 'package:build_runner/src/logging/std_io_logging.dart';

Future<Null> main(List<String> args) async {
  var logListener = Logger.root.onRecord.listen(stdIOLogListener);

  // Use the actual command runner to parse the args and immediately print the
  // usage information if there is no command provided or the help command was
  // explicitly invoked.
  var commandRunner = new BuildCommandRunner([]);
  var parsedArgs = commandRunner.parse(args);
  var commandName = parsedArgs.command?.name;
  if (commandName == null || commandName == 'help') {
    commandRunner.printUsage();
    return;
  }

  var buildScript = await generateBuildScript();
  var scriptFile = new File(scriptLocation)..createSync(recursive: true);
  scriptFile.writeAsStringSync(buildScript);

  var exitPort = new ReceivePort();
  await Isolate.spawnUri(scriptFile.uri, args, null, onExit: exitPort.sendPort);
  await exitPort.first;
  await logListener.cancel();
}
