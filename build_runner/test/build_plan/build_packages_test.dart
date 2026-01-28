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

      test('current', () {
        expect(
          buildPackages.current,
          BuildPackage(
            name: 'build_runner',
            path: '',
            watch: true,
            isInBuild: true,
            languageVersion: LanguageVersion(3, 7),
            dependencies: buildPackages.current!.dependencies,
          ),
        );
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

      test('allPackages', () {
        expect(
          buildPackages.allPackages,
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

      test('current', () {
        expect(
          buildPackages.current,
          BuildPackage(
            name: 'basic_pkg',
            path: p.join(tempDirectory, 'basic_pkg'),
            watch: true,
            isInBuild: true,
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
        expect(buildPackages.allPackages, {
          'a': buildPackages['a'],
          'b': buildPackages['b'],
          'with_dev_deps': buildPackages['with_dev_deps'],
          r'$sdk': buildPackages[r'$sdk'],
        });
      });

      test('dev deps are contained in deps of current pkg, but not others', () {
        // Package `b` shows as a dep because this is the root package.
        expect(
          buildPackages.current,
          BuildPackage(
            name: 'with_dev_deps',
            path: p.join(tempDirectory, 'with_dev_deps'),
            watch: true,
            isInBuild: true,
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
          buildPackages.allPackages.keys,
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
        isInBuild: true,
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
      final graph = BuildPackages.fromPackages([a, b, c, d], current: 'a');
      expect(graph.current!, a);
      expect(
        graph.allPackages,
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
name: workspace
environment:
  sdk: ^3.5.0
workspace:
  - a
  - b
''');
      await tester.run('a', 'dart pub get');

      buildPackages = await BuildPackages.forPath(p.join(tempDirectory, 'a'));
    });

    test('loads only dependent packages, has correct current', () async {
      expect(buildPackages.allPackages, {
        'a': BuildPackage(
          name: 'a',
          path: p.join(tempDirectory, 'a'),
          watch: true,
          isInBuild: true,
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

      expect(buildPackages.current, buildPackages['a']);
    });
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
