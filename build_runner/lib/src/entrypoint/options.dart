// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:glob/glob.dart';
import 'package:io/io.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf_io.dart';

import 'package:build_runner/build_runner.dart';

const _assumeTty = 'assume-tty';
const _deleteFilesByDefault = 'delete-conflicting-outputs';
const _hostname = 'hostname';

/// Unified command runner for all build_runner commands.
class BuildCommandRunner extends CommandRunner {
  final List<BuilderApplication> builderApplications;

  BuildCommandRunner(List<BuilderApplication> builderApplications)
      : this.builderApplications = new List.unmodifiable(builderApplications),
        super('build_runner', 'Unified interface for running Dart builds.') {
    addCommand(new _BuildCommand());
    addCommand(new _WatchCommand());
    addCommand(new _ServeCommand());
    addCommand(new _TestCommand());
  }
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

  _SharedOptions._(
      {@required this.assumeTty, @required this.deleteFilesByDefault});

  factory _SharedOptions.fromParsedArgs(ArgResults argResults) {
    return new _SharedOptions._(
        assumeTty: argResults[_assumeTty] as bool,
        deleteFilesByDefault: argResults[_deleteFilesByDefault] as bool);
  }
}

/// Options specific to the [_ServeCommand].
class _ServeOptions extends _SharedOptions {
  final String hostName;
  final List<_ServeTarget> serveTargets;

  _ServeOptions._({
    @required this.hostName,
    @required this.serveTargets,
    @required bool assumeTty,
    @required bool deleteFilesByDefault,
  })
      : super._(
            assumeTty: assumeTty, deleteFilesByDefault: deleteFilesByDefault);

  factory _ServeOptions.fromParsedArgs(ArgResults argResults) {
    var serveTargets = <_ServeTarget>[];
    for (var arg in argResults.rest) {
      var parts = arg.split(':');
      var path = parts.first;
      var port = parts.length == 2 ? int.parse(parts[1]) : 8080;
      serveTargets.add(new _ServeTarget(path, port));
    }
    if (serveTargets.isEmpty) {
      serveTargets.addAll([
        new _ServeTarget('web', 8080),
        new _ServeTarget('test', 8081),
      ]);
    }
    return new _ServeOptions._(
        hostName: argResults[_hostname] as String,
        serveTargets: serveTargets,
        assumeTty: argResults[_assumeTty] as bool,
        deleteFilesByDefault: argResults[_deleteFilesByDefault] as bool);
  }
}

/// A target to serve, representing a directory and a port.
class _ServeTarget {
  final String dir;
  final int port;

  _ServeTarget(this.dir, this.port);
}

abstract class _BaseCommand extends Command {
  List<BuilderApplication> get builderApplications =>
      (runner as BuildCommandRunner).builderApplications;

  _BaseCommand() {
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
          defaultsTo: false);
  }

  /// Must be called inside [run] so that [argResults] is non-null.
  ///
  /// You may override this to return more specific options if desired, but they
  /// must extend [_SharedOptions].
  _SharedOptions _readOptions() =>
      new _SharedOptions.fromParsedArgs(argResults);
}

/// A [Command] that does a single build and then exits.
class _BuildCommand extends _BaseCommand {
  @override
  String get name => 'build';

  @override
  String get description =>
      'Performs a single build on the specified targets and then exits.';

  @override
  Future<Null> run() async {
    var options = _readOptions();
    await build(builderApplications,
        deleteFilesByDefault: options.deleteFilesByDefault,
        assumeTty: options.assumeTty);
  }
}

/// A [Command] that watches the file system for updates and rebuilds as
/// appropriate.
class _WatchCommand extends _BaseCommand {
  @override
  String get name => 'watch';

  @override
  String get description =>
      'Builds the specified targets, watching the file system for updates and '
      'rebuilding as appropriate.';

  @override
  Future<Null> run() async {
    var options = _readOptions();
    var handler = await watch(builderApplications,
        deleteFilesByDefault: options.deleteFilesByDefault,
        assumeTty: options.assumeTty);
    await handler.currentBuild;
    await handler.buildResults.drain();
  }
}

/// Extends [_WatchCommand] with dev server functionality.
class _ServeCommand extends _WatchCommand {
  _ServeCommand() {
    argParser
      ..addOption(_hostname,
          help: 'Specify the hostname to serve on', defaultsTo: 'localhost');
  }

