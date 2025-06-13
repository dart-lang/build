// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:build_runner/src/build_script_generate/bootstrap.dart';
import 'package:build_runner/src/build_script_generate/build_process_state.dart';
import 'package:build_runner/src/entrypoint/options.dart';
import 'package:build_runner/src/entrypoint/runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';

import 'src/commands/clean.dart';
import 'src/commands/generate_build_script.dart';

Future<void> main(List<String> args) async {
  // Use the actual command runner to parse the args and immediately print the
  // usage information if there is no command provided or the help command was
  // explicitly invoked.
  var commandRunner = BuildCommandRunner(
    [],
    await PackageGraph.forThisPackage(),
  );
  var localCommands = [CleanCommand(), GenerateBuildScript()];
  var localCommandNames = localCommands.map((c) => c.name).toSet();
  for (var command in localCommands) {
    commandRunner.addCommand(command);
    // This flag is added to each command individually and not the top level.
    command.argParser.addFlag(
      verboseOption,
      abbr: 'v',
      defaultsTo: false,
      negatable: false,
      help: 'Verbose logging: displays info logged by builders.',
    );
  }

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
      yellow.wrap('Could not find a command named "${parsedArgs.rest[0]}".'),
    );
    print('');
    print(commandRunner.usageWithoutDescription);
    exitCode = ExitCode.usage.code;
    return;
  }

  if (commandName == 'help' ||
      parsedArgs.wasParsed('help') ||
      (parsedArgs.command?.wasParsed('help') ?? false)) {
    await commandRunner.runCommand(parsedArgs);
    return;
  }

  if (commandName == null) {
    commandRunner.printUsage();
    exitCode = ExitCode.usage.code;
    return;
  }

  if (localCommandNames.contains(commandName)) {
    exitCode = await commandRunner.runCommand(parsedArgs) ?? 1;
  } else {
    var experiments = parsedArgs.command!['enable-experiment'] as List<String>?;
    // Set the buildLog mode before the command starts so the first few log
    // messages are displayed correctly.
    switch (commandName) {
      case 'build':
      case 'serve':
      case 'watch':
      case 'test':
        buildLog.configuration = buildLog.configuration.rebuild((b) {
          b.mode = BuildLogMode.build;
        });
      case 'daemon':
        buildLog.configuration = buildLog.configuration.rebuild((b) {
          b.mode = BuildLogMode.daemon;
        });
    }
    while ((exitCode = await generateAndRun(args, experiments: experiments)) ==
        ExitCode.tempFail.code) {}
  }
}
