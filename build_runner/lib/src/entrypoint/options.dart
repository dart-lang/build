// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:build_config/build_config.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf_io.dart';

import 'package:build_runner/build_runner.dart';

const _assumeTty = 'assume-tty';
const _define = 'define';
const _deleteFilesByDefault = 'delete-conflicting-outputs';
const _logRequests = 'log-requests';
const _lowResourcesMode = 'low-resources-mode';
const _failOnSevere = 'fail-on-severe';
const _hostname = 'hostname';
const _output = 'output';
const _config = 'config';
const _verbose = 'verbose';
const _trackPerformance = 'track-performance';

final _pubBinary = Platform.isWindows ? 'pub.bat' : 'pub';

final _defaultWebDirs = const ['web', 'test', 'example', 'benchmark'];

/// Unified command runner for all build_runner commands.
class BuildCommandRunner extends CommandRunner<int> {
  final List<BuilderApplication> builderApplications;

  final packageGraph = new PackageGraph.forThisPackage();

  BuildCommandRunner(List<BuilderApplication> builderApplications)
      : this.builderApplications = new List.unmodifiable(builderApplications),
        super('build_runner', 'Unified interface for running Dart builds.') {
    addCommand(new _BuildCommand());
    addCommand(new _WatchCommand());
    addCommand(new _ServeCommand());
    addCommand(new _TestCommand());
  }

  // CommandRunner._usageWithoutDescription is private – this is a reasonable
  // facsimile.
  /// Returns [usage] with [description] removed from the beginning.
  String get usageWithoutDescription => LineSplitter
      .split(usage)
      .skipWhile((line) => line == description || line.isEmpty)
      .join('\n');
}

/// Returns a map of output directory to root input directory to be used
/// for merging.
///
/// Each output option is split on `:` where the first value is the
/// root input directory and the second value output directory.
/// If no delimeter is provided the root input directory will be null.
Map<String, String> _parseOuputMap(ArgResults argResults) {
  var outputs = argResults[_output] as List<String>;
  if (outputs == null) return null;
  var result = <String, String>{};
  for (var option in argResults[_output] as List<String>) {
    var split = option.split(':');
    if (split.length == 1) {
      var output = split.first;
      result[output] = null;
    } else if (split.length == 2) {
      var output = split.last;
      var root = split.first;
      if (root.contains('/')) {
        throw 'Input root can not be nested: $option';
      }
      result[output] = split.first;
    } else {
      throw 'Invalid option for output: $option';
    }
  }
  return result;
}

/// Base options that are shared among all commands.
class _SharedOptions {
  /// Skip the `stdioType()` check and assume the output is going to a terminal
  /// and that we can accept input on stdin.
  final bool assumeTty;

  /// By default, the user will be prompted to delete any files which already
  /// exist but were not generated by this specific build script.
  ///
  /// This option can be set to `true` to skip this prompt.
  final bool deleteFilesByDefault;

  /// Any log of type `SEVERE` should fail the current build.
  final bool failOnSevere;

  final bool enableLowResourcesMode;

  /// Read `build.$configKey.yaml` instead of `build.yaml`.
  final String configKey;

  /// A mapping of output paths to root input directory.
  ///
  /// If null, no directory will be created.
  final Map<String, String> outputMap;

  /// Enables performance tracking and the `/$perf` page.
  final bool trackPerformance;

  final bool verbose;

  // Global config overrides by builder.
  //
  // Keys are the builder keys, such as my_package|my_builder, and values
  // represent config objects. All keys in the config will override the parsed
  // config for that key.
  final Map<String, Map<String, dynamic>> builderConfigOverrides;

  _SharedOptions._({
    @required this.assumeTty,
    @required this.deleteFilesByDefault,
    @required this.failOnSevere,
    @required this.enableLowResourcesMode,
    @required this.configKey,
    @required this.outputMap,
    @required this.trackPerformance,
    @required this.verbose,
    @required this.builderConfigOverrides,
  });

  factory _SharedOptions.fromParsedArgs(
      ArgResults argResults, String rootPackage) {
    return new _SharedOptions._(
      assumeTty: argResults[_assumeTty] as bool,
      deleteFilesByDefault: argResults[_deleteFilesByDefault] as bool,
      failOnSevere: argResults[_failOnSevere] as bool,
      enableLowResourcesMode: argResults[_lowResourcesMode] as bool,
      configKey: argResults[_config] as String,
      outputMap: _parseOuputMap(argResults),
      trackPerformance: argResults[_trackPerformance] as bool,
      verbose: argResults[_verbose] as bool,
      builderConfigOverrides:
          _parseBuilderConfigOverrides(argResults[_define], rootPackage),
    );
  }
}

