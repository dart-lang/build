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
  final Generator generator;
  final List<Shape> shapes;
  final Directory rootDirectory;
  final List<int> sizes;
  final bool useExperimentalResolver;
  final bool allowFailures;

  Config({
    required this.allowFailures,
    required this.buildRepoPath,
    required this.generator,
    required this.rootDirectory,
    required this.sizes,
    required this.shapes,
    required this.useExperimentalResolver,
  });

  factory Config.fromArgResults(ArgResults argResults) => Config(
    allowFailures: argResults['allow-failures'] as bool,
    buildRepoPath: argResults['build-repo-path'] as String?,
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
    useExperimentalResolver: argResults['use-experimental-resolver'] as bool,
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
    final buildRepoPath = config.buildRepoPath;
    if (buildRepoPath == null) return '';

    return '''
dependency_overrides:
  build:
    path: $buildRepoPath/build
  build_config:
    path: $buildRepoPath/build_config
  build_modules:
    path: $buildRepoPath/build_modules
  build_resolvers:
    path: $buildRepoPath/build_resolvers
  build_runner:
    path: $buildRepoPath/build_runner
  build_runner_core:
    path: $buildRepoPath/build_runner_core
  build_test:
    path: $buildRepoPath/build_test
  build_web_compilers:
    path: $buildRepoPath/build_web_compilers
''';
  }
}
