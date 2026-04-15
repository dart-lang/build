// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:io/io.dart';
import 'package:path/path.dart' as p;

import '../build_plan/build_paths.dart';
import '../constants.dart';
import 'build_runner_command.dart';

class CleanCommand implements BuildRunnerCommand {
  final BuildPaths buildPaths;

  CleanCommand(this.buildPaths);

  @override
  Future<int> run() async {
    // Delete specific directories and files instead of the whole cache
    // directory, which can't be deleted on Windows due to the open lock file.

    final basePath =
        buildPaths.buildWorkspace
            ? buildPaths.workspacePath!
            : buildPaths.packagePath;

    final entrypointDir = Directory(p.join(basePath, entrypointDirectoryPath));
    if (entrypointDir.existsSync()) {
      entrypointDir.deleteSync(recursive: true);
    }

    final assetGraph = File(p.join(basePath, assetGraphPath));
    if (assetGraph.existsSync()) {
      assetGraph.deleteSync();
    }

    final generatedDir = Directory(p.join(basePath, generatedOutputDirectory));
    if (generatedDir.existsSync()) {
      generatedDir.deleteSync(recursive: true);
    }

    return ExitCode.success.code;
  }
}
