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
  final Map<AssetId, int> _nodeReadPhases = {};
  final Map<int, Map<AssetId, DepsCycle>> _cycles = {};
  final Map<int, Map<AssetId, DepsGraph>> _graphs = {};
  final DepsNodeLoader nodeLoader;

  DepsGraphLoader(this.nodeLoader);

  Future<void> load(int phase, AssetId id) async {
    final pendingIds = [id];

    while (pendingIds.isNotEmpty) {
      final nextId = pendingIds.removeLast();
      final lastReadAt = _nodeReadPhases[nextId];

      if (lastReadAt != null && lastReadAt >= phase) {
        continue;
      }
      _nodeReadPhases[nextId] = phase;
      final node = await nodeLoader.load(phase, nextId);
      _nodes[nextId] = node;

      if (node.deps != null) {
        for (final dep in node.deps!) {
          final lastReadAt = _nodeReadPhases[dep];
          if (lastReadAt == null || lastReadAt < phase) {
            pendingIds.add(dep);
          }
        }
      }
    }
  }

  void _buildCycles(int phase) {
    if (_cycles.containsKey(phase)) return;
    final result = _cycles[phase] = {};
    final cycles = stronglyConnectedComponents(_nodes.values, (node) {
      final isHidden = node.isHidden(atPhase: phase);
      if (node.deps == null) {
        if (node.missing || isHidden) {
          return [];
        } else {
          _cycles.remove(phase);
          throw StateError(
            'Missing deps for $node; trying to read at phase $phase '
            'without calling load at that phase first.',
          );
        }
      }

      if (isHidden) {
        return [];
      }

      return node.deps!.map((n) => _nodes[n]!);
    });
    for (final cycleNodes in cycles) {
      final cycle = DepsCycle((b) => b..nodes.replace(cycleNodes));
      for (final id in cycle.nodes.map((node) => node.id)) {
        result[id] = cycle;
      }
    }
  }

  void _buildGraph(int phase, AssetId id) {
    final cycles = _cycles[phase]!;
    final graphs = _graphs[phase] ??= {};
    final root = cycles[id]!;
    final graph = DepsGraphBuilder()..root.replace(root);
    final building = <AssetId>{};
    building.addAll(root.nodes.map((node) => node.id));
    for (final node in root.nodes) {
      if (node.deps != null) {
        for (final dep in node.deps!) {
          if (building.contains(dep)) continue;
          final depNode = _nodes[dep]!;
          if (depNode.phase == null || depNode.phase! < phase) {
            _buildGraph(phase, dep);
            graph.children.add(graphs[dep]!);
          }
        }
      }
    }
    graphs[id] = graph.build();
  }

  BuiltSet<AssetId> transitiveDepsOf(int phase, AssetId id) {
    _buildCycles(phase);
    _buildGraph(phase, id);

    return _graphs[phase]![id]!.transitiveDeps;
  }
}
