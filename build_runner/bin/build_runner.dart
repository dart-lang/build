// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'package:build_runner/src/build_script_generate/build_script_generate.dart';
import 'package:build_runner/src/entrypoint/options.dart';
import 'package:build_runner/src/logging/std_io_logging.dart';

Future<Null> main(List<String> args) async {
  // Use the actual command runner to parse the args and immediately print the
  // usage information if there is no command provided or the help command was
  // explicitly invoked.
  var commandRunner = new BuildCommandRunner([])
    ..addCommand(new _GenerateBuildScript());
  var parsedArgs = commandRunner.parse(args);
  var commandName = parsedArgs.command?.name;
  if (commandName == null || commandName == 'help') {
    commandRunner.printUsage();
    return;
  }

  StreamSubscription logListener;
  if (commandName != _generateCommand) {
    logListener = Logger.root.onRecord.listen(stdIOLogListener);
  }
  var buildScript = await generateBuildScript();
  var scriptFile = new File(scriptLocation)..createSync(recursive: true);
  scriptFile.writeAsStringSync(buildScript);
  if (commandName == _generateCommand) {
    print(p.absolute(scriptLocation));
    return;
  }

  var exitPort = new ReceivePort();
  var errorPort = new ReceivePort();
  var errorListener = errorPort.listen((e) => stderr.writeAll(e as List, '\n'));
  await Isolate.spawnUri(new Uri.file(p.absolute(scriptLocation)), args, null,
      onExit: exitPort.sendPort, onError: errorPort.sendPort);
  await exitPort.first;
  await errorListener.cancel();
  await logListener?.cancel();
}

const _generateCommand = 'generate-build-script';

class _GenerateBuildScript extends Command {
  @override
  final description = 'Generate a script to run builds and print the file path '
      'with no other logging. Useful for wrapping builds with other tools.';

  @override
  final name = _generateCommand;
}
