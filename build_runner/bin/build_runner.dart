// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'package:build_runner/src/build_script_generate/build_script_generate.dart';
import 'package:build_runner/src/build_script_generate/bootstrap.dart';
import 'package:build_runner/src/entrypoint/runner.dart';
import 'package:build_runner/src/logging/std_io_logging.dart';

Future<Null> main(List<String> args) async {
  // Use the actual command runner to parse the args and immediately print the
  // usage information if there is no command provided or the help command was
  // explicitly invoked.
  var commandRunner = BuildCommandRunner([])
    ..addCommand(_GenerateBuildScript());

  ArgResults parsedArgs;
  try {
    parsedArgs = commandRunner.parse(args);
  } on UsageException catch (e) {
    print(red.wrap(e.message));
    print('');
    print(e.usage);
    exitCode = ExitCode.usage.code;
    return;
  }

  var commandName = parsedArgs.command?.name;

  if (parsedArgs.rest.isNotEmpty) {
    print(
        yellow.wrap('Could not find a command named "${parsedArgs.rest[0]}".'));
    print('');
    print(commandRunner.usageWithoutDescription);
    exitCode = ExitCode.usage.code;
    return;
  }

  if (commandName == null || commandName == 'help') {
    commandRunner.printUsage();
    return;
  }

  StreamSubscription logListener;
  if (commandName == _generateCommand) {
    exitCode = await commandRunner.runCommand(parsedArgs);
    return;
  }
  logListener = Logger.root.onRecord.listen(stdIOLogListener());

  while ((exitCode = await generateAndRun(args)) == ExitCode.tempFail.code) {}
  await logListener?.cancel();
}

const _generateCommand = 'generate-build-script';

class _GenerateBuildScript extends Command<int> {
  @override
  final description = 'Generate a script to run builds and print the file path '
      'with no other logging. Useful for wrapping builds with other tools.';

  @override
  final name = _generateCommand;

  @override
  bool get hidden => true;

  @override
  Future<int> run() async {
    var buildScript = await generateBuildScript();
    File(scriptLocation)
      ..createSync(recursive: true)
      ..writeAsStringSync(buildScript);
    print(p.absolute(scriptLocation));
    return 0;
  }
}
