// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:build_daemon/constants.dart';
import 'package:built_collection/built_collection.dart';

import 'internal.dart';

enum CommandType {
  build,
  clean,
  daemon,
  run,
  serve,
  test,
  watch;

  BuildLogMode get buildLogMode {
    if (this == clean) return BuildLogMode.simple;
    if (this == daemon) return BuildLogMode.daemon;
    return BuildLogMode.build;
  }

  /// Whether the command must be launched as a nested `build_runner` binary
  /// built with configured builders.
  bool get requiresBuilders => this != clean;
}

/// A `build_runner` command line with arguments parsed to primitive types.
class BuildRunnerCommandLine {
  // The entire command line.
  final BuiltList<String> arguments;
  // The command line after parsed options.
  final BuiltList<String> rest;

  final CommandType type;

  final BuiltList<String>? buildFilter;
  final String? buildMode;
  final String? config;
  final BuiltList<String>? defines;
  final BuiltList<String>? enableExperiments;
  final String? hostname;
  final bool? liveReload;
  final String? logPerformance;
  final bool? logRequests;
  final bool? lowResourcesMode;
  final BuiltList<String>? outputs;
  final bool? release;
  final bool? trackPerformance;
  final bool? symlink;
  final bool? verbose;

  static Future<BuildRunnerCommandLine?> parse(Iterable<String> arguments) =>
      _CommandRunner().run(arguments);

  BuildRunnerCommandLine(this.type, ArgResults argResults)
    : arguments = argResults.arguments.build(),
      rest = argResults.rest.build(),
      buildFilter = argResults.listNamed(buildFilterOption),
      buildMode = argResults.stringNamed(buildModeFlag),
      config = argResults.stringNamed(configOption),
      defines = argResults.listNamed(defineOption),
      enableExperiments = argResults.listNamed(enableExperimentOption),
      hostname = argResults.stringNamed(hostnameOption),
      liveReload = argResults.boolNamed(liveReloadOption),
      logPerformance = argResults.stringNamed(logPerformanceOption),
      logRequests = argResults.boolNamed(logRequestsOption),
      lowResourcesMode = argResults.boolNamed(lowResourcesModeOption),
      outputs = argResults.listNamed(outputOption),
      release = argResults.boolNamed(releaseOption),
      trackPerformance = argResults.boolNamed(trackPerformanceOption),
      symlink = argResults.boolNamed(symlinkOption),
      verbose = argResults.boolNamed(verboseOption);

  String get usage {
    // Calling `usage` only works if the command has been added to a
    // `CommandRunner`. So, use singletons that do get added to one.
    switch (type) {
      case CommandType.build:
        return _build.usage;
      case CommandType.clean:
        return _clean.usage;
      case CommandType.daemon:
        return _daemon.usage;
      case CommandType.run:
        return _run.usage;
      case CommandType.serve:
        return _serve.usage;
      case CommandType.test:
        return _test.usage;
      case CommandType.watch:
        return _watch.usage;
    }
  }

  /// The number of arguments in [rest] that are from before any `--` on the
  /// command line.
  int get restArgumentsBeforeSeparator {
    final index = arguments.indexOf('--') + 1;
    final numArgumentsAfter = (index > 0) ? arguments.length - index : 0;
    return rest.length - numArgumentsAfter;
  }
}

extension _ArgResultsExtension on ArgResults {
  bool? boolNamed(String name) => options.contains(name) ? flag(name) : null;
  BuiltList<String>? listNamed(String name) =>
      options.contains(name) ? multiOption(name).build() : null;
  String? stringNamed(String name) =>
      options.contains(name) ? option(name) : null;
}

