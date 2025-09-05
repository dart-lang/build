// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/experiments.dart';
import 'package:built_collection/built_collection.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:io/io.dart';
import 'package:shelf/shelf_io.dart';

import '../build_script_generate/build_process_state.dart';
import '../logging/build_log.dart';
import '../options/testing_overrides.dart';
import '../package_graph/apply_builders.dart';
import '../package_graph/package_graph.dart';
import 'build_options.dart';
import 'build_runner_command.dart';
import 'serve_options.dart';
import 'watch_command.dart';

class ServeCommand implements BuildRunnerCommand {
  final BuiltList<BuilderApplication> builders;
  final BuildOptions buildOptions;
  final ServeOptions serveOptions;
  final TestingOverrides testingOverrides;

  ServeCommand({
    required this.builders,
    required this.buildOptions,
    required this.serveOptions,
    this.testingOverrides = const TestingOverrides(),
  });

  @override
  Future<int> run() =>
      withEnabledExperiments(_run, buildOptions.enableExperiments.asList());

  Future<int> _run() async {
    buildLog.configuration = buildLog.configuration.rebuild((b) {
      b.mode = BuildLogMode.build;
      b.verbose = buildOptions.verbose;
      b.onLog = testingOverrides.onLog;
    });
    final servers = <ServeTarget, HttpServer>{};
    try {
      try {
        await Future.wait(
          serveOptions.serveTargets.map((target) async {
            servers[target] = await HttpMultiServer.bind(
              serveOptions.hostname,
              target.port,
            );
          }),
        );
      } on SocketException catch (e) {
        if (e.address != null && e.port != null) {
          buildLog.error(
            'Error starting server at ${e.address!.address}:${e.port}, address '
            'is already in use. Please kill the server running on that port or '
            'serve on a different port and restart this process.',
          );
        } else {
          buildLog.error('Error starting server on ${serveOptions.hostname}.');
        }
        return ExitCode.osError.code;
      }

      final handler =
          await WatchCommand(
            builders: builders,
            buildOptions: buildOptions,
            testingOverrides: testingOverrides,
          ).watch();

      servers.forEach((target, server) {
        serveRequests(
          server,
          handler.handlerFor(
            target.dir,
            logRequests: serveOptions.logRequests,
            liveReload: serveOptions.liveReload,
          ),
        );
      });

      // TODO(davidmorgan): reuse package graph.
      _ensureBuildWebCompilersDependency(await PackageGraph.forThisPackage());

      final completer = Completer<int>();
      handleBuildResultsStream(handler.buildResults, completer);
      _logServerPorts();
      await handler.currentBuild;
      return await completer.future;
    } finally {
      await Future.wait(
        servers.values.map((server) => server.close(force: true)),
      );
    }
  }

  void _logServerPorts() async {
    // Warn if in serve mode with no servers.
    if (serveOptions.serveTargets.isEmpty) {
      buildLog.warning(
        'Found no known web directories to serve, but running in `serve` '
        'mode. You may expliclity provide a directory to serve with trailing '
        'args in <dir>[:<port>] format.',
      );
    } else {
      for (final target in serveOptions.serveTargets) {
        buildLog.info(
          'Serving `${target.dir}` on '
          'http://${serveOptions.hostname}:${target.port}',
        );
      }
    }
  }
}

void _ensureBuildWebCompilersDependency(PackageGraph packageGraph) {
  if (!packageGraph.allPackages.containsKey('build_web_compilers')) {
    buildLog.warning('''
    Missing dev dependency on package:build_web_compilers, which is required to serve Dart compiled to JavaScript.

    Please update your dev_dependencies section of your pubspec.yaml:

    dev_dependencies:
      build_runner: any
      build_test: any
      build_web_compilers: any''');
  }
}