/// Options specific to the [_ServeCommand].
class _ServeOptions extends _SharedOptions {
  final String hostName;
  final bool logRequests;
  final List<_ServeTarget> serveTargets;

  _ServeOptions._({
    @required this.hostName,
    @required this.logRequests,
    @required this.serveTargets,
    @required bool assumeTty,
    @required bool deleteFilesByDefault,
    @required bool failOnSevere,
    @required bool enableLowResourcesMode,
    @required String configKey,
    @required Map<String, String> outputMap,
    @required bool trackPerformance,
    @required bool verbose,
    @required Map<String, Map<String, dynamic>> builderConfigOverrides,
  }) : super._(
          assumeTty: assumeTty,
          deleteFilesByDefault: deleteFilesByDefault,
          failOnSevere: failOnSevere,
          enableLowResourcesMode: enableLowResourcesMode,
          configKey: configKey,
          outputMap: outputMap,
          trackPerformance: trackPerformance,
          verbose: verbose,
          builderConfigOverrides: builderConfigOverrides,
        );

  factory _ServeOptions.fromParsedArgs(
      ArgResults argResults, String rootPackage) {
    var serveTargets = <_ServeTarget>[];
    var nextDefaultPort = 8080;
    for (var arg in argResults.rest) {
      var parts = arg.split(':');
      var path = parts.first;
      var port = parts.length == 2 ? int.parse(parts[1]) : nextDefaultPort++;
      serveTargets.add(new _ServeTarget(path, port));
    }
    if (serveTargets.isEmpty) {
      for (var dir in _defaultWebDirs) {
        if (new Directory(dir).existsSync()) {
          serveTargets.add(new _ServeTarget(dir, nextDefaultPort++));
        }
      }
    }
    return new _ServeOptions._(
      hostName: argResults[_hostname] as String,
      logRequests: argResults[_logRequests] as bool,
      serveTargets: serveTargets,
      assumeTty: argResults[_assumeTty] as bool,
      deleteFilesByDefault: argResults[_deleteFilesByDefault] as bool,
      failOnSevere: argResults[_failOnSevere] as bool,
      enableLowResourcesMode: argResults[_lowResourcesMode] as bool,
      configKey: argResults[_config] as String,
      outputMap: _parseOuputMap(argResults),
      trackPerformance: argResults[_trackPerformance] as bool,
      verbose: argResults[_verbose] as bool,
      builderConfigOverrides:
          _parseBuilderConfigOverrides(argResults[_define], rootPackage),
    );
  }
}

/// A target to serve, representing a directory and a port.
class _ServeTarget {
  final String dir;
  final int port;

  _ServeTarget(this.dir, this.port);
}

abstract class BuildRunnerCommand extends Command<int> {
  List<BuilderApplication> get builderApplications =>
      (runner as BuildCommandRunner).builderApplications;

  PackageGraph get packageGraph => (runner as BuildCommandRunner).packageGraph;

  BuildRunnerCommand() {
    _addBaseFlags();
  }

  void _addBaseFlags() {
    argParser
      ..addFlag(_assumeTty,
          help: 'Enables colors and interactive input when the script does not'
              ' appear to be running directly in a terminal, for instance when it'
              ' is a subprocess',
          negatable: true)
      ..addFlag(_deleteFilesByDefault,
          help:
              'By default, the user will be prompted to delete any files which '
              'already exist but were not known to be generated by this '
              'specific build script.\n\n'
              'Enabling this option skips the prompt and deletes the files. '
              'This should typically be used in continues integration servers '
              'and tests, but not otherwise.',
          negatable: false,
          defaultsTo: false)
      ..addFlag(_lowResourcesMode,
          help: 'Reduce the amount of memory consumed by the build process. '
              'This will slow down builds but allow them to progress in '
              'resource constrained environments.',
          negatable: false,
          defaultsTo: false)
      ..addOption(_config,
          help: 'Read `build.<name>.yaml` instead of the default `build.yaml`',
          abbr: 'c')
      ..addFlag(_failOnSevere,
          help: 'Whether to consider the build a failure on an error logged.',
          negatable: true,
          defaultsTo: false)
      ..addFlag(_trackPerformance,
          help: r'Enables performance tracking and the /$perf page.',
          negatable: true,
          defaultsTo: false)
      ..addMultiOption(_output,
          help: 'A directory to write the result of a build to.', abbr: 'o')
      ..addFlag('verbose',
          abbr: 'v',
          defaultsTo: false,
          negatable: false,
          help: 'Enables verbose logging.')
      ..addMultiOption(_define,
          splitCommas: false,
          help: 'Sets the global `options` config for a builder by key.');
  }

  /// Must be called inside [run] so that [argResults] is non-null.
  ///
  /// You may override this to return more specific options if desired, but they
  /// must extend [_SharedOptions].
  _SharedOptions _readOptions() =>
      new _SharedOptions.fromParsedArgs(argResults, packageGraph.root.name);
}

