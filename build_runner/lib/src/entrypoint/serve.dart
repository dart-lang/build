// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http_multi_server/http_multi_server.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf_io.dart';

import '../generate/build.dart';
import '../server/server.dart';
import 'options.dart';
import 'watch.dart';

/// Extends [WatchCommand] with dev server functionality.
class ServeCommand extends WatchCommand {
  ServeCommand() {
    argParser
      ..addOption(hostnameOption,
          help: 'Specify the hostname to serve on', defaultsTo: 'localhost')
      ..addFlag(logRequestsOption,
          defaultsTo: false,
          negatable: false,
          help: 'Enables logging for each request to the server.')
      ..addFlag(liveReloadOption,
          defaultsTo: false,
          negatable: false,
          help: 'Enables automatic page reloading on rebuilds.');
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
  ServeOptions readOptions() => new ServeOptions.fromParsedArgs(
      argResults, argResults.rest, packageGraph.root.name, this);

  @override
  Future<int> run() async {
    var options = readOptions();
    var handler = await watch(
      builderApplications,
      deleteFilesByDefault: options.deleteFilesByDefault,
      enableLowResourcesMode: options.enableLowResourcesMode,
      configKey: options.configKey,
      assumeTty: options.assumeTty,
      outputMap: options.outputMap,
      outputSymlinksOnly: options.outputSymlinksOnly,
      packageGraph: packageGraph,
      trackPerformance: options.trackPerformance,
      skipBuildScriptCheck: options.skipBuildScriptCheck,
      verbose: options.verbose,
      builderConfigOverrides: options.builderConfigOverrides,
      isReleaseBuild: options.isReleaseBuild,
      buildDirs: options.buildDirs,
      logPerformanceDir: options.logPerformanceDir,
    );

    if (handler == null) return ExitCode.config.code;

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
        stdout.writeln('Serving `${target.dir}` on '
            'http://${options.hostName}:${target.port}');
      }
    }
    await handler.buildResults.drain();
    await Future.wait(servers.map((server) => server.close()));

    return ExitCode.success.code;
  }
}

Future<HttpServer> _startServer(
    ServeOptions options, ServeTarget target, ServeHandler handler) async {
  var server = await _bindServer(options, target);
  serveRequests(
      server, handler.handlerFor(target.dir, logRequests: options.logRequests));
  return server;
}

Future<HttpServer> _bindServer(ServeOptions options, ServeTarget target) {
  switch (options.hostName) {
    case 'any':
      // Listens on both IPv6 and IPv4
      return HttpServer.bind(InternetAddress.anyIPv6, target.port);
    case 'localhost':
      return HttpMultiServer.loopback(target.port);
    default:
      return HttpServer.bind(options.hostName, target.port);
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
