// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:build/build.dart';
import 'package:build_runner/src/package_graph/package_graph.dart';
import 'package:build_runner/src/watcher/asset_change.dart';
import 'package:build_runner/src/watcher/graph_watcher.dart';
import 'package:build_runner/src/watcher/node_watcher.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  group('PackageGraphWatcher', () {
    test('should aggregate changes from all nodes', () {
      final pkgA = new PackageNode.noPubspec('a', path: '/g/a');
      final pkgB = new PackageNode.noPubspec('b', path: '/g/b');
      pkgA.dependencies.add(pkgB);

      final graph = new PackageGraph.fromRoot(pkgA);
      final nodes = {
        'a': new FakeNodeWatcher(pkgA),
        'b': new FakeNodeWatcher(pkgB),
      };
      final watcher = new PackageGraphWatcher(graph, watch: (node) {
        return nodes[node.name];
      });

      nodes['a'].emitAdd('lib/a.dart');
      nodes['b'].emitAdd('lib/b.dart');

      expect(
          watcher.watch(),
          emitsInOrder([
            new AssetChange(new AssetId('a', 'lib/a.dart'), ChangeType.ADD),
            new AssetChange(new AssetId('b', 'lib/b.dart'), ChangeType.ADD),
          ]));
    });

    test('should avoid duplicate changes with nested packages', () {
      final pkgA = new PackageNode.noPubspec('a', path: '/g/a');
      final pkgB = new PackageNode.noPubspec('b', path: '/g/a/b');
      pkgA.dependencies.add(pkgB);

      final graph = new PackageGraph.fromRoot(pkgA);
      final nodes = {
        'a': new FakeNodeWatcher(pkgA),
        'b': new FakeNodeWatcher(pkgB),
      };
      final watcher = new PackageGraphWatcher(graph, watch: (node) {
        return nodes[node.name];
      });

      nodes['a'].emitAdd('lib/a.dart');
      nodes['b'].emitAdd('lib/b.dart');

      expect(
          watcher.watch(),
          emitsInOrder([
            new AssetChange(new AssetId('a', 'lib/a.dart'), ChangeType.ADD),
            new AssetChange(new AssetId('b', 'lib/b.dart'), ChangeType.ADD),
          ]));
    });
  });
}

class FakeNodeWatcher implements PackageNodeWatcher {
  final PackageNode _package;
  final _events = new StreamController<AssetChange>();

  FakeNodeWatcher(this._package);

  void emitAdd(String path) {
    _events.add(
      new AssetChange(
        new AssetId(_package.name, path),
        ChangeType.ADD,
      ),
    );
  }

  @override
  Stream<AssetChange> watch([_]) => _events.stream;
}
