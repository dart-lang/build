import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

const _rootDirParam = 'root-dir';
const _helpParam = 'help';
const _inExtension = 'in-extension';
const _logLevelParam = 'log-level';
const _logPathParam = 'log';
const _outExtension = 'out-extension';
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
  ..addOption(_inExtension, help: 'The file extension to process')
  ..addOption(_logLevelParam,
      allowed: _optionToLogLevel.keys.toList(),
      defaultsTo: 'warning',
      help: 'The minimum level of log to print to the console.')
  ..addOption(_logPathParam, help: 'The full path of the logfile to write')
  ..addOption(_outParam, abbr: 'o', help: 'The directory to write into.')
  ..addOption(_outExtension,
      allowMultiple: true, help: 'The file extension to output')
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
class Options {
  final List<String> rootDirs;
  final String packagePath;
  final String outDir;
  final Level logLevel;
  final String logPath;
  final String inputExtension;
  final List<String> outputExtensions;
  final String packageMapPath;
  final String srcsPath;
  final bool help;
  final bool isWorker;
  final bool useSummaries;
  final List<String> additionalArgs;

  Options._(
      this.rootDirs,
      this.packagePath,
      this.outDir,
      this.logPath,
      this.inputExtension,
      this.outputExtensions,
      this.packageMapPath,
      this.srcsPath,
      this.help,
      this.logLevel,
      {this.isWorker,
      this.useSummaries: true,
      this.additionalArgs});

  factory Options.parse(List<String> args, {bool isWorker}) {
    // When not running as a worker, but that mode is supported, then we get
    // just this arg which points at a file containing the arguments.
    if (args.length == 1 && args.first.startsWith('@')) {
      args = new File(args.first.substring(1)).readAsLinesSync();
    }

    final argResults = _argParser.parse(args);

    final rootDirs = _checkNotNull(argResults, _rootDirParam) as List<String>;
    final packagePath = _checkNotNull(argResults, _packagePathParam);
    final outDir = _checkNotNull(argResults, _outParam);
    final logLevel =
        _optionToLogLevel[_checkNotNull(argResults, _logLevelParam)];

    final logPath = _checkNotNull(argResults, _logPathParam);
    final inputExtension = _checkNotNull(argResults, _inExtension);
    final outputExtensions =
        _checkNotNull(argResults, _outExtension) as List<String>;

    final packageMapPath = _checkNotNull(argResults, _packageMapParam);
    final srcsPath = _checkNotNull(argResults, _srcsParam);
    final help = argResults[_helpParam];
    final useSummaries = argResults[_summariesParam];

    return new Options._(rootDirs, packagePath, outDir, logPath, inputExtension,
        outputExtensions, packageMapPath, srcsPath, help, logLevel,
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

dynamic _checkNotNull(ArgResults results, String param) {
  final val = results[param];
  if (val == null) throw new ArgumentError.notNull(param);
  return val;
}
