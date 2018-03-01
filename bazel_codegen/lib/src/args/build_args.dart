// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

const _rootDirParam = 'root-dir';
const _helpParam = 'help';
const _buildExtensions = 'build-extensions';
const _logLevelParam = 'log-level';
const _logPathParam = 'log';
const _outParam = 'out';
const _packagePathParam = 'package-path';
const _packageMapParam = 'package-map';
const _srcsParam = 'srcs-file';
const _summariesParam = 'use-summaries';

// All arguments other than `--help` and `--use-summaries` are required.
final _argParser = new ArgParser()
  ..addOption(_rootDirParam,
      allowMultiple: true,
      help: 'One or more workspace directories to check when reading files.')
  ..addFlag(_helpParam,
      abbr: 'h', negatable: false, help: 'Prints this message and exits')
  ..addOption(_buildExtensions,
      allowMultiple: true,
      help: 'The file extensions to process. For each input extension add an '
          'argument in the format "input:output1;output2"')
  ..addOption(_logLevelParam,
      allowed: _optionToLogLevel.keys.toList(),
      defaultsTo: 'warning',
      help: 'The minimum level of log to print to the console.')
  ..addOption(_logPathParam, help: 'The full path of the logfile to write')
  ..addOption(_outParam, abbr: 'o', help: 'The directory to write into.')
  ..addFlag(_summariesParam,
      negatable: true,
      defaultsTo: true,
      help: 'Whether to use summaries for analysis')
  ..addOption(_packagePathParam,
      help: 'The path of the package we are processing relative to CWD')
  ..addOption(_packageMapParam,
      help: 'Path to a file containing the path under the bazel roots to each '
          'package name.')
  ..addOption(_srcsParam,
      help: 'Path to a file containing all files to generate code for. '
          'Each line in this file is the path to a source to generate for. '
          'These are expected to be relative to CWD.');

Map<String, Level> _optionToLogLevel = {
  'fine': Level.FINE,
  'info': Level.INFO,
  'warning': Level.WARNING,
  'error': Level.SEVERE,
};

/// Parsed arguments for code generator binaries.
class BuildArgs {
  final List<String> rootDirs;
  final String packagePath;
  final String outDir;
  final Level logLevel;
  final String logPath;
  final Map<String, List<String>> buildExtensions;
  final String packageMapPath;
  final String srcsPath;
  final bool help;
  final bool isWorker;
  final bool useSummaries;
  final List<String> additionalArgs;

  BuildArgs._(
      this.rootDirs,
      this.packagePath,
      this.outDir,
      this.logPath,
      this.buildExtensions,
      this.packageMapPath,
      this.srcsPath,
      this.help,
      this.logLevel,
      {this.isWorker,
      this.useSummaries: true,
      this.additionalArgs});

  factory BuildArgs.parse(List<String> args, {bool isWorker}) {
    // When not running as a worker, but that mode is supported, then we get
    // just this arg which points at a file containing the arguments.
    if (args.length == 1 && args.first.startsWith('@')) {
      args = new File(args.first.substring(1)).readAsLinesSync();
    }

    final argResults = _argParser.parse(args);

    final rootDirs = (_requiredArg(argResults, _rootDirParam) as List)
        .map((v) => v as String)
        .toList();
    final packagePath = _requiredArg(argResults, _packagePathParam) as String;
    final outDir = _requiredArg(argResults, _outParam) as String;
    final logLevel =
        _optionToLogLevel[_requiredArg(argResults, _logLevelParam)];

    final logPath = _requiredArg(argResults, _logPathParam) as String;
    final rawBuildExtensions =
        _requiredArg(argResults, _buildExtensions) as Iterable;
    final buildExtensions = new Map<String, List<String>>.fromIterable(
        rawBuildExtensions,
        key: (e) => (e as String).split(':').first,
        value: (e) => (e as String).split(':').last.split(';').toList());

    final packageMapPath = _requiredArg(argResults, _packageMapParam) as String;
    final srcsPath = _requiredArg(argResults, _srcsParam) as String;
    final help = argResults[_helpParam] as bool;
    final useSummaries = argResults[_summariesParam] as bool;

    return new BuildArgs._(rootDirs, packagePath, outDir, logPath,
        buildExtensions, packageMapPath, srcsPath, help, logLevel,
        additionalArgs: argResults.rest,
        isWorker: isWorker,
        useSummaries: useSummaries);
  }

  void printUsage() {
    print('Usage: dart ${Platform.script.pathSegments.last} '
        '<options(s)> <Additional args for generator>');
    print('All options are required');
    print('Options:\n${_argParser.usage}');
  }
}

dynamic _requiredArg(ArgResults results, String param) {
  final val = results[param];
  if (val == null) throw new ArgumentError.notNull(param);
  return val;
}