/// A [Command] that does a single build and then exits.
class _BuildCommand extends BuildRunnerCommand {
  @override
  String get name => 'build';

  @override
  String get description =>
      'Performs a single build on the specified targets and then exits.';

  @override
  Future<int> run() async {
    var options = _readOptions();
    var result = await build(builderApplications,
        deleteFilesByDefault: options.deleteFilesByDefault,
        enableLowResourcesMode: options.enableLowResourcesMode,
        failOnSevere: options.failOnSevere,
        configKey: options.configKey,
        assumeTty: options.assumeTty,
        outputMap: options.outputMap,
        packageGraph: packageGraph,
        verbose: options.verbose,
        builderConfigOverrides: options.builderConfigOverrides);
    if (result.status == BuildStatus.success) {
      return ExitCode.success.code;
    } else {
      return 1;
    }
  }
}

/// A [Command] that watches the file system for updates and rebuilds as
/// appropriate.
class _WatchCommand extends BuildRunnerCommand {
  @override
  String get name => 'watch';

  @override
  String get description =>
      'Builds the specified targets, watching the file system for updates and '
      'rebuilding as appropriate.';

  @override
  Future<int> run() async {
    var options = _readOptions();
    var handler = await watch(builderApplications,
        deleteFilesByDefault: options.deleteFilesByDefault,
        enableLowResourcesMode: options.enableLowResourcesMode,
        failOnSevere: options.failOnSevere,
        configKey: options.configKey,
        assumeTty: options.assumeTty,
        outputMap: options.outputMap,
        packageGraph: packageGraph,
        trackPerformance: options.trackPerformance,
        verbose: options.verbose,
        builderConfigOverrides: options.builderConfigOverrides);
    await handler.currentBuild;
    await handler.buildResults.drain();
    return ExitCode.success.code;
  }
}

/// Extends [_WatchCommand] with dev server functionality.
class _ServeCommand extends _WatchCommand {
  _ServeCommand() {
    argParser
      ..addOption(_hostname,
          help: 'Specify the hostname to serve on', defaultsTo: 'localhost')
      ..addFlag(_logRequests,
          defaultsTo: false,
          negatable: false,
          help: 'Enables logging for each request to the server.');
  }

  @override
  String get invocation => '${super.invocation} [<directory>[:<port>]]...';

  @override
  String get name => 'serve';

  @override
  String get description =>
      'Runs a development server that serves the specified targets and runs '
      'builds based on file system updates.';

  @override
  _ServeOptions _readOptions() =>
      new _ServeOptions.fromParsedArgs(argResults, packageGraph.root.name);

  @override
  Future<int> run() async {
    var options = _readOptions();
    var logger = new Logger('Serve');
    var handler = await watch(builderApplications,
        deleteFilesByDefault: options.deleteFilesByDefault,
        enableLowResourcesMode: options.enableLowResourcesMode,
        failOnSevere: options.failOnSevere,
        configKey: options.configKey,
        assumeTty: options.assumeTty,
        outputMap: options.outputMap,
        packageGraph: packageGraph,
        trackPerformance: options.trackPerformance,
        verbose: options.verbose,
        builderConfigOverrides: options.builderConfigOverrides);
    _ensureBuildWebCompilersDependency(packageGraph, logger);
    var servers = await Future.wait(options.serveTargets
        .map((target) => _startServer(options, target, handler)));
    await handler.currentBuild;
    // Warn if in serve mode with no servers.
    if (options.serveTargets.isEmpty) {
      logger.warning(
          'Found no known web directories to serve, but running in `serve` '
          'mode. You may expliclity provide a directory to serve with trailing '
          'args in <dir>[:<port>] format.');
    } else {
      for (var target in options.serveTargets) {
        stdout.writeln(
            'Serving `${target.dir}` on http://${options.hostName}:${target.port}');
      }
    }
    await handler.buildResults.drain();
    await Future.wait(servers.map((server) => server.close()));

    return ExitCode.success.code;
  }
}

Future<HttpServer> _startServer(
    _ServeOptions options, _ServeTarget target, ServeHandler handler) async {
  var server = await _bindServer(options, target);
  serveRequests(
      server, handler.handlerFor(target.dir, logRequests: options.logRequests));
  return server;
}

Future<HttpServer> _bindServer(_ServeOptions options, _ServeTarget target) {
  switch (options.hostName) {
    case 'any':
      // Listens on both IPv6 and IPv4
      return HttpServer.bind(InternetAddress.ANY_IP_V6, target.port);
    case 'localhost':
      return HttpMultiServer.loopback(target.port);
    default:
      return HttpServer.bind(options.hostName, target.port);
  }
}

