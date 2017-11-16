import 'package:test/test.dart';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/package_graph/dependency_ordering.dart';

void main() {
  group('stronglyConnectedComponents', () {
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
      var inOrder = stronglyConnectedComponents<String, PackageNode>(
              [graph.root], (node) => node.name, (node) => node.dependencies)
          .map((c) => c.map((p) => p.name));
      expect(inOrder, hasLength(5));
      expect(
          inOrder,
          containsAllInOrder([
            ['left2'],
            ['left1'],
            ['a']
          ]));
      expect(
          inOrder,
          containsAllInOrder([
            ['right2'],
            ['right1'],
            ['a']
          ]));
    });

    test('includes the root last in the strongly connected component', () {
      var a = new PackageNode('a', '1.0.0', PackageDependencyType.path, null);
      var b = new PackageNode('b', '1.0.0', PackageDependencyType.path, null);
      a.dependencies.add(b);
      b.dependencies.add(a);
      var graph = new PackageGraph.fromRoot(a);
      var inOrder = stronglyConnectedComponents<String, PackageNode>(
              [graph.root], (node) => node.name, (node) => node.dependencies)
          .map((c) => c.map((p) => p.name));
      expect(inOrder, hasLength(1));
      expect(inOrder.first, ['b', 'a']);
    });

    test('handles cycles from beneath the root', () {
      var a = new PackageNode('a', '1.0.0', PackageDependencyType.path, null);
      var b = new PackageNode('b', '1.0.0', PackageDependencyType.path, null);
      var c = new PackageNode('c', '1.0.0', PackageDependencyType.path, null);
      a.dependencies.add(b);
      b.dependencies.add(c);
      c.dependencies.add(b);
      var graph = new PackageGraph.fromRoot(a);
      var inOrder = stronglyConnectedComponents<String, PackageNode>(
              [graph.root], (node) => node.name, (node) => node.dependencies)
          .map((c) => c.map((p) => p.name));
      expect(inOrder, hasLength(2));
      expect(
          inOrder,
          containsAllInOrder([
            allOf(contains('b'), contains('c')),
            ['a']
          ]));
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
      var inOrder = stronglyConnectedComponents<String, PackageNode>(
              [graph.root], (node) => node.name, (node) => node.dependencies)
          .map((c) => c.map((p) => p.name));
      expect(inOrder, hasLength(4));
      expect(
          inOrder,
          containsAllInOrder([
            ['sharedDep'],
            ['left'],
            ['a']
          ]));
      expect(
          inOrder,
          containsAllInOrder([
            ['sharedDep'],
            ['right'],
            ['a']
          ]));
    });
  });
}
