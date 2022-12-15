// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@Timeout.factor(4)
import 'package:_test_common/descriptors.dart';
import 'package:_test_common/sdk.dart';
import 'package:build_runner/src/build_script_generate/build_script_generate.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  group('validation', () {
    setUpAll(() async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
          'code_builder',
        ]),
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
        expect(result.stderr, isEmpty,
            skip: 'https://github.com/dart-lang/sdk/issues/50592');
        expect(
            result.stdout,
            contains(
                'The `../` import syntax in build.yaml is now deprecated'));
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
        expect(result.stderr, isEmpty,
            skip: 'https://github.com/dart-lang/sdk/issues/50592');
        expect(
            result.stdout,
            isNot(contains(
                'The `../` import syntax in build.yaml is now deprecated')));

        await d.dir('a', [
          d.dir('.dart_tool', [
            d.dir('build', [
              d.dir('entrypoint', [
                d.file('build.dart',
                    contains("import '../../../tool/builder.dart'"))
              ])
            ])
          ])
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
''')
        ]).create();
        var result = await runPub('a', 'run', args: ['build_runner', 'build']);
        expect(result.stderr, isEmpty,
            skip: 'https://github.com/dart-lang/sdk/issues/50592');
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
''')
        ]).create();
        var result = await runPub('a', 'run', args: ['build_runner', 'build']);
        expect(result.stderr, isEmpty,
            skip: 'https://github.com/dart-lang/sdk/issues/50592');
        expect(
            result.stdout,
            contains(
                'Could not load imported package "unknown_package" '
                'for definition "a:fake".'));
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
      expect(result.stderr, isEmpty,
          skip: 'https://github.com/dart-lang/sdk/issues/50592');
      expect(
          result.stdout,
          allOf(
            contains(
                'Invalid builder key `a:a` found in global_options config of '
                'build.yaml. This configuration will have no effect.'),
            contains(
                'Invalid builder key `b:b` found in global_options config of '
                'build.yaml. This configuration will have no effect.'),
          ));
    });
  });

  group('determines whether a build script can be null safe', () {
    final buildYaml = d.file('build.yaml', '''
builders:
  a:
    import: 'package:a/builder.dart'
    build_extensions: {'.foo': ['.bar']}
    builder_factories: ['builder']
    ''');

    test('when all builders are opted-in', () async {
      await d.dir('a', [
        d.file('pubspec.yaml', '''
name: a
environment:
  sdk: '>=2.12.0 <3.0.0'
      '''),
        buildYaml,
        d.dir('lib', [d.file('builder.dart', '')]),
      ]).create();
      var pubGetResult = await runPub('a', 'get');
      expect(pubGetResult.exitCode, 0,
          reason: 'stdout: ${pubGetResult.stdout}\n\n'
              'stderr: ${pubGetResult.stderr}');

      final options = await findBuildScriptOptions(
          packageGraph: await PackageGraph.forPath('${d.sandbox}/a'));
      expect(options.canRunWithSoundNullSafety, isTrue);
    });

    if (supportsUnsoundNullSafety) {
      test('when the root package opts out', () async {
        await d.dir('a', [
          d.file('pubspec.yaml', '''
name: a
environment:
  sdk: '>=2.9.0 <3.0.0'
      '''),
          d.dir('lib', [d.file('builder.dart', '')]),
        ]).create();
        var pubGetResult = await runPub('a', 'get');
        expect(pubGetResult.exitCode, 0,
            reason: 'stdout: ${pubGetResult.stdout}\n\n'
                'stderr: ${pubGetResult.stderr}');

        final options = await findBuildScriptOptions(
            packageGraph: await PackageGraph.forPath('${d.sandbox}/a'));
        expect(options.canRunWithSoundNullSafety, isFalse);
      });

      test('when a builder-defining package opts out', () async {
        await d.dir('a', [
          d.file('pubspec.yaml', '''
name: a
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  b:
    path: ../b/
      '''),
        ]).create();
        await d.dir('b', [
          d.file('pubspec.yaml', '''
name: b
environment:
  sdk: '>=2.9.0 <3.0.0'
      '''),
          buildYaml,
          d.dir('lib', [
            d.file('builder.dart', ''),
          ]),
        ]).create();
        await runPub('a', 'get');
        var pubGetResult = await runPub('a', 'get');
        expect(pubGetResult.exitCode, 0,
            reason: 'stdout: ${pubGetResult.stdout}\n\n'
                'stderr: ${pubGetResult.stderr}');

        final options = await findBuildScriptOptions(
            packageGraph: await PackageGraph.forPath('${d.sandbox}/a'));
        expect(options.canRunWithSoundNullSafety, isFalse);
      });
    }

    test('when a builder-defining library ops out', () async {
      await d.dir('a', [
        d.file('pubspec.yaml', '''
name: a
environment:
  sdk: '>=2.12.0 <3.0.0'
      '''),
        buildYaml,
        d.dir('lib', [d.file('builder.dart', '// @dart=2.9')]),
      ]).create();
      await runPub('a', 'get');
      var pubGetResult = await runPub('a', 'get');
      expect(pubGetResult.exitCode, 0,
          reason: 'stdout: ${pubGetResult.stdout}\n\n'
              'stderr: ${pubGetResult.stderr}');

      final options = await findBuildScriptOptions(
          packageGraph: await PackageGraph.forPath('${d.sandbox}/a'));
      expect(options.canRunWithSoundNullSafety, isFalse);
    });

    test('when a builder-defining library ops out through a relative path',
        () async {
      await d.dir('a', [
        d.file('pubspec.yaml', '''
name: a
environment:
  sdk: '>=2.12.0 <3.0.0'
      '''),
        d.file('build.yaml', '''
builders:
  a:
    import: '../../../tool/builder.dart'
    build_extensions: {'.foo': ['.bar']}
    builder_factories: ['builder']
    '''),
        d.dir('tool', [d.file('builder.dart', '//@dart=2.9')]),
      ]).create();
      await runPub('a', 'get');
      var pubGetResult = await runPub('a', 'get');
      expect(pubGetResult.exitCode, 0,
          reason: 'stdout: ${pubGetResult.stdout}\n\n'
              'stderr: ${pubGetResult.stderr}');

      final options = await findBuildScriptOptions(
          packageGraph: await PackageGraph.forPath('${d.sandbox}/a'));
      expect(options.canRunWithSoundNullSafety, isFalse);
    });

    test('when a builder-defining library uses a top-level relative path',
        () async {
      await d.dir('a', [
        d.file('pubspec.yaml', '''
name: a
environment:
  sdk: '>=2.12.0 <3.0.0'
      '''),
        d.file('build.yaml', '''
builders:
  a:
    import: 'tool/builder.dart'
    build_extensions: {'.foo': ['.bar']}
    builder_factories: ['builder']
    '''),
        d.dir('tool', [d.file('builder.dart', '')]),
      ]).create();
      await runPub('a', 'get');
      var pubGetResult = await runPub('a', 'get');
      expect(pubGetResult.exitCode, 0,
          reason: 'stdout: ${pubGetResult.stdout}\n\n'
              'stderr: ${pubGetResult.stderr}');

      final options = await findBuildScriptOptions(
          packageGraph: await PackageGraph.forPath('${d.sandbox}/a'));
      expect(options.canRunWithSoundNullSafety, isTrue);
    });
  });
}
