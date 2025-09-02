// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

import 'generators.dart';
import 'shape.dart';
import 'workspace.dart';

/// Benchmark tool config.
class Config {
  final String? buildRepoPath;
  final Map<String, String> dependencyOverridePaths;
  final Generator generator;
  final List<Shape> shapes;
  final Directory rootDirectory;
  final List<int> sizes;
  final bool allowFailures;
  bool mostlyNoCodegen;

  Config({
    required this.allowFailures,
    required this.buildRepoPath,
    required this.dependencyOverridePaths,
    required this.generator,
    required this.rootDirectory,
    required this.sizes,
    required this.shapes,
    required this.mostlyNoCodegen,
  });

  factory Config.fromArgResults(ArgResults argResults) => Config(
    allowFailures: argResults['allow-failures'] as bool,
    buildRepoPath: argResults['build-repo-path'] as String?,
    dependencyOverridePaths: {
      for (var s in argResults['dependency-override-path'] as List<String>)
        s.split('=')[0]: s.split('=')[1],
    },
    generator: Generator.values.singleWhere(
      (e) => e.packageName == argResults['generator'],
    ),
    rootDirectory: Directory(argResults['root-directory'] as String),
    sizes:
        argResults['size'] == null
            ? [1, 100, 250, 500, 750, 1000]
            : [int.parse(argResults['size'] as String)],
    shapes:
        argResults['shape'] == null
            ? Shape.values
            : [Shape.values.singleWhere((e) => e.name == argResults['shape'])],
    mostlyNoCodegen: argResults['mostly-no-codegen'] as bool,
  );
}

/// Single benchmark run config.
class RunConfig {
  final Config config;
  final int size;
  final Shape shape;

  /// [size] as a padded-to-consistent-width `String`.
  final String paddedSize;

  final Workspace workspace;

  RunConfig({
    required this.config,
    required this.workspace,
    required this.size,
    required this.paddedSize,
    required this.shape,
  });

  String get dependencyOverrides {
    final overrides = StringBuffer();

    final buildRepoPath = config.buildRepoPath;
    if (buildRepoPath != null) {
      overrides.write('''
  build:
    path: $buildRepoPath/build
  build_config:
    path: $buildRepoPath/build_config
  build_modules:
    path: $buildRepoPath/build_modules
  build_runner:
    path: $buildRepoPath/build_runner
  build_runner_core:
    path: $buildRepoPath/build_runner_core
  build_test:
    path: $buildRepoPath/build_test
  build_web_compilers:
    path: $buildRepoPath/build_web_compilers
''');
    }

    for (final entry in config.dependencyOverridePaths.entries) {
      overrides.write('''
  ${entry.key}:
    path: ${entry.value}
''');
    }

    return overrides.isEmpty
        ? ''
        : '''
dependency_overrides:
$overrides
''';
  }
}