/// A [Command] that does a single build and then runs tests using the compiled
/// assets.
class _TestCommand extends BuildRunnerCommand {
  @override
  final argParser = new ArgParser(allowTrailingOptions: false);

  @override
  String get name => 'test';

  @override
  String get description =>
      'Performs a single build on the specified targets and then runs tests '
      'using the compiled assets.';

  @override
  Future<int> run() async {
    _SharedOptions options;
    // We always run our tests in a temp dir.
    var tempPath = Directory.systemTemp
        .createTempSync('build_runner_test')
        .absolute
        .uri
        .toFilePath();
    try {
      _ensureBuildTestDependency(packageGraph);
      options = _readOptions();
      var outputMap = options.outputMap ?? {};
      outputMap.addAll({tempPath: null});
      var result = await build(builderApplications,
          deleteFilesByDefault: options.deleteFilesByDefault,
          enableLowResourcesMode: options.enableLowResourcesMode,
          failOnSevere: options.failOnSevere,
          configKey: options.configKey,
          assumeTty: options.assumeTty,
          outputMap: outputMap,
          packageGraph: packageGraph,
          trackPerformance: options.trackPerformance,
          verbose: options.verbose,
          builderConfigOverrides: options.builderConfigOverrides);

      if (result.status == BuildStatus.failure) {
        stdout.writeln('Skipping tests due to build failure');
        return 1;
      }

      var testExitCode = await _runTests(tempPath);
      if (testExitCode != 0) {
        // No need to log - should see failed tests in the console.
        exitCode = testExitCode;
      }
      return testExitCode;
    } on BuildTestDependencyError catch (e) {
      stdout.writeln(e);
      return ExitCode.config.code;
    } finally {
      // Clean up the output dir.
      await new Directory(tempPath).delete(recursive: true);
    }
  }

  /// Runs tests using [precompiledPath] as the precompiled test directory.
  Future<int> _runTests(String precompiledPath) async {
    stdout.writeln('Running tests...\n');
    var extraTestArgs = argResults.rest;
    var testProcess = await Process.start(
        _pubBinary,
        [
          'run',
          'test',
          '--precompiled',
          precompiledPath,
        ]..addAll(extraTestArgs),
        mode: ProcessStartMode.INHERIT_STDIO);
    return testProcess.exitCode;
  }
}

void _ensureBuildTestDependency(PackageGraph packageGraph) {
  if (!packageGraph.allPackages.containsKey('build_test')) {
    throw new BuildTestDependencyError();
  }
}

void _ensureBuildWebCompilersDependency(PackageGraph packageGraph, Logger log) {
  if (!packageGraph.allPackages.containsKey('build_web_compilers')) {
    log.warning('''
    Missing dev dependency on package:build_web_compilers, which is required to serve Dart compiled to JavaScript.

    Please update your dev_dependencies section of your pubspec.yaml:

    dev_dependencies:
      build_runner: any
      build_test: any
      build_web_compilers: any''');
  }
}

Map<String, Map<String, dynamic>> _parseBuilderConfigOverrides(
    dynamic parsedArg, String rootPackage) {
  final builderConfigOverrides = <String, Map<String, dynamic>>{};
  if (parsedArg == null) return builderConfigOverrides;
  var allArgs = parsedArg is List<String> ? parsedArg : [parsedArg as String];
  for (final define in allArgs) {
    final parts = define.split('=');
    const expectedFormat = '--define "<builder_key>=<option>=<value>"';
    if (parts.length < 3) {
      throw new ArgumentError.value(
          define,
          _define,
          'Expected at least 2 `=` signs, should be of the format like '
          '$expectedFormat');
    } else if (parts.length > 3) {
      var rest = parts.sublist(2);
      parts.removeRange(2, parts.length);
      parts.add(rest.join('='));
    }
    final builderKey = normalizeBuilderKeyUsage(parts[0], rootPackage);
    final option = parts[1];
    dynamic value;
    // Attempt to parse the value as JSON, and if that fails then treat it as
    // a normal string.
    try {
      value = json.decode(parts[2]);
    } on FormatException catch (_) {
      value = parts[2];
    }
    final config = builderConfigOverrides.putIfAbsent(
        builderKey, () => <String, dynamic>{});
    if (config.containsKey(option)) {
      throw new ArgumentError(
          'Got duplicate overrides for the same builder option: '
          '$builderKey=$option. Only one is allowed.');
    }
    config[option] = value;
  }
  return builderConfigOverrides;
}

class BuildTestDependencyError extends StateError {
  BuildTestDependencyError() : super('''
Missing dev dependency on package:build_test, which is required to run tests.

Please update your dev_dependencies section of your pubspec.yaml:

  dev_dependencies:
    build_runner: any
    build_test: any
    # If you need to run web tests, you will also need this dependency.
    build_web_compilers: any
''');
}