const buildFilterOption = 'build-filter';
const configOption = 'config';
const defineOption = 'define';
const deleteFilesByDefaultOption = 'delete-conflicting-outputs';
const enableExperimentOption = 'enable-experiment';
const hostnameOption = 'hostname';
const liveReloadOption = 'live-reload';
const logPerformanceOption = 'log-performance';
const logRequestsOption = 'log-requests';
const lowResourcesModeOption = 'low-resources-mode';
const outputOption = 'output';
const releaseOption = 'release';
const trackPerformanceOption = 'track-performance';
const symlinkOption = 'symlink';
const verboseOption = 'verbose';

/// [CommandRunner] that returns a [BuildRunnerCommandLine] without actually
/// running it.
class _CommandRunner extends CommandRunner<BuildRunnerCommandLine> {
  _CommandRunner()
    : super(
        'build_runner',
        'Dart build tool.',
        usageLineLength:
            buildProcessState.stdio.hasTerminal
                ? buildProcessState.stdio.terminalColumns
                : 80,
      ) {
    addCommand(_build);
    addCommand(_clean);
    addCommand(_daemon);
    addCommand(_run);
    addCommand(_serve);
    addCommand(_test);
    addCommand(_watch);
  }
}

final _build = _Build();

class _Build extends Command<BuildRunnerCommandLine> {
  _Build() {
    addBuildArgs(argParser, symlinksDefault: false);
  }

  /// Adds args common to all build commands to [argParser].
  static void addBuildArgs(
    ArgParser argParser, {
    required bool symlinksDefault,
  }) {
    argParser
      // No longer does anything, but accept so old usage does not fail.
      ..addFlag(
        deleteFilesByDefaultOption,
        hide: true,
        abbr: 'd',
        negatable: false,
      )
      ..addFlag(
        lowResourcesModeOption,
        help:
            'Reduce the amount of memory consumed by the build process. '
            'This will slow down builds but allow them to progress in '
            'resource constrained environments.',
        negatable: false,
        defaultsTo: false,
      )
      ..addOption(
        configOption,
        help: 'Read `build.<name>.yaml` instead of the default `build.yaml`',
        abbr: 'c',
      )
      ..addFlag(
        'fail-on-severe',
        help: 'Deprecated argument - always enabled',
        negatable: true,
        defaultsTo: true,
        hide: true,
      )
      ..addFlag(
        trackPerformanceOption,
        help: r'Enables performance tracking and the /$perf page.',
        negatable: true,
        defaultsTo: false,
      )
      ..addOption(
        logPerformanceOption,
        help:
            'A directory to write performance logs to, must be in the '
            'current package. Implies `--track-performance`.',
      )
      ..addMultiOption(
        outputOption,
        help:
            'A directory to copy the fully built package to. Or a mapping '
            'from a top-level directory in the package to the directory to '
            'write a filtered build output to. For example "web:deploy".',
        abbr: 'o',
      )
      ..addFlag(
        verboseOption,
        abbr: 'v',
        defaultsTo: false,
        negatable: false,
        help: 'Verbose logging: displays info logged by builders.',
      )
      ..addFlag(
        releaseOption,
        abbr: 'r',
        defaultsTo: false,
        negatable: true,
        help: 'Build with release mode defaults for builders.',
      )
      ..addMultiOption(
        defineOption,
        splitCommas: false,
        help: 'Sets the global `options` config for a builder by key.',
      )
      ..addFlag(
        symlinkOption,
        defaultsTo: symlinksDefault,
        negatable: true,
        help: 'Symlink files in the output directories, instead of copying.',
      )
      ..addMultiOption(
        buildFilterOption,
        help:
            'An explicit filter of files to build. Relative paths and '
            '`package:` uris are supported, including glob syntax for paths '
            'portions (but not package names).\n\n'
            'If multiple filters are applied then outputs matching any '
            'filter will be built (they do not need to match all filters).',
      )
      ..addMultiOption(
        enableExperimentOption,
        help: 'A list of dart language experiments to enable.',
      );
  }

  @override
  String get invocation => '${super.invocation} [directories]';

  @override
  String get name => 'build';

  @override
  String get description => 'Builds the current package.';

