// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build_runner/src/bootstrap/build_process_state.dart';
import 'package:build_runner/src/build_plan/build_paths.dart';
import 'package:build_runner/src/build_runner.dart';
import 'package:path/path.dart' as p;

import '../test_builders.dart';

Future<void> main(List<String> arguments) async {
  var dir = Directory.current;
  while (!File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  final isWorkspace = arguments.contains('--workspace');
  final buildPaths = BuildPaths.load(dir.path, buildWorkspace: isWorkspace);

  buildProcessState.deserializeAndSet(
    json.encode({
      'packageConfigUri': Uri.file(
        p.join(
          buildPaths.workspacePath ?? buildPaths.packagePath,
          '.dart_tool',
          'package_config.json',
        ),
      ).toString(),
    }),
  );

  final isDaemon = arguments.contains('daemon');
  if (!isDaemon) {
    await buildProcessState.takeLock(buildPaths);
  }

  final builderFactories = await createWorkspaceTestBuilderFactories(arguments);
  final code = await BuildRunner(
    arguments: arguments,
    builderFactories: builderFactories,
  ).run();
  await stdout.flush();
  await stderr.flush();
  exit(code);
}
