// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_benchmark/commands.dart';
import 'package:_benchmark/generators.dart';
import 'package:args/command_runner.dart';

final commandRunner =
    CommandRunner<void>(
        'dart run _benchmark',
        'Benchmarks build_runner performance.',
      )
      ..addCommand(BenchmarkCommand())
      ..addCommand(MeasureCommand())
      ..addCommand(CreateCommand())
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
      );

Future<void> main(List<String> arguments) async {
  await commandRunner.run(arguments);
}