  @override
  Future<BuildRunnerCommandLine> run() async =>
      BuildRunnerCommandLine(CommandType.build, argResults!);
}

final _clean = _Clean();

class _Clean extends Command<BuildRunnerCommandLine> {
  @override
  String get name => 'clean';

  @override
  String get description =>
      'Deletes the build cache. The next build will be a full build.';

  @override
  Future<BuildRunnerCommandLine> run() async =>
      BuildRunnerCommandLine(CommandType.clean, argResults!);
}

final _daemon = _Daemon();

class _Daemon extends Command<BuildRunnerCommandLine> {
  @override
  String get description => 'Starts the build daemon.';

  @override
  bool get hidden => true;

  @override
  String get name => 'daemon';

  _Daemon() {
    _Build.addBuildArgs(argParser, symlinksDefault: false);
    argParser
      ..addOption(
        buildModeFlag,
        help: 'Specify the build mode of the daemon, e.g. auto or manual.',
        defaultsTo: 'BuildMode.Auto',
      )
      ..addFlag(
        logRequestsOption,
        defaultsTo: false,
        negatable: false,
        help: 'Enables logging for each request to the server.',
      );
  }

  @override
  Future<BuildRunnerCommandLine> run() async =>
      BuildRunnerCommandLine(CommandType.daemon, argResults!);
}

final _run = _Run();

class _Run extends Command<BuildRunnerCommandLine> {
  _Run() {
    _Build.addBuildArgs(argParser, symlinksDefault: false);
  }

  @override
  String get name => 'run';

  @override
  String get description => 'Builds the current package, executes a script.';

  @override
  String get invocation =>
      '${super.invocation.replaceFirst('[arguments]', '[build-arguments]')} '
      '<executable> [-- [script-arguments]]';

  @override
  Future<BuildRunnerCommandLine> run() async =>
      BuildRunnerCommandLine(CommandType.run, argResults!);
}

final _serve = _Serve();

class _Serve extends Command<BuildRunnerCommandLine> {
  _Serve() {
    _Build.addBuildArgs(argParser, symlinksDefault: false);
    argParser
      ..addOption(
        hostnameOption,
        help: 'Specify the hostname to serve on',
        defaultsTo: 'localhost',
      )
      ..addFlag(
        logRequestsOption,
        defaultsTo: false,
        negatable: false,
        help: 'Enables logging for each request to the server.',
      )
      ..addFlag(
        liveReloadOption,
        defaultsTo: false,
        negatable: false,
        help: 'Enables automatic page reloading on rebuilds. ',
      );
  }

  @override
  String get invocation => '${super.invocation} [<directory>[:<port>]]...';

  @override
  String get name => 'serve';

  @override
  String get description =>
      'Continuously builds and serves the current package.';

  @override
  Future<BuildRunnerCommandLine> run() async =>
      BuildRunnerCommandLine(CommandType.serve, argResults!);
}

final _test = _Test();

class _Test extends Command<BuildRunnerCommandLine> {
  _Test() {
    _Build.addBuildArgs(argParser, symlinksDefault: !Platform.isWindows);
  }

  @override
  String get invocation =>
      '${super.invocation.replaceFirst('[arguments]', '[build-arguments]')} '
      '[-- [test-arguments]]';

  @override
  String get name => 'test';

  @override
  String get description => 'Builds the current package then runs tests.';

  @override
  Future<BuildRunnerCommandLine> run() async =>
      BuildRunnerCommandLine(CommandType.test, argResults!);
}

final _watch = _Watch();

class _Watch extends Command<BuildRunnerCommandLine> {
  _Watch() {
    _Build.addBuildArgs(argParser, symlinksDefault: false);
  }

  @override
  String get invocation => '${super.invocation} [directories]';

  @override
  String get name => 'watch';

  @override
  String get description => 'Continuously builds the current package.';

  @override
  Future<BuildRunnerCommandLine> run() async =>
      BuildRunnerCommandLine(CommandType.watch, argResults!);
}
