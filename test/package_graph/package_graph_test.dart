// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'package:test/test.dart';

import 'package:build/build.dart';

main() async {
  PackageGraph graph;

  group('forThisPackage ', () {
    setUp(() async {
      graph = await new PackageGraph.forThisPackage();
    });

    test('root', () {
      expectPkg(
          graph.root, 'build', isNotEmpty, PackageDependencyType.Path, './');
    });
  });

  group('basic package ', () {
    var basicPkgPath = 'test/package_graph/basic_pkg';

    setUp(() async {
      graph = await new PackageGraph.forPath(basicPkgPath);
    });

    test('allPackages', () {
      expect(graph.allPackages, {
        'a': graph['a'],
        'b': graph['b'],
        'c': graph['c'],
        'basic_pkg': graph['basic_pkg'],
      });
    });

    test('root', () {
      expectPkg(graph.root, 'basic_pkg', '1.0.0', PackageDependencyType.Path,
          basicPkgPath, [graph['a'], graph['b'], graph['c']]);
    });

    test('pub dependency', () {
      expectPkg(graph['a'], 'a', '2.0.0', PackageDependencyType.Pub,
          '$basicPkgPath/pkg/a/', [graph['b'], graph['c']]);
    });

    test('git dependency', () {
      expectPkg(graph['b'], 'b', '3.0.0', PackageDependencyType.Github,
          '$basicPkgPath/pkg/b/', [graph['c']]);
    });

    test('path dependency', () {
      expectPkg(graph['c'], 'c', '4.0.0', PackageDependencyType.Path,
          '$basicPkgPath/pkg/c/', [graph['basic_pkg']]);
    });
  });

  test('missing pubspec throws on create', () {
    expect(() => new PackageGraph.forPath('no_pubspec'), throws);
  });

  test('missing .packages file throws on create', () {
    expect(() => new PackageGraph.forPath('no_packages_file'), throws);
  });
}

void expectPkg(PackageNode node, name, version, type, location,
    [Iterable<PackageNode> dependencies]) {
  expect(node.name, name);
  expect(node.version, version);
  expect(node.dependencyType, type);
  expect(node.location.path, location);
  if (dependencies != null) {
    expect(node.dependencies, unorderedEquals(dependencies));
  }
}
