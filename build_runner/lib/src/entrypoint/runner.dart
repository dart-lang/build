// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';

import 'build.dart';
import 'clean.dart';
import 'run_script.dart';
import 'serve.dart';
import 'test.dart';
import 'watch.dart';

/// Unified command runner for all build_runner commands.
class BuildCommandRunner extends CommandRunner<int> {
  final List<BuilderApplication> builderApplications;

  final packageGraph = new PackageGraph.forThisPackage();

  BuildCommandRunner(List<BuilderApplication> builderApplications)
      : this.builderApplications = new List.unmodifiable(builderApplications),
        super('build_runner', 'Unified interface for running Dart builds.') {
    addCommand(new BuildCommand());
    addCommand(new WatchCommand());
    addCommand(new ServeCommand());
    addCommand(new TestCommand());
    addCommand(new CleanCommand());
    addCommand(new RunCommand());
  }

  // CommandRunner._usageWithoutDescription is private – this is a reasonable
  // facsimile.
  /// Returns [usage] with [description] removed from the beginning.
  String get usageWithoutDescription => LineSplitter.split(usage)
      .skipWhile((line) => line == description || line.isEmpty)
      .join('\n');
}
