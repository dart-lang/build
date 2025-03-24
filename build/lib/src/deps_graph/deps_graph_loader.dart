// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:graphs/graphs.dart';

import '../asset/id.dart';
import 'deps_cycle.dart';
import 'deps_graph.dart';
import 'deps_node.dart';
import 'deps_node_loader.dart';

/// Loads a [DepsGraph].
class DepsGraphLoader {
  final Map<AssetId, DepsNode> _nodes = {};
  final Map<AssetId, DepsCycle> _cycles = {};
  final Map<AssetId, DepsGraph> _graphs = {};
  final DepsNodeLoader nodeLoader;

  DepsGraphLoader(this.nodeLoader);

  Future<void> load(AssetId id) async {
    final pendingIds = [id];

    while (pendingIds.isNotEmpty) {
      final nextId = pendingIds.removeLast();
      final node = await nodeLoader.load(nextId);
      _nodes[nextId] = node;
      if (node.deps != null) {
        for (final dep in node.deps!) {
          if (!_nodes.containsKey(dep)) {
            pendingIds.add(dep);
          }
        }
      }
    }

    _buildCycles();
    _buildGraph(id);
  }

  void _buildCycles() {
    final cycles = stronglyConnectedComponents(
      _nodes.values,
      (node) => node.deps == null ? [] : node.deps!.map((n) => _nodes[n]!),
    );
    for (final cycleNodes in cycles) {
      final cycle = DepsCycle((b) => b..nodes.replace(cycleNodes));
      for (final id in cycle.nodes.map((node) => node.id)) {
        _cycles[id] = cycle;
      }
    }
  }

  void _buildGraph(AssetId id) {
    final root = _cycles[id]!;
    final graph = DepsGraphBuilder()..root.replace(root);
    final building = <AssetId>{};
    building.addAll(root.nodes.map((node) => node.id));
    for (final node in root.nodes) {
      if (node.deps != null) {
        for (final dep in node.deps!) {
          if (building.contains(dep)) continue;
          _buildGraph(dep);
          graph.children.add(_graphs[dep]!);
        }
      }
    }
    _graphs[id] = graph.build();
  }

  BuiltSet<AssetId> transitiveDepsOf(int phase, AssetId id) {
    return _graphs[id]!.transitiveDeps;
  }
}
