// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';

import 'package:build_runner/src/build_script_generate/build_script_generate.dart';
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
  if (commandName != _generateCommand) {
    logListener = Logger.root.onRecord.listen(stdIOLogListener());
  }
  var buildScript = await generateBuildScript();
  var scriptFile = File(scriptLocation)..createSync(recursive: true);
  scriptFile.writeAsStringSync(buildScript);
  if (commandName == _generateCommand) {
    print(p.absolute(scriptLocation));
    return;
  }

  var exitPort = ReceivePort();
  var errorPort = ReceivePort();
  var messagePort = ReceivePort();
  var errorListener = errorPort.listen((e) {
    stderr.writeln('\n\nYou have hit a bug in build_runner');
    stderr.writeln('Please file an issue with reproduction steps at '
        'https://github.com/dart-lang/build/issues\n\n');
    final error = e[0];
    final trace = e[1] as String;
    stderr.writeln(error);
    stderr.writeln(Trace.parse(trace).terse);
    if (exitCode == 0) exitCode = 1;
  });
  try {
    await Isolate.spawnUri(
        Uri.file(p.absolute(scriptLocation)), args, messagePort.sendPort,
        onExit: exitPort.sendPort, onError: errorPort.sendPort);
  } on IsolateSpawnException catch (e) {
    print(red.wrap('Failed to launch the build script. '
        'This is likely due to a misconfigured builder definition. '
        'See the generated script at $scriptLocation to find errors.'));
    print(e);
    messagePort.sendPort.send(ExitCode.config.code);
    exitPort.sendPort.send(null);
  }
  StreamSubscription exitCodeListener;
  exitCodeListener = messagePort.listen((isolateExitCode) {
    if (isolateExitCode is! int) {
      throw StateError(
          'Bad response from isolate, expected an exit code but got '
          '$isolateExitCode');
    }
    exitCode = isolateExitCode as int;
    exitCodeListener.cancel();
    exitCodeListener = null;
  });
  await exitPort.first;
  await errorListener.cancel();
  await logListener?.cancel();
  await exitCodeListener?.cancel();
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
}
