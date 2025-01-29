// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

import 'generators.dart';
import 'workspace.dart';

/// Benchmark tool config.
class Config {
  final Generator generator;
  final Directory rootDirectory;
  final List<int> sizes = const [1, 100, 250, 500, 750, 1000];

  Config({required this.generator, required this.rootDirectory});

  factory Config.fromArgResults(ArgResults argResults) => Config(
    generator: Generator.values.singleWhere(
      (e) => e.packageName == argResults['generator'],
    ),
    rootDirectory: Directory(argResults['root-directory'] as String),
  );
}

/// Single benchmark run config.
class RunConfig {
  final Config config;
  final int size;

  /// [size] as a padded-to-consistent-width `String`.
  final String paddedSize;

  final Workspace workspace;

  RunConfig({
    required this.config,
    required this.workspace,
    required this.size,
    required this.paddedSize,
  });
}