  @override
  String get name => 'serve';

  @override
  String get description =>
      'Runs a development server that serves the specified targets and runs '
      'builds based on file system updates.';

  @override
  _ServeOptions _readOptions() => new _ServeOptions.fromParsedArgs(argResults);

  @override
  Future<Null> run() async {
    var options = _readOptions();
    var handler = await watch(builderApplications,
        deleteFilesByDefault: options.deleteFilesByDefault,
        assumeTty: options.assumeTty);
    var servers = await Future.wait(options.serveTargets.map((target) =>
        serve(handler.handlerFor(target.dir), options.hostName, target.port)));
    await handler.currentBuild;
    for (var target in options.serveTargets) {
      stdout.writeln('Serving `${target.dir}` on port ${target.port}');
    }
    await handler.buildResults.drain();
    await Future.wait(servers.map((server) => server.close()));
  }
}

/// A [Command] that does a single build and then runs tests using the compiled
/// assets.
class _TestCommand extends _BaseCommand {
  @override
  final argParser = new ArgParser(allowTrailingOptions: false);

  @override
  String get name => 'test';

  @override
  String get description =>
      'Performs a single build on the specified targets and then runs tests '
      'using the compiled assets.';

  @override
  Future<Null> run() async {
    var options = _readOptions();
    await build(builderApplications,
        deleteFilesByDefault: options.deleteFilesByDefault,
        assumeTty: options.assumeTty);

    // Create the merged output directory.
    String precompiledPath = await _createMergedDir();

    // Create missing *_test.html files.
    await _createMissingHtmlFiles(precompiledPath);

    // Run the tests!
    await _runTests(precompiledPath);

    await ProcessManager.terminateStdIn();
  }

  /// Creates a merged directory for the current build script.
  Future<String> _createMergedDir() async {
    var tmpDir = await Directory.systemTemp.createTemp('build_runner_test');
    var tmpDirPath = tmpDir.absolute.uri.toFilePath();
    var scriptLocation = Platform.script.path;
    var process = await new ProcessManager().spawn('pub', [
      'run',
      'build_runner:create_merged_dir',
      '--script',
      scriptLocation,
      '--output-dir',
      tmpDirPath,
    ]);

    var processExitCode = await process.exitCode;
    if (processExitCode != 0) {
      print('Error creating merged dir! :(');
      exit(processExitCode);
    }
    return tmpDirPath;
  }

  /// Creates html files for tests in [tmpDirPath] that are missing them.
  Future<Null> _createMissingHtmlFiles(String tmpDirPath) async {
    var dartBrowserTestSuffix = '_test.dart.browser_test.dart';
    var htmlTestSuffix = '_test.html';
    var dartFiles =
        new Glob('test/**$dartBrowserTestSuffix').list(root: tmpDirPath);
    await for (var file in dartFiles) {
      var dartPath = p.relative(file.path, from: tmpDirPath);
      var htmlPath = dartPath.substring(
              0, dartPath.length - dartBrowserTestSuffix.length) +
          htmlTestSuffix;
      var htmlFile = new File(p.join(tmpDirPath, htmlPath));
      if (!await htmlFile.exists()) {
        var originalDartPath = p.basename(dartPath.substring(
            0, dartPath.length - '.browser_test.dart'.length));
        await htmlFile.writeAsString('''
<!DOCTYPE html>
<html>
<head>
  <title>${HTML_ESCAPE.convert(htmlPath)} Test</title>
  <link rel="x-dart-test"
        href="${HTML_ESCAPE.convert(originalDartPath)}">
  <script src="packages/test/dart.js"></script>
</head>
</html>''');
      }
    }
  }

  /// Runs tests using [precompiledPath] as the precompiled test directory.
  Future<Null> _runTests(String precompiledPath) async {
    var extraTestArgs = argResults.rest;
    var testProcess = await new ProcessManager().spawn(
        'pub',
        [
          'run',
          'test',
          '--precompiled',
          precompiledPath,
        ]..addAll(extraTestArgs));
    var testExitCode = await testProcess.exitCode;
    if (testExitCode != 0) {
      // No need to log - should see failed tests in the console.
      exit(testExitCode);
    }
  }
}
