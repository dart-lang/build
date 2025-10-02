// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  test('without caching writes are immediate', () async {
    final readerWriter = TestReaderWriter(rootPackage: 'a');
    final result = await testBuilder(
      TestBuilder(
        check: (_) async {
          expect(readerWriter.testing.assets, [
            AssetId('a', 'lib/a.dart'),
            AssetId('a', '.dart_tool/build/generated/a/lib/a.g.dart'),
          ]);
        },
      ),
      {'a|lib/a.dart': ''},
      readerWriter: readerWriter,
      enableLowResourceMode: true,
    );
    expect(result.succeeded, true);
  });

  test('with caching writes wait until build completion', () async {
    final readerWriter = TestReaderWriter(rootPackage: 'a');
    final result = await testBuilder(
      TestBuilder(
        check: (_) async {
          expect(readerWriter.testing.assets, [AssetId('a', 'lib/a.dart')]);
        },
      ),
      {'a|lib/a.dart': ''},
      readerWriter: readerWriter,
      enableLowResourceMode: false,
    );
    expect(result.succeeded, true);
    expect(
      readerWriter.testing.assets,
      containsAll([
        AssetId('a', 'lib/a.dart'),
        AssetId('a', '.dart_tool/build/generated/a/lib/a.g.dart'),
      ]),
    );
  });

  test('with caching writes are readable before fully written', () async {
    final readerWriter = TestReaderWriter(rootPackage: 'a');
    final result = await testBuilder(
      TestBuilder(
        check: (buildStep) async {
          expect(
            await buildStep.readAsString(AssetId('a', 'lib/a.g.dart')),
            'someoutput',
          );
          expect(readerWriter.testing.assets, [AssetId('a', 'lib/a.dart')]);
        },
      ),
      {'a|lib/a.dart': ''},
      readerWriter: readerWriter,
      enableLowResourceMode: false,
    );
    expect(result.succeeded, true);
  });
}

/// Writes output, runs `check`.
class TestBuilder implements Builder {
  final Future<void> Function(BuildStep buildStep) check;
  TestBuilder({required this.check});

  @override
  Future<void> build(BuildStep buildStep) async {
    final outputId = buildStep.inputId.changeExtension('.g.dart');
    await buildStep.writeAsString(outputId, 'someoutput');
    await check(buildStep);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.g.dart'],
  };
}
