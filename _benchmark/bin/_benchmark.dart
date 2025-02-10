// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_benchmark/commands.dart';
import 'package:_benchmark/generators.dart';
import 'package:_benchmark/shape.dart';
import 'package:args/command_runner.dart';

final commandRunner =
    CommandRunner<void>(
        'dart run _benchmark',
        'Benchmarks build_runner performance.',
      )
      ..addCommand(BenchmarkCommand())
      ..addCommand(MeasureCommand())
      ..addCommand(CreateCommand())
      ..argParser.addFlag(
        'allow-failures',
        help: 'Whether to continue benchmarking despite failures.',
      )
      ..argParser.addOption(
        'build-repo-path',
        help: 'Path to build repo to benchmark.',
      )
      ..argParser.addOption(
        'generator',
        help: 'Generator to benchmark.',
        allowed: Generator.values.map((e) => e.packageName).toList(),
        defaultsTo: Generator.builtValue.packageName,
      )
      ..argParser.addOption(
        'root-directory',
        help: 'Root directory for generated source and builds.',
        defaultsTo: '${Directory.systemTemp.path}/build_benchmark',
      )
      ..argParser.addOption(
        'size',
        help:
            'Benchmark size: number of libraries. Omit to run for a range of '
            'sizes.',
      )
      ..argParser.addOption(
        'shape',
        help: 'Shape of the dependency graph. Omit to run for all shapes.',
        allowed: Shape.values.map((e) => e.name).toList(),
      )
      ..argParser.addFlag(
        'use-experimental-resolver',
        help: 'Whether to pass `--use-experimental-resolver` to build_runner.',
      );

Future<void> main(List<String> arguments) async {
  await commandRunner.run(arguments);
}
