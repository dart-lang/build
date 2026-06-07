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
  final bool mostlyNoCodegen;
  final List<bool> webConfigs;
  final List<String> versions;
  final int repetitions;

  Config({
    required this.allowFailures,
    required this.buildRepoPath,
    required this.dependencyOverridePaths,
    required this.generator,
    required this.rootDirectory,
    required this.sizes,
    required this.shapes,
    required this.mostlyNoCodegen,
    required this.webConfigs,
    required this.versions,
    required this.repetitions,
  });

  factory Config.fromArgResults(ArgResults argResults) {
    final buildRepoPath = argResults['build-repo-path'] as String?;
    final versionsInput = argResults['versions'] as String?;
    final List<String> versions;
    if (versionsInput != null) {
      versions = versionsInput.split(',');
    } else {
      versions = buildRepoPath != null ? ['pub', 'local'] : ['pub'];
    }

    final shapes =
        argResults.wasParsed('shape')
            ? [Shape.values.singleWhere((e) => e.name == argResults['shape'])]
            : [Shape.random];

    final sizes =
        argResults.wasParsed('size')
            ? [int.parse(argResults['size'] as String)]
            : [10, 2000];

    final webConfigs =
        argResults.wasParsed('web')
            ? [argResults['web'] as bool]
            : [false, true];

    final repetitions =
        argResults.wasParsed('repetitions')
            ? int.parse(argResults['repetitions'] as String)
            : 5; // Default to 5 repetitions

    return Config(
      allowFailures: argResults['allow-failures'] as bool,
      buildRepoPath: buildRepoPath,
      dependencyOverridePaths: {
        for (final s in argResults['dependency-override-path'] as List<String>)
          s.split('=')[0]: s.split('=')[1],
      },
      generator: Generator.values.singleWhere(
        (e) => e.packageName == argResults['generator'],
      ),
      rootDirectory: Directory(argResults['root-directory'] as String),
      sizes: sizes,
      shapes: shapes,
      mostlyNoCodegen: argResults['mostly-no-codegen'] as bool,
      webConfigs: webConfigs,
      versions: versions,
      repetitions: repetitions,
    );
  }
}

/// Single benchmark run config.
class RunConfig {
  final Config config;
  final int size;
  final Shape shape;

  /// [size] as a padded-to-consistent-width `String`.
  final String paddedSize;

  final Workspace workspace;
  final String version;
  final bool web;

  RunConfig({
    required this.config,
    required this.workspace,
    required this.size,
    required this.paddedSize,
    required this.shape,
    required this.version,
    required this.web,
  });

  String get dependencyOverrides {
    final overrides = StringBuffer();

    final String? buildRepoPath;
    final String? gitRef;

    if (version.startsWith('git:')) {
      buildRepoPath = null;
      gitRef = version.substring(4);
    } else if (version == 'local') {
      buildRepoPath = config.buildRepoPath;
      if (buildRepoPath == null) {
        throw StateError(
          'local version requested but --build-repo-path is not set',
        );
      }
      gitRef = null;
    } else if (version == 'pub') {
      buildRepoPath = null;
      gitRef = null;
    } else {
      // Assume version is a path
      buildRepoPath = version;
      gitRef = null;
    }

    if (buildRepoPath != null) {
      overrides.write('''
  build:
    path: $buildRepoPath/build
  build_config:
    path: $buildRepoPath/build_config
  build_runner:
    path: $buildRepoPath/build_runner
  build_test:
    path: $buildRepoPath/build_test
  build_web_compilers:
    path: $buildRepoPath/builder_pkgs/build_web_compilers
''');
    }

    if (gitRef != null) {
      overrides.write('''
  build:
    git:
      url: https://github.com/dart-lang/build.git
      path: build
      ref: $gitRef
  build_config:
    git:
      url: https://github.com/dart-lang/build.git
      path: build_config
      ref: $gitRef
  build_runner:
    git:
      url: https://github.com/dart-lang/build.git
      path: build_runner
      ref: $gitRef
  build_test:
    git:
      url: https://github.com/dart-lang/build.git
      path: build_test
      ref: $gitRef
  build_web_compilers:
    git:
      url: https://github.com/dart-lang/build.git
      path: builder_pkgs/build_web_compilers
      ref: $gitRef
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
