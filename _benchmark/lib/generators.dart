// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'benchmark.dart';
import 'benchmarks/built_value_generator_benchmark.dart';
import 'benchmarks/freezed_generator_benchmark.dart';
import 'benchmarks/json_serializable_generator_benchmark.dart';
import 'benchmarks/mockito_generator_benchmark.dart';

/// A code generator for benchmarking.
enum Generator {
  builtValue(
    packageName: 'built_value',
    benchmark: BuiltValueGeneratorBenchmark(),
  ),
  freezed(packageName: 'freezed', benchmark: FreezedGeneratorBenchmark()),
  jsonSerializable(
    packageName: 'json_serializable',
    benchmark: JsonSerializableGeneratorBenchmark(),
  ),
  mockito(packageName: 'mockito', benchmark: MockitoGeneratorBenchmark());

  final String packageName;
  final Benchmark benchmark;

  const Generator({required this.packageName, required this.benchmark});
}
