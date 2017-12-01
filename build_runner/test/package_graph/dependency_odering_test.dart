import 'package:test/test.dart';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/package_graph/dependency_ordering.dart';

import '../common/package_graphs.dart';

void main() {
  group('stronglyConnectedComponents', () {
    test('with two sub trees', () {
      var graph = buildPackageGraph({
        rootPackage('a'): ['left1', 'right1'],
        package('left1'): ['left2'],
        package('left2'): [],
        package('right1'): ['right2'],
        package('right2'): []
      });
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
      var graph = buildPackageGraph({
        rootPackage('a'): ['b'],
        package('b'): ['a']
      });
      var inOrder = stronglyConnectedComponents<String, PackageNode>(
              [graph.root], (node) => node.name, (node) => node.dependencies)
          .map((c) => c.map((p) => p.name));
      expect(inOrder, hasLength(1));
      expect(inOrder.first, ['b', 'a']);
    });

    test('handles cycles from beneath the root', () {
      var graph = buildPackageGraph({
        rootPackage('a'): ['b'],
        package('b'): ['c'],
        package('c'): ['b']
      });
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
      var graph = buildPackageGraph({
        rootPackage('a'): ['left', 'right'],
        package('left'): ['sharedDep'],
        package('right'): ['sharedDep'],
        package('sharedDep'): []
      });
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
