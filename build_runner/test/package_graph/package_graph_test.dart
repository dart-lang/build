// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:build_runner/build_runner.dart';

void main() {
  PackageGraph graph;

  group('PackageGraph', () {
    group('forThisPackage ', () {
      setUp(() async {
        graph = new PackageGraph.forThisPackage();
      });

      test('root', () {
        expectPkg(graph.root, 'build_runner', isNotEmpty,
            PackageDependencyType.path, './');
      });
    });

    group('basic package ', () {
      var basicPkgPath = 'test/fixtures/basic_pkg';

      setUp(() async {
        graph = new PackageGraph.forPath(basicPkgPath);
      });

      test('allPackages', () {
        expect(graph.allPackages, {
          'a': graph['a'],
          'b': graph['b'],
          'c': graph['c'],
          'd': graph['d'],
          'basic_pkg': graph['basic_pkg'],
        });
      });

      test('root', () {
        expectPkg(graph.root, 'basic_pkg', '1.0.0', PackageDependencyType.path,
            basicPkgPath, [graph['a'], graph['b'], graph['c'], graph['d']]);
      });

      test('pub dependency', () {
        expectPkg(graph['a'], 'a', '2.0.0', PackageDependencyType.pub,
            '$basicPkgPath/pkg/a', [graph['b'], graph['c']]);
      });

      test('git dependency', () {
        expectPkg(graph['b'], 'b', '3.0.0', PackageDependencyType.github,
            '$basicPkgPath/pkg/b', [graph['c']]);
      });

      test('path dependency', () {
        expectPkg(graph['c'], 'c', '4.0.0', PackageDependencyType.path,
            '$basicPkgPath/pkg/c', [graph['basic_pkg']]);
      });

      test('hosted dependency', () {
        expectPkg(graph['d'], 'd', '5.0.0', PackageDependencyType.hosted,
            '$basicPkgPath/pkg/d', [graph['c']]);
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
        });
      });

      test('dev deps are contained in deps of root pkg, but not others', () {
        // Package `b` shows as a dep because this is the root package.
        expectPkg(
            graph.root,
            'with_dev_deps',
            '1.0.0',
            PackageDependencyType.path,
            withDevDepsPkgPath,
            [graph['a'], graph['b']]);

        // Package `c` does not appear because this is not the root package.
        expectPkg(graph['a'], 'a', '2.0.0', PackageDependencyType.pub,
            '$withDevDepsPkgPath/pkg/a', []);

        expectPkg(graph['b'], 'b', '3.0.0', PackageDependencyType.pub,
            '$withDevDepsPkgPath/pkg/b', []);

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
        ]);
      });
    });

    test('custom creation via fromRoot', () {
      var a = new PackageNode('a', '1.0.0', PackageDependencyType.path, null);
      var b = new PackageNode('b', '1.0.0', PackageDependencyType.pub, null);
      var c = new PackageNode('c', '1.0.0', PackageDependencyType.pub, null);
      var d = new PackageNode('d', '1.0.0', PackageDependencyType.pub, null);
      a.dependencies.addAll([b, d]);
      b.dependencies.add(c);
      var graph = new PackageGraph.fromRoot(a);
      expect(graph.root, a);
      expect(graph.allPackages, {'a': a, 'b': b, 'c': c, 'd': d});
    });

    test('missing pubspec throws on create', () {
      expect(
          () => new PackageGraph.forPath(
              path.join('test', 'fixtures', 'no_pubspec')),
          throwsA(anything));
    });

    test('missing .packages file throws on create', () {
      expect(
          () => new PackageGraph.forPath(
              path.join('test', 'fixtures', 'no_packages_file')),
          throwsA(anything));
    });
  });

  group('orderedPackages', () {
    test('with two sub trees', () {
      var a = new PackageNode('a', '1.0.0', PackageDependencyType.path, null);
      var left1 =
          new PackageNode('left1', '1.0.0', PackageDependencyType.pub, null);
      var left2 =
          new PackageNode('left2', '1.0.0', PackageDependencyType.pub, null);
      var right1 =
          new PackageNode('right1', '1.0.0', PackageDependencyType.pub, null);
      var right2 =
          new PackageNode('right2', '1.0.0', PackageDependencyType.pub, null);
      a.dependencies.addAll([left1, right1]);
      left1.dependencies.add(left2);
      right1.dependencies.add(right2);
      var graph = new PackageGraph.fromRoot(a);
      var inOrder = graph.orderedPackages.map((n) => n.name).toList();
      expect(inOrder, containsAllInOrder(['left2', 'left1', 'a']));
      expect(inOrder, containsAllInOrder(['right2', 'right1', 'a']));
    });

    test('includes root last in cycle', () {
      var a = new PackageNode('a', '1.0.0', PackageDependencyType.path, null);
      var b = new PackageNode('b', '1.0.0', PackageDependencyType.path, null);
      a.dependencies.add(b);
      b.dependencies.add(a);
      var graph = new PackageGraph.fromRoot(a);
      var inOrder = graph.orderedPackages.map((n) => n.name).toList();
      expect(inOrder, ['b', 'a']);
    });

    test('handles cycles from beneath the root', () {
      var a = new PackageNode('a', '1.0.0', PackageDependencyType.path, null);
      var b = new PackageNode('b', '1.0.0', PackageDependencyType.path, null);
      var c = new PackageNode('c', '1.0.0', PackageDependencyType.path, null);
      a.dependencies.add(b);
      b.dependencies.add(c);
      c.dependencies.add(b);
      var graph = new PackageGraph.fromRoot(a);
      var inOrder = graph.orderedPackages.map((n) => n.name).toList();
      expect(inOrder, containsAllInOrder(['b', 'a']));
      expect(inOrder, containsAllInOrder(['c', 'a']));
    });

    test('handles diamonds', () {
      var a = new PackageNode('a', '1.0.0', PackageDependencyType.path, null);
      var left =
          new PackageNode('left', '1.0.0', PackageDependencyType.path, null);
      var right =
          new PackageNode('right', '1.0.0', PackageDependencyType.path, null);
      var sharedDep = new PackageNode(
          'sharedDep', '1.0.0', PackageDependencyType.path, null);
      a.dependencies.addAll([left, right]);
      left.dependencies.add(sharedDep);
      right.dependencies.add(sharedDep);
      var graph = new PackageGraph.fromRoot(a);
      var inOrder = graph.orderedPackages.map((n) => n.name).toList();
      expect(inOrder, hasLength(4));
    });
  });

  group('dependentsOf', () {
    test('with two sub trees', () {
      var a = new PackageNode('a', '1.0.0', PackageDependencyType.path, null);
      var left1 =
          new PackageNode('left1', '1.0.0', PackageDependencyType.pub, null);
      var left2 =
          new PackageNode('left2', '1.0.0', PackageDependencyType.pub, null);
      var right1 =
          new PackageNode('right1', '1.0.0', PackageDependencyType.pub, null);
      var right2 =
          new PackageNode('right2', '1.0.0', PackageDependencyType.pub, null);
      var needle =
          new PackageNode('needle', '1.0.0', PackageDependencyType.pub, null);
      a.dependencies.addAll([left1, right1, needle]);
      left1.dependencies.addAll([left2, needle]);
      right1.dependencies.add(right2);
      right2.dependencies.add(needle);
      var graph = new PackageGraph.fromRoot(a);
      var dependents = graph.dependentsOf('needle').map((n) => n.name).toList();
      expect(dependents, containsAllInOrder(['left1', 'a']));
      expect(dependents, containsAllInOrder(['right2', 'a']));
      expect(dependents, isNot(contains('left2')));
      expect(dependents, isNot(contains('right1')));
    });
  });
}

void expectPkg(PackageNode node, String name, dynamic version,
    PackageDependencyType type, String location,
    [Iterable<PackageNode> dependencies]) {
  expect(node.name, name);
  expect(node.version, version);
  expect(node.dependencyType, type);
  expect(node.location.path, location);
  if (dependencies != null) {
    expect(node.dependencies, unorderedEquals(dependencies));
  }
}
