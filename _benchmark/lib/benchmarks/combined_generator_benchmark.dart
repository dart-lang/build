// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../benchmark.dart';
import '../config.dart';

/// Benchmark that exercises all four generators in every logical library,
/// sharing the `.g.dart` file for `built_value` and `json_serializable`.
class CombinedGeneratorBenchmark implements Benchmark {
  const CombinedGeneratorBenchmark();

  @override
  void create(RunConfig config) {
    final workspace = config.workspace;
    final size = config.size;

    workspace.write(
      'pubspec.yaml',
      source:
          '''
name: ${workspace.name}
publish_to: none

environment:
  sdk: ^3.6.0

dependencies:
  built_value: any
  freezed_annotation: any
  json_annotation: any
  mockito: any

dev_dependencies:
  build_runner: any
  built_value_generator: any
  freezed: any
  json_serializable: any
${config.config.web ? '  build_web_compilers: any' : ''}
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
    if (config.config.web) {
      workspace.writeWebEntrypoint();
    }

    for (var libraryNumber = 0; libraryNumber != size; ++libraryNumber) {
      final libraryName = Benchmarks.libraryName(
        libraryNumber,
        benchmarkSize: size,
      );
      final partName = Benchmarks.partName(libraryNumber, benchmarkSize: size);
      final freezedPartName = partName.replaceAll('.g.dart', '.freezed.dart');

      final importNames = config.shape.importNames(
        libraryNumber,
        benchmarkSize: size,
      );

      // Main library with freezed + json_serializable + built_value + mockito
      // service.
      workspace.write(
        'lib/$libraryName',
        source:
            '''
// ignore_for_file: unused_import
import 'package:built_value/built_value.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

${[for (final importName in importNames) "import '$importName';"].join('\n')}

part '$freezedPartName';
part '$partName';

@freezed
class Value with _\$Value {
  const factory Value({
    String? name,
    int? id,
  }) = _Value;

  factory Value.fromJson(Map<String, dynamic> json) => _\$ValueFromJson(json);
}

abstract class BuiltValue implements Built<BuiltValue, BuiltValueBuilder> {
  BuiltValue._();
  factory BuiltValue([void Function(BuiltValueBuilder) updates]) = _\$BuiltValue;
}

class Service$libraryNumber {
  void doSomething(int value) {}
}
''',
      );

      // Test file with mockito.
      final testName = Benchmarks.testName(libraryNumber, benchmarkSize: size);
      final mockName = testName.replaceAll('.dart', '.mocks.dart');
      workspace.write(
        'test/$testName',
        source:
            '''
// ignore_for_file: unused_import
import 'package:mockito/annotations.dart';
import 'package:${workspace.name}/$libraryName';

@GenerateNiceMocks([
  MockSpec<Service$libraryNumber>(),
])
import '$mockName';

void main() {}
''',
      );
    }
  }
}
