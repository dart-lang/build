// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@Timeout.factor(4)
library;

import 'package:_test_common/descriptors.dart';
import 'package:_test_common/sdk.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

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
            'build_resolvers',
            'build_runner',
            'build_runner_core',
            'code_builder',
          ],
        ),
      ]).create();
      await runPub('a', 'get');
    });

    group('of builder imports', () {
      test('warn about deprecated ../ style imports', () async {
        await d.dir('a', [
          d.file('build.yaml', '''
builders:
  fake:
    import: "../../../tool/builder.dart"
    builder_factories: ["myFactory"]
    build_extensions: {"foo": ["bar"]}
'''),
        ]).create();

        var result = await runPub('a', 'run', args: ['build_runner', 'build']);
        expect(result.stderr, isEmpty);
        expect(
          result.stdout,
          contains('The `../` import syntax in build.yaml is now deprecated'),
        );
      });

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

        var result = await runPub('a', 'run', args: ['build_runner', 'build']);
        expect(result.stderr, isEmpty);
        expect(
          result.stdout,
          isNot(
            contains('The `../` import syntax in build.yaml is now deprecated'),
          ),
        );

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
        var result = await runPub('a', 'run', args: ['build_runner', 'build']);
        expect(result.stderr, isEmpty);
        expect(result.stdout, contains('could not be parsed'));
      });

      test('warn when import not present in packageGraph', () async {
        await d.dir('a', [
          d.file('build.yaml', '''
builders:
  fake:
    import: "package:unknown_package/import.dart"
    builder_factories: ["myFactory"]
    build_extensions: {"foo": ["bar"]}
'''),
        ]).create();
        var result = await runPub('a', 'run', args: ['build_runner', 'build']);
        expect(result.stderr, isEmpty);
        expect(
          result.stdout,
          contains(
            'Could not load imported package "unknown_package" '
            'for definition "a:fake".',
          ),
        );
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

      var result = await runPub('a', 'run', args: ['build_runner', 'build']);
      expect(result.stderr, isEmpty);
      expect(
        result.stdout,
        allOf(
          contains(
            'Invalid builder key `a:a` found in global_options config of '
            'build.yaml. This configuration will have no effect.',
          ),
          contains(
            'Invalid builder key `b:b` found in global_options config of '
            'build.yaml. This configuration will have no effect.',
          ),
        ),
      );
    });
  });
}
