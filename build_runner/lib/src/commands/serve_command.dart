// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/experiments.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:io/io.dart';
import 'package:shelf/shelf_io.dart';

import '../bootstrap/build_process_state.dart';
import '../build_plan/build_options.dart';
import '../build_plan/build_packages.dart';
import '../build_plan/builder_factories.dart';
import '../build_plan/testing_overrides.dart';
import '../logging/build_log.dart';
import 'build_runner_command.dart';
import 'serve/server.dart';
import 'serve_options.dart';
import 'watch_command.dart';

class ServeCommand implements BuildRunnerCommand {
  final BuilderFactories builderFactories;
  final BuildOptions buildOptions;
  final ServeOptions serveOptions;
  final TestingOverrides testingOverrides;

  ServeCommand({
    required this.builderFactories,
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
            'Failed to start server on ${e.address!.address}:${e.port}, '
            'address in use.',
          );
        } else {
          buildLog.error('Error starting server on ${serveOptions.hostname}.');
        }
        return ExitCode.osError.code;
      }

      final watcher =
          await WatchCommand(
            builderFactories: builderFactories,
            buildOptions: buildOptions,
            testingOverrides: testingOverrides,
          ).watch();
      if (watcher == null) return ExitCode.tempFail.code;
      final handler = ServeHandler(watcher);

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
      _ensureBuildWebCompilersDependency(await BuildPackages.forThisPackage());

      final completer = Completer<int>();
      handleBuildResultsStream(watcher.buildResults, completer);

      if (serveOptions.serveTargets.isEmpty) {
        buildLog.warning('Nothing to serve.');
      } else {
        for (final target in serveOptions.serveTargets) {
          final port = servers[target]!.port;
          buildLog.info(
            'Serving `${target.dir}` on http://${serveOptions.hostname}:$port',
          );
        }
      }

      await watcher.currentBuildResult;
      return await completer.future;
    } finally {
      await Future.wait(
        servers.values.map((server) => server.close(force: true)),
      );
    }
  }
}

void _ensureBuildWebCompilersDependency(BuildPackages buildPackages) {
  if (!buildPackages.packages.containsKey('build_web_compilers')) {
    buildLog.warning('''
Missing dev dependency on package:build_web_compilers, which is required to serve Dart compiled to JavaScript.

Please update your dev_dependencies section of your pubspec.yaml:

dev_dependencies:
  build_runner: any
  build_test: any
  build_web_compilers: any''');
  }
}
