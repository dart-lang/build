// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:build_runner/build_runner.dart';

import '../common/package_graphs.dart';

void main() {
  PackageGraph graph;

  group('PackageGraph', () {
    group('forThisPackage ', () {
      setUp(() async {
        graph = new PackageGraph.forThisPackage();
      });

      test('root', () {
        expectPkg(graph.root, 'build_runner', './');
      });
    });

    group('basic package ', () {
      var basicPkgPath = 'test/fixtures/basic_pkg';

      setUp(() async {
        graph = new PackageGraph.forPath(basicPkgPath);
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
            }));
      });

      test('root', () {
        expectPkg(graph.root, 'basic_pkg', basicPkgPath,
            [graph['a'], graph['b'], graph['c'], graph['d']]);
      });

      test('dependency', () {
        expectPkg(
            graph['a'], 'a', '$basicPkgPath/pkg/a', [graph['b'], graph['c']]);
      });
    });

    group('package with dev dependencies', () {
      var withDevDepsPkgPath = 'test/fixtures/with_dev_deps';

      setUp(() async {
        graph = new PackageGraph.forPath(withDevDepsPkgPath);
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
        expectPkg(graph.root, 'with_dev_deps', withDevDepsPkgPath,
            [graph['a'], graph['b']]);

        // Package `c` does not appear because this is not the root package.
        expectPkg(graph['a'], 'a', '$withDevDepsPkgPath/pkg/a', []);

        expectPkg(graph['b'], 'b', '$withDevDepsPkgPath/pkg/b', []);

        expect(graph['c'], isNull);
      });
    });

    group('package with flutter dependencies', () {
      var withFlutterDeps = 'test/fixtures/flutter_pkg';

      setUp(() async {
        graph = new PackageGraph.forPath(withFlutterDeps);
      });

      test('allPackages resolved correctly with all packages', () {
        expect(graph.allPackages.keys, [
          'flutter_gallery',
          'intl',
          'string_scanner',
          'flutter',
          'collection',
          'flutter_gallery_assets',
          'flutter_test',
          'flutter_driver',
          r'$sdk',
        ]);
      });
    });

    test('custom creation via fromRoot', () {
      var a = new PackageNode('a', null);
      var b = new PackageNode('b', null);
      var c = new PackageNode('c', null);
      var d = new PackageNode('d', null);
      a.dependencies.addAll([b, d]);
      b.dependencies.add(c);
      var graph = new PackageGraph.fromRoot(a);
      expect(graph.root, a);
      expect(graph.allPackages,
          equals({'a': a, 'b': b, 'c': c, 'd': d, r'$sdk': anything}));
    });

    test('missing pubspec throws on create', () {
      expect(
          () => new PackageGraph.forPath(
              p.join('test', 'fixtures', 'no_pubspec')),
          throwsA(anything));
    });

    test('missing .packages file throws on create', () {
      expect(
          () => new PackageGraph.forPath(
              p.join('test', 'fixtures', 'no_packages_file')),
          throwsA(anything));
    });
  });

  group('orderedPackages', () {
    test('with two sub trees', () {
      var graph = buildPackageGraph('a', {
        package('a'): ['left1', 'right1'],
        package('left1'): ['left2'],
        package('left2'): [],
        package('right1'): ['right2'],
        package('right2'): []
      });
      var inOrder = graph.orderedPackages.map((n) => n.name).toList();
      expect(inOrder, containsAllInOrder(['left2', 'left1', 'a']));
      expect(inOrder, containsAllInOrder(['right2', 'right1', 'a']));
    });

    test('includes root last in cycle', () {
      var graph = buildPackageGraph('a', {
        package('a'): ['b'],
        package('b'): ['a']
      });
      var inOrder = graph.orderedPackages.map((n) => n.name).toList();
      expect(inOrder, ['b', 'a']);
    });

    test('handles cycles from beneath the root', () {
      var graph = buildPackageGraph('a', {
        package('a'): ['b'],
        package('b'): ['c'],
        package('c'): ['b']
      });
      var inOrder = graph.orderedPackages.map((n) => n.name).toList();
      expect(inOrder, containsAllInOrder(['b', 'a']));
      expect(inOrder, containsAllInOrder(['c', 'a']));
    });

    test('handles diamonds', () {
      var graph = buildPackageGraph('a', {
        package('a'): ['left', 'right'],
        package('left'): ['sharedDep'],
        package('right'): ['sharedDep'],
        package('sharedDep'): []
      });
      var inOrder = graph.orderedPackages.map((n) => n.name).toList();
      expect(inOrder, hasLength(4));
    });
  });

  group('dependentsOf', () {
    test('with two sub trees', () {
      var graph = buildPackageGraph('a', {
        package('a'): ['left1', 'right1', 'needle'],
        package('left1'): ['left2', 'needle'],
        package('left2'): [],
        package('right1'): ['right2'],
        package('right2'): ['needle'],
        package('needle'): []
      });
      var dependents = graph.dependentsOf('needle').map((n) => n.name).toList();
      expect(dependents, containsAllInOrder(['left1', 'a']));
      expect(dependents, containsAllInOrder(['right2', 'a']));
      expect(dependents, isNot(contains('left2')));
      expect(dependents, isNot(contains('right1')));
    });
  });
}

void expectPkg(PackageNode node, String name, String location,
    [Iterable<PackageNode> dependencies]) {
  location = p.absolute(location);
  expect(node.name, name);
  expect(node.path, location);
  if (dependencies != null) {
    expect(node.dependencies, unorderedEquals(dependencies));
  }
}
