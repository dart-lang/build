// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:watcher/watcher.dart';

import 'exceptions.dart';
import 'node.dart';

/// All the [AssetId]s involved in a build, and all of their outputs.
class AssetGraph {
  /// All the [AssetNode]s in the graph, indexed by [AssetId].
  final _nodesById = <AssetId, AssetNode>{};

  /// The start time of the most recent build which created this graph.
  ///
  /// Any assets which have been updated after this time should be invalidated
  /// on subsequent builds.
  ///
  /// This is initialized to a very old value, and should be set to a real
  /// value if you want incremental rebuilds.
  DateTime validAsOf = new DateTime.fromMillisecondsSinceEpoch(0);

  AssetGraph();

  /// Part of the serialized graph, used to ensure versioning constraints.
  ///
  /// This should be incremented any time the serialize/deserialize methods
  /// change on this class or [AssetNode].
  static int get _version => 3;

  /// Deserializes this graph.
  factory AssetGraph.deserialize(Map serializedGraph) {
    if (serializedGraph['version'] != AssetGraph._version) {
      throw new AssetGraphVersionException(
          serializedGraph['version'], _version);
    }

    var graph = new AssetGraph();
    for (var serializedItem in serializedGraph['nodes']) {
      graph.add(new AssetNode.deserialize(serializedItem));
    }
    graph.validAsOf =
        new DateTime.fromMillisecondsSinceEpoch(serializedGraph['validAsOf']);
    return graph;
  }

  /// Puts this graph into a serializable form.
  Map serialize() => {
        'version': _version,
        'nodes': allNodes.map((node) => node.serialize()).toList(),
        'validAsOf': validAsOf.millisecondsSinceEpoch,
      };

  /// Checks if [id] exists in the graph.
  bool contains(AssetId id) => _nodesById.containsKey(id);

  /// Gets the [AssetNode] for [id], if one exists.
  AssetNode get(AssetId id) => _nodesById[id];

  /// Adds [node] to the graph.
  void add(AssetNode node) {
    if (_nodesById.containsKey(node.id)) {
      throw new DuplicateAssetNodeException(node);
    }
    _nodesById[node.id] = node;
  }

  /// Adds the node returned by [ifAbsent] to the graph, if [id] doesn't
  /// already exist.
  ///
  /// Returns either the existing value or the one just added.
  AssetNode addIfAbsent(AssetId id, AssetNode ifAbsent()) =>
      _nodesById.putIfAbsent(id, ifAbsent);

  /// Removes the node representing [id] from the graph.
  AssetNode remove(AssetId id) => _nodesById.remove(id);

  /// Gets all nodes in the graph.
  Iterable<AssetNode> get allNodes => _nodesById.values;

  /// Invalidates all generated assets.
  ///
  /// If the build script has changed any Builder could have new behavior which
  /// would produce a different output.
  void invalidateBuildScript() {
    for (var node in allNodes) {
      if (node is GeneratedAssetNode) node.needsUpdate = true;
    }
  }

  /// Update graph structure, invalidate outputs that may change, and return the
  /// set of assets that need to be deleted.
  Iterable<AssetId> updateAndInvalidate(Map<AssetId, ChangeType> updates) {
    var deletes = new Set<AssetId>();
    var seen = new Set<AssetId>();
    void clearNodeAndDeps(AssetId id, ChangeType rootChangeType,
        {AssetId parent}) {
      if (seen.contains(id)) return;
      seen.add(id);
      var node = this.get(id);
      if (node == null) return;

      // Update all outputs of this asset as well.
      for (var output in node.outputs) {
        clearNodeAndDeps(output, rootChangeType, parent: node.id);
      }

      if (parent == null && rootChangeType == ChangeType.REMOVE) {
        // This is the root asset, it was removed on disk so it needs to be
        // removed from the graph.
        remove(id);
      }
      if (node is GeneratedAssetNode) {
        node.needsUpdate = true;
        if (rootChangeType == ChangeType.REMOVE &&
            node.primaryInput == parent) {
          remove(id);
          deletes.add(id);
        }
      }
    }

    updates.forEach(clearNodeAndDeps);
    return deletes;
  }

  @override
  String toString() => 'validAsOf: $validAsOf\n${_nodesById.values.toList()}';
}
