// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
library;

import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:package_config/package_config_types.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late BuildPackages graph;

  group('BuildPackages', () {
    group('forThisPackage ', () {
      setUp(() async {
        graph = await BuildPackages.forThisPackage();
      });

      test('root', () {
        expectPkg(graph.root, 'build_runner', '', isEditable: true);
      });

      test('asPackageConfig', () {
        final config = graph.asPackageConfig;
        final buildRunner = config.packages.singleWhere(
          (p) => p.name == 'build_runner',
        );

        expect(buildRunner.languageVersion, LanguageVersion(3, 7));
      });
    });

    group('basic package ', () {
      final basicPkgPath = p.absolute('test/fixtures/basic_pkg/');

      setUp(() async {
        graph = await BuildPackages.forPath(basicPkgPath);
      });

      test('allPackages', () {
        expect(
          graph.allPackages,
          equals({
            'a': graph['a'],
            'b': graph['b'],
            'c': graph['c'],
            'd': graph['d'],
            'basic_pkg': graph['basic_pkg'],
            r'$sdk': anything,
          }),
        );
      });

      test('root', () {
        expectPkg(
          graph.root,
          'basic_pkg',
          basicPkgPath,
          isEditable: true,
          dependencies: [graph['a']!, graph['b']!, graph['c']!, graph['d']!],
        );
      });

      test('dependency', () {
        expectPkg(
          graph['a']!,
          'a',
          '$basicPkgPath/pkg/a',
          isEditable: false,
          dependencies: [graph['b']!, graph['c']!],
        );
      });

      test('asPackageConfig', () {
        final config = graph.asPackageConfig;
        final names = config.packages.map((e) => e.name);

        expect(names, isNot(contains(r'$sdk')));
        expect(names, containsAll(['a', 'b', 'c', 'd', 'basic_pkg']));
      });
    });

    group('package with dev dependencies', () {
      final withDevDepsPkgPath = p.absolute('test/fixtures/with_dev_deps');

      setUp(() async {
        graph = await BuildPackages.forPath(withDevDepsPkgPath);
      });

      test('allPackages contains dev deps of root pkg, but not others', () {
        // Package `c` is a dev dep of package `a` so it shouldn't be present
        // while package `b` is a dev dep of the root package so it should be.
        expect(graph.allPackages, {
          'a': graph['a'],
          'b': graph['b'],
          'with_dev_deps': graph['with_dev_deps'],
          r'$sdk': graph[r'$sdk'],
        });
      });

      test('dev deps are contained in deps of root pkg, but not others', () {
        // Package `b` shows as a dep because this is the root package.
        expectPkg(
          graph.root,
          'with_dev_deps',
          withDevDepsPkgPath,
          isEditable: true,
          dependencies: [graph['a']!, graph['b']!],
        );

        // Package `c` does not appear because this is not the root package.
        expectPkg(
          graph['a']!,
          'a',
          '$withDevDepsPkgPath/pkg/a',
          isEditable: false,
          dependencies: [],
        );

        expectPkg(
          graph['b']!,
          'b',
          '$withDevDepsPkgPath/pkg/b',
          isEditable: false,
          dependencies: [],
        );

        expect(graph['c'], isNull);
      });
    });

    group('package with flutter dependencies', () {
      final withFlutterDeps = p.absolute('test/fixtures/flutter_pkg');

      setUp(() async {
        graph = await BuildPackages.forPath(withFlutterDeps);
      });

      test('allPackages resolved correctly with all packages', () {
        expect(
          graph.allPackages.keys,
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

    test('custom creation via fromRoot', () {
      final a = BuildPackage('a', '/a', null, isEditable: true, isRoot: true);
      final b = BuildPackage('b', '/b', null, isEditable: true);
      final c = BuildPackage('c', '/c', null, isEditable: true);
      final d = BuildPackage('d', '/d', null, isEditable: true);
      a.dependencies.addAll([b, d]);
      b.dependencies.add(c);
      final graph = BuildPackages.fromRoot(a);
      expect(graph.root, a);
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

  group('workspace ', () {
    final workspaceFixturePath = p.absolute('test/fixtures/workspace');

    test('loads only dependent packages, has correct root', () async {
      Matcher packageNodeEquals(BuildPackage node) => isA<BuildPackage>()
          .having((c) => c.path, 'path', node.path)
          .having(
            (c) => c.dependencies,
            'dependencies',
            node.dependencies.map(packageNodeEquals),
          )
          .having((c) => c.isEditable, 'isEditable', node.isEditable);

      final graph = await BuildPackages.forPath(
        p.absolute('$workspaceFixturePath/pkgs/a'),
      );
      final a = BuildPackage(
        'a',
        '$workspaceFixturePath/pkgs/a',
        null,
        isEditable: true,
        isRoot: true,
      );
      final b = BuildPackage(
        'b',
        '$workspaceFixturePath/pkgs/b',
        null,
        isEditable: true,
      );
      a.dependencies.add(b);

      expect(graph.allPackages, {
        'a': packageNodeEquals(a),
        'b': packageNodeEquals(b),
        r'$sdk': anything,
      });

      expect(graph.root, packageNodeEquals(a));
    });
  });
}

void expectPkg(
  BuildPackage node,
  String name,
  String location, {
  required bool isEditable,
  Iterable<BuildPackage>? dependencies,
}) {
  location = p.canonicalize(location);
  expect(node.name, name);
  expect(node.path, location);
  expect(node.isEditable, isEditable);
  if (dependencies != null) {
    expect(node.dependencies, unorderedEquals(dependencies));
  }
}
