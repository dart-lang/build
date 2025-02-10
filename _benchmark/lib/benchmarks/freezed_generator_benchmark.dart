// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../benchmark.dart';
import '../config.dart';

/// Benchmark with one trivial `freezed` value type per library.
///
/// There is one large library cycle due to `app.dart` which depends on
/// everything and is depended on by everything.
class FreezedGeneratorBenchmark implements Benchmark {
  const FreezedGeneratorBenchmark();

  @override
  void create(RunConfig config) {
    final workspace = config.workspace;
    final size = config.size;

    // TODO(davidmorgan): add a way to pick `build` and generator versions.
    workspace.write(
      'pubspec.yaml',
      source: '''
name: ${workspace.name}
publish_to: none

environment:
  sdk: ^3.6.0

dependencies:
  freezed_annotation: any

dev_dependencies:
  build_runner: any
  freezed: any

${config.dependencyOverrides}
''',
    );

    workspace.write(
      'lib/app.dart',
      source: '''
/// ignore_for_file: unused_import
/// CACHEBUSTER
''',
    );

    for (var libraryNumber = 0; libraryNumber != size; ++libraryNumber) {
      final libraryName = Benchmarks.libraryName(
        libraryNumber,
        benchmarkSize: size,
      );
      final partName = Benchmarks.partName(
        libraryNumber,
        benchmarkSize: size,
        infix: 'freezed',
      );
      final importNames = config.shape.importNames(
        libraryNumber,
        benchmarkSize: size,
      );
      workspace.write(
        'lib/$libraryName',
        source: '''
// ignore_for_file: unused_import
import 'package:freezed_annotation/freezed_annotation.dart';

${[for (final importName in importNames) "import '$importName';"].join('\n')}

part '$partName';

@freezed
class Value with _\$Value {
  const factory Value() = _Value;
}
''',
      );
    }
  }
}
