// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@Timeout.factor(4)
library;

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../common/descriptors.dart';
import '../common/sdk.dart';

void main() {
  group('validation', () {
    setUpAll(() async {
      await d.dir('a', [
        await pubspec(
          'a',
          currentIsolateDependencies: [
            'build',
            'build_config',
            'build_daemon',
            'build_runner',
            'code_builder',
          ],
        ),
      ]).create();
      await runPub('a', 'get');
    });

    group('of builder imports', () {
      test('support package relative imports', () async {
        await d.dir('a', [
          d.file('build.yaml', '''
builders:
  fake:
    import: "tool/builder.dart"
    builder_factories: ["myFactory"]
    build_extensions: {"foo": ["bar"]}
'''),
        ]).create();

        final result = await runPub(
          'a',
          'run',
          args: ['build_runner', 'build'],
        );
        expect(result.stderr, isEmpty);
        await d.dir('a', [
          d.dir('.dart_tool', [
            d.dir('build', [
              d.dir('entrypoint', [
                d.file(
                  'build.dart',
                  contains("import '../../../tool/builder.dart'"),
                ),
              ]),
            ]),
          ]),
        ]).validate();
      });

      test('warns for builder config that leaves unparseable Dart', () async {
        await d.dir('a', [
          d.file('build.yaml', '''
builders:
  fake:
    import: "tool/builder.dart"
    builder_factories: ["not an identifier"]
    build_extensions: {"foo": ["bar"]}
'''),
        ]).create();
        final result = await runPub(
          'a',
          'run',
          args: ['build_runner', 'build'],
        );
        expect(result.stderr, isEmpty);
        expect(result.stdout, contains('could not be parsed'));
      });
    });

    test('checks builder keys in global_options', () async {
      await d.dir('a', [
        d.file('build.yaml', '''
global_options:
  a:a:
    runs_before:
      - b:b
'''),
      ]).create();

      final result = await runPub('a', 'run', args: ['build_runner', 'build']);
      expect(result.stderr, isEmpty);
      expect(
        result.stdout,
        allOf(
          contains('Ignoring `global_options` for unknown builder `a:a`.'),
          contains(
            'Ignoring `runs_before` in `global_options` '
            'referencing unknown builder `b:b`.',
          ),
        ),
      );
    });
  });
}
