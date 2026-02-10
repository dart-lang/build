// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:package_config/package_config_types.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../common/common.dart';

void main() {
  late BuildPackages buildPackages;

  group('BuildPackages', () {
    group('forThisPackage ', () {
      setUp(() async {
        buildPackages = await BuildPackages.forThisPackage();
      });

      test('singleOutputPackage', () {
        expect(buildPackages.singleOutputPackage, 'build_runner');
      });

      test('asPackageConfig', () {
        final config = buildPackages.asPackageConfig;
        final buildRunner = config.packages.singleWhere(
          (p) => p.name == 'build_runner',
        );

        expect(buildRunner.languageVersion, LanguageVersion(3, 7));
      });
    });

    group('basic package', () {
      late BuildPackages buildPackages;
      late String tempDirectory;

      setUp(() async {
        final pubspecs = await Pubspecs.load();
        final tester = BuildRunnerTester(pubspecs);
        tempDirectory = tester.tempDirectory.path;

        tester.writePackage(
          name: 'basic_pkg',
          files: {},
          pathDependencies: ['a', 'b', 'c', 'd'],
        );
        tester.writePackage(name: 'a', files: {}, pathDependencies: ['b', 'c']);
        tester.writePackage(name: 'b', files: {});
        tester.writePackage(name: 'c', files: {});
        tester.writePackage(name: 'd', files: {});
        await tester.run('basic_pkg', 'dart pub get');
        fakeHostedPackages(tester.tempDirectory, ['a', 'b', 'c', 'd']);

        buildPackages = await BuildPackages.forPath(
          p.join(tempDirectory, 'basic_pkg'),
        );
      });

      test('packages', () {
        expect(
          buildPackages.packages.asMap(),
          equals({
            'a': buildPackages['a'],
            'b': buildPackages['b'],
            'c': buildPackages['c'],
            'd': buildPackages['d'],
            'basic_pkg': buildPackages['basic_pkg'],
            r'$sdk': anything,
          }),
        );
      });

      test('singleOutputPackage', () {
        expect(buildPackages.singleOutputPackage, 'basic_pkg');

        expect(
          buildPackages.packages['basic_pkg'],
          BuildPackage(
            name: 'basic_pkg',
            path: p.join(tempDirectory, 'basic_pkg'),
            watch: true,
            isOutput: true,
            languageVersion: LanguageVersion(3, 7),
            dependencies: ['a', 'b', 'c', 'd'],
          ),
        );
      });

      test('dependency', () {
        expect(
          buildPackages['a'],
          BuildPackage(
            name: 'a',
            path: p.join(tempDirectory, 'a'),
            languageVersion: LanguageVersion(3, 7),
            dependencies: ['b', 'c'],
          ),
        );
      });

      test('asPackageConfig', () {
        final config = buildPackages.asPackageConfig;
        final names = config.packages.map((e) => e.name);

        expect(names, isNot(contains(r'$sdk')));
        expect(names, containsAll(['a', 'b', 'c', 'd', 'basic_pkg']));
      });
    });

    group('package with dev dependencies', () {
      late BuildPackages buildPackages;
      late String tempDirectory;

      setUp(() async {
        final pubspecs = await Pubspecs.load();
        final tester = BuildRunnerTester(pubspecs);
        tempDirectory = tester.tempDirectory.path;

        tester.writePackage(
          name: 'with_dev_deps',
          files: {},
          pathDependencies: ['a'],
          pathDevDependencies: ['b'],
        );
        tester.writePackage(name: 'a', files: {}, pathDevDependencies: ['c']);
        tester.writePackage(name: 'b', files: {});
        tester.writePackage(name: 'c', files: {});
        await tester.run('with_dev_deps', 'dart pub get');
        fakeHostedPackages(tester.tempDirectory, ['a', 'b', 'c']);

        buildPackages = await BuildPackages.forPath(
          p.join(tempDirectory, 'with_dev_deps'),
        );
      });

      test('allPackages contains dev deps of current pkg, but not others', () {
        // Package `c` is a dev dep of package `a` so it shouldn't be present
        // while package `b` is a dev dep of the root package so it should be.
        expect(buildPackages.packages.asMap(), {
          'a': buildPackages['a'],
          'b': buildPackages['b'],
          'with_dev_deps': buildPackages['with_dev_deps'],
          r'$sdk': buildPackages[r'$sdk'],
        });
      });

      test('dev deps are contained in deps of current pkg, but not others', () {
        // Package `b` shows as a dep because this is the root package.
        expect(buildPackages.singleOutputPackage, 'with_dev_deps');

        expect(
          buildPackages['with_dev_deps'],
          BuildPackage(
            name: 'with_dev_deps',
            path: p.join(tempDirectory, 'with_dev_deps'),
            watch: true,
            isOutput: true,
            languageVersion: LanguageVersion(3, 7),
            dependencies: ['a', 'b'],
          ),
        );

        // Package `c` does not appear because this is not the current package.
        expect(
          buildPackages['a'],
          BuildPackage(
            name: 'a',
            path: p.join(tempDirectory, 'a'),
            languageVersion: LanguageVersion(3, 7),
          ),
        );

        expect(
          buildPackages['b'],
          BuildPackage(
            name: 'b',
            path: p.join(tempDirectory, 'b'),
            languageVersion: LanguageVersion(3, 7),
          ),
        );

        expect(buildPackages['c'], isNull);
      });
    });

    group('package with flutter dependencies', () {
      final withFlutterDeps = p.absolute('test/fixtures/flutter_pkg');

      setUp(() async {
        buildPackages = await BuildPackages.forPath(withFlutterDeps);
      });

      test('allPackages resolved correctly with all packages', () {
        expect(
          buildPackages.packages.keys,
          unorderedEquals([
            'flutter_gallery',
            'intl',
            'string_scanner',
            'flutter',
            'collection',
            'flutter_gallery_assets',
            'flutter_test',
            'flutter_driver',
            r'$sdk',
          ]),
        );
      });
    });

    test('custom creation via fromCurrent', () {
      final a = BuildPackage(
        name: 'a',
        path: '/a',
        watch: true,
        isOutput: true,
        dependencies: ['b', 'd'],
      );
      final b = BuildPackage(
        name: 'b',
        path: '/b',
        watch: true,
        dependencies: ['c'],
      );
      final c = BuildPackage(name: 'c', path: '/c', watch: true);
      final d = BuildPackage(name: 'd', path: '/d', watch: true);
      final graph = BuildPackages.singlePackageBuild('a', [a, b, c, d]);
      expect(graph.singleOutputPackage!, 'a');
      expect(
        graph.packages.asMap(),
        equals({'a': a, 'b': b, 'c': c, 'd': d, r'$sdk': anything}),
      );
    });

    test('missing pubspec throws on create', () {
      expect(
        () => BuildPackages.forPath(
          p.absolute(p.join('test', 'fixtures', 'no_pubspec')),
        ),
        throwsA(anything),
      );
    });

    test('missing .dart_tool/package_config.json file throws on create', () {
      expect(
        () => BuildPackages.forPath(
          p.absolute(p.join('test', 'fixtures', 'no_packages_file')),
        ),
        throwsA(anything),
      );
    });
  });

  group('workspace', () {
    late BuildPackages buildPackages;
    late String tempDirectory;

    setUp(() async {
      final pubspecs = await Pubspecs.load();
      final tester = BuildRunnerTester(pubspecs);
      tempDirectory = tester.tempDirectory.path;

      tester.writePackage(
        name: 'a',
        files: {},
        workspaceDependencies: ['b'],
        inWorkspace: true,
      );
      tester.writePackage(name: 'b', files: {}, inWorkspace: true);
      tester.write('pubspec.yaml', '''
name: some_workspace_name
environment:
  sdk: ^3.5.0
workspace:
  - a
  - b
''');
      await tester.run('a', 'dart pub get');
    });

    test('without --workspace loads correctly', () async {
      buildPackages = await BuildPackages.forPath(p.join(tempDirectory, 'a'));

      expect(buildPackages.packages.asMap(), {
        'a': BuildPackage(
          name: 'a',
          path: p.join(tempDirectory, 'a'),
          watch: true,
          isOutput: true,
          languageVersion: LanguageVersion(3, 7),
          dependencies: ['b'],
        ),
        'b': BuildPackage(
          name: 'b',
          path: p.join(tempDirectory, 'b'),
          watch: true,
          languageVersion: LanguageVersion(3, 7),
        ),
        r'$sdk': anything,
      });

      expect(buildPackages.singleOutputPackage, 'a');
      expect(buildPackages.outputRoot, 'a');
    });

    group('with --workspace loads correctly', () {
      late Map<String, Object> expectedPackages;

      setUp(() {
        expectedPackages = {
          'a': BuildPackage(
            name: 'a',
            path: p.join(tempDirectory, 'a'),
            watch: true,
            isOutput: true,
            languageVersion: LanguageVersion(3, 7),
            dependencies: ['b'],
          ),
          'b': BuildPackage(
            name: 'b',
            path: p.join(tempDirectory, 'b'),
            watch: true,
            isOutput: true,
            languageVersion: LanguageVersion(3, 7),
          ),
          'some_workspace_name': BuildPackage(
            name: 'some_workspace_name',
            path: tempDirectory,
            watch: true,
            isOutput: true,
            languageVersion: LanguageVersion(3, 5),
          ),
          r'$sdk': anything,
        };
      });

      test('for package', () async {
        // Load the workspace passing the directory of a package in the
        // workspace.
        buildPackages = await BuildPackages.forPath(
          p.join(tempDirectory, 'a'),
          workspace: true,
        );

        expect(buildPackages.packages.asMap(), expectedPackages);
        expect(buildPackages.singleOutputPackage, null);
        expect(buildPackages.outputRoot, 'some_workspace_name');
      });

      test('for workspace root', () async {
        // Load the workspace passing the directory of a package in the
        // workspace itself. The result should be identical.
        buildPackages = await BuildPackages.forPath(
          tempDirectory,
          workspace: true,
        );

        expect(buildPackages.packages.asMap(), expectedPackages);
        expect(buildPackages.singleOutputPackage, null);
        expect(buildPackages.outputRoot, 'some_workspace_name');
      });
    });
  });

  test('calculates transitive dependencies', () {
    final buildPackages = BuildPackages.workspaceBuild('workspace', [
      BuildPackage.forTesting(name: 'a', dependencies: ['b']),
      BuildPackage.forTesting(name: 'b', dependencies: ['d']),
      BuildPackage.forTesting(name: 'c', dependencies: ['d']),
      BuildPackage.forTesting(name: 'd', dependencies: ['e']),
      BuildPackage.forTesting(name: 'e', dependencies: ['d']),
      BuildPackage.forTesting(name: 'f', dependencies: ['g']),
      BuildPackage.forTesting(name: 'g', dependencies: ['h']),
      BuildPackage.forTesting(name: 'h', dependencies: ['g', 'i']),
      BuildPackage.forTesting(name: 'i'),
      BuildPackage.forTesting(name: 'workspace'),
    ]);

    expect(buildPackages.transitiveDepsOf('a'), {'a', 'b', 'd', 'e'});
    expect(buildPackages.transitiveDepsOf('d'), {'d', 'e'});
    expect(buildPackages.transitiveDepsOf('f'), {'f', 'g', 'h', 'i'});
    expect(buildPackages.transitiveDepsOf('g'), {'g', 'h', 'i'});
    expect(buildPackages.transitiveDepsOf('h'), {'g', 'h', 'i'});
  });

  test('filters to transitive dependencies of single build package', () {
    final buildPackages = BuildPackages.singlePackageBuild('f', [
      BuildPackage.forTesting(name: 'a', dependencies: ['b']),
      BuildPackage.forTesting(name: 'b'),
      BuildPackage.forTesting(name: 'f', dependencies: ['g']),
      BuildPackage.forTesting(name: 'g'),
    ]);

    expect(buildPackages.packages.keys, ['f', 'g', r'$sdk']);
  });

  test('calculates peer packages', () {
    final buildPackages = BuildPackages.workspaceBuild('workspace', [
      BuildPackage.forTesting(name: 'a', dependencies: ['b'], isOutput: true),
      BuildPackage.forTesting(name: 'b', dependencies: ['d']),
      BuildPackage.forTesting(name: 'c', dependencies: ['d'], isOutput: true),
      BuildPackage.forTesting(name: 'd', dependencies: ['e']),
      BuildPackage.forTesting(name: 'e', dependencies: ['d']),
      BuildPackage.forTesting(name: 'f', dependencies: ['g'], isOutput: true),
      BuildPackage.forTesting(name: 'g'),
      BuildPackage.forTesting(name: 'h', dependencies: ['e'], isOutput: true),
      BuildPackage.forTesting(name: 'workspace'),
    ]);

    // Transitive deps of output package `a`.
    expect(buildPackages.peersOf('a'), {'a', 'b', 'd', 'e'});
    expect(buildPackages.peersOf('b'), {'a', 'b', 'd', 'e'});

    // Transitive deps of output package `c`.
    expect(buildPackages.peersOf('c'), {'c', 'd', 'e'});

    // Transitive deps of output packages `a`, `c` and `h`.
    expect(buildPackages.peersOf('d'), {'a', 'b', 'c', 'd', 'e', 'h'});
    expect(buildPackages.peersOf('e'), {'a', 'b', 'c', 'd', 'e', 'h'});

    // Transitive deps of output package `f`.
    expect(buildPackages.peersOf('f'), {'f', 'g'});
    expect(buildPackages.peersOf('g'), {'f', 'g'});
  });
}

/// Updates all `pubspec.lock` files to change source for [packages] to
/// `hosted`.
///
/// This fakes that they were fetched from pub, not from path.
///
/// `pubspec.lock` files that do not mention [packages] are ignored.
void fakeHostedPackages(Directory tempDirectory, Iterable<String> packages) {
  for (final file
      in tempDirectory.listSync(recursive: true).whereType<File>()) {
    if (p.basename(file.path) != 'pubspec.lock') continue;
    final yaml = Map<Object, Object>.from(
      loadYaml(file.readAsStringSync()) as YamlMap,
    );
    final packagesYaml =
        yaml['packages'] = Map<Object, Object>.from(
          yaml['packages'] as YamlMap,
        );
    for (final package in packages) {
      if (packagesYaml.containsKey(package)) {
        final packageYaml =
            packagesYaml[package] = Map<Object, Object>.from(
              packagesYaml[package] as YamlMap,
            );
        packageYaml['source'] = 'hosted';
      }
    }
    // `package:yaml` does not support writing, recommends to just write as
    // JSON because it's valid yaml.
    file.writeAsStringSync(json.encode(yaml));
  }
}
