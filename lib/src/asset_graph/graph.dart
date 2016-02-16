// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../asset/id.dart';
import 'exceptions.dart';
import 'node.dart';

/// Represents all the [Asset]s in the system, and all of their dependencies.
class AssetGraph {
  /// All the [AssetNode]s in the system, indexed by [AssetId].
  final _nodesById = <AssetId, AssetNode>{};

  AssetGraph();

  /// Part of the serialized graph, used to ensure versioning constraints.
  ///
  /// This should be incremented any time the serialize/deserialize methods
  /// change on this class or [AssetNode].
  static get _version => 1;

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
    return graph;
  }

  /// Puts this graph into a serializable form.
  Map serialize() => {
        'version': _version,
        'nodes': allNodes.map((node) => node.serialize()).toList(),
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

  /// Removes [node] from the graph.
  AssetNode remove(AssetId id) => _nodesById.remove(id);

  /// Gets all nodes in the graph.
  Iterable<AssetNode> get allNodes => _nodesById.values;

  @override
  toString() => _nodesById.values.toList().toString();
}
