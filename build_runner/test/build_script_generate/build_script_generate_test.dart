// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@Timeout.factor(4)
import 'package:_test_common/package_graphs.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:build_runner/build_script_generate.dart';

import 'package:_test_common/descriptors.dart';
import 'package:_test_common/sdk.dart';

void main() {
  group('Builder imports', () {
    setUp(() async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
        ]),
      ]).create();
      await runPub('a', 'get');
    });

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
      expect(result.stdout,
          contains('The `../` import syntax in build.yaml is now deprecated'));
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
      expect(
          result.stdout,
          isNot(contains(
              'The `../` import syntax in build.yaml is now deprecated')));

      await d.dir('a', [
        d.dir('.dart_tool', [
          d.dir('build', [
            d.dir('entrypoint', [
              d.file(
                  'build.dart', contains("import '../../../tool/builder.dart'"))
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
      expect(result.stdout, contains('could not be parsed'));
    });
  });

  test('generates build script with custom options', () async {
    final script = await generateBuildScript(_TestGenerationOptions());

    expect(script, contains("import 'package:foo/bar.dart'"));
    expect(script, contains("import 'package:builders/builder.dart'"));
    expect(script, contains('createCustomBuilder'));
    expect(script, contains('runBuild(args, _builders)'));
  });
}

class _TestGenerationOptions extends BuildScriptGenerationOptions {
  @override
  Expression runBuild(Expression args, Expression builders) {
    return refer('runBuild', 'package:foo/bar.dart').call([args, builders]);
  }

  @override
  Future<PackageGraph> packageGraph() {
    return Future.value(buildPackageGraph(
      {
        rootPackage('root'): ['builders'],
        package('builders'): []
      },
    ));
  }

  @override
  Future<Map<String, BuildConfig>> findConfigOverrides(
      PackageGraph graph, RunnerAssetReader reader) {
    return Future.value({
      'builders': BuildConfig.parse(
        'builders',
        [],
        '''
        builders:
          builders|builder:
            import: 'package:builders/builder.dart'
            builder_factories: [createCustomBuilder]
            build_extensions: {'.dart': ['.g.dart']}
            auto_apply: dependents
        ''',
      )
    });
  }
}
