// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:watcher/watcher.dart';

import '../asset/reader.dart';
import '../generate/exceptions.dart';
import '../generate/phase.dart';
import '../package_builder/package_builder.dart';
import 'exceptions.dart';
import 'node.dart';

part 'serialization.dart';

/// All the [AssetId]s involved in a build, and all of their outputs.
class AssetGraph {
  /// All the [AssetNode]s in the graph, indexed by package and then path.
  final _nodesByPackage = <String, Map<String, AssetNode>>{};

  /// A [Digest] of the build actions this graph was originally created with.
  ///
  /// When an [AssetGraph] is deserialized we check whether or not it matches
  /// the new [BuildAction]s and throw away the graph if it doesn't.
  final Digest buildActionsDigest;

  AssetGraph._(this.buildActionsDigest);

  /// Deserializes this graph.
  factory AssetGraph.deserialize(Map serializedGraph) =>
      new _AssetGraphDeserializer(serializedGraph).deserialize();

  static Future<AssetGraph> build(
      List<BuildAction> buildActions,
      Set<AssetId> sources,
      String rootPackage,
      DigestAssetReader digestReader) async {
    var graph = new AssetGraph._(computeBuildActionsDigest(buildActions));
    var newNodes = graph._addSources(sources);
    graph._addOutputsForSources(buildActions, sources, rootPackage);
    // Pre-emptively compute digests for the nodes we know have outputs.
    await graph._setLastKnownDigests(
        newNodes.where((node) => node.outputs.isNotEmpty), digestReader);
    return graph;
  }

  Map<String, dynamic> serialize() =>
      new _AssetGraphSerializer(this).serialize();

  /// Checks if [id] exists in the graph.
  bool contains(AssetId id) =>
      _nodesByPackage[id.package]?.containsKey(id.path) ?? false;

  /// Gets the [AssetNode] for [id], if one exists.
  AssetNode get(AssetId id) {
    var pkg = _nodesByPackage[id?.package];
    if (pkg == null) return null;
    return pkg[id.path];
  }

  /// Adds [node] to the graph if it doesn't exist.
  ///
  /// Throws a [StateError] if it already exists in the graph.
  void _add(AssetNode node) {
    var existing = get(node.id);
    if (existing != null) {
      if (existing is SyntheticAssetNode) {
        // Don't call _removeRecursive, that recursively removes all transitive
        // primary outputs. We only want to remove this node.
        _nodesByPackage[existing.id.package].remove(existing.id.path);
        node.outputs.addAll(existing.outputs);
        node.primaryOutputs.addAll(existing.primaryOutputs);
      } else {
        throw new StateError(
            'Tried to add node ${node.id} to the asset graph but it already '
            'exists.');
      }
    }
    _nodesByPackage.putIfAbsent(node.id.package, () => {})[node.id.path] = node;
  }

  /// Adds [assetIds] as [AssetNode]s to this graph, and returns the newly
  /// created nodes.
  List<AssetNode> _addSources(Set<AssetId> assetIds) {
    return assetIds.map((id) {
      var node = new SourceAssetNode(id);
      _add(node);
      return node;
    }).toList();
  }

  /// Uses [digestReader] to compute the [Digest] for [nodes] and set the
  /// `lastKnownDigest` field.
  Future<Null> _setLastKnownDigests(
      Iterable<AssetNode> nodes, DigestAssetReader digestReader) async {
    await Future.wait(nodes.map((node) async {
      node.lastKnownDigest = await digestReader.digest(node.id);
    }));
  }

  /// Removes the node representing [id] from the graph, and all of its
  /// `primaryOutput`s.
  ///
  /// Also removes all edges between all removed nodes and other nodes.
  ///
  /// Returns a [Set<AssetId>] of all removed nodes.
  Set<AssetId> _removeRecursive(AssetId id, {Set<AssetId> removedIds}) {
    removedIds ??= new Set<AssetId>();
    var node = get(id);
    if (node == null) return removedIds;
    removedIds.add(id);
    for (var output in node.primaryOutputs) {
      _removeRecursive(output, removedIds: removedIds);
    }
    for (var output in node.outputs) {
      var generatedNode = get(output) as GeneratedAssetNode;
      if (generatedNode != null) {
        generatedNode.inputs.remove(id);
      }
    }
    if (node is GeneratedAssetNode) {
      for (var input in node.inputs) {
        var inputNode = get(input);
        // We may have already removed this node entirely.
        if (inputNode != null) inputNode.outputs.remove(id);
      }
    }
    _nodesByPackage[id.package].remove(id.path);
    return removedIds;
  }

  /// All nodes in the graph, whether source files or generated outputs.
  Iterable<AssetNode> get allNodes =>
      _nodesByPackage.values.expand((pkdIds) => pkdIds.values);

  /// All nodes in the graph for `package`.
  Iterable<AssetNode> packageNodes(String package) =>
      _nodesByPackage[package]?.values ?? [];

  /// All the generated outputs in the graph.
  Iterable<AssetId> get outputs =>
      allNodes.where((n) => n is GeneratedAssetNode).map((n) => n.id);

  /// All the source files in the graph.
  Iterable<AssetId> get sources =>
      allNodes.where((n) => n is SourceAssetNode).map((n) => n.id);

  /// Updates graph structure, invalidating and deleting any outputs that were
  /// affected.
  ///
  /// Returns the list of [AssetId]s that were invalidated.
  Future<Set<AssetId>> updateAndInvalidate(
      List<BuildAction> buildActions,
      Map<AssetId, ChangeType> updates,
      String rootPackage,
      Future delete(AssetId id),
      DigestAssetReader digestReader) async {
    var invalidatedIds = new Set<AssetId>();

    // Transitively invalidates all assets.
    void invalidateNodeAndDeps(AssetId id, ChangeType rootChangeType) {
      var node = this.get(id);
      if (node == null) return;
      if (!invalidatedIds.add(id)) return;

      if (node is GeneratedAssetNode) {
        node.needsUpdate = true;
      }

      // Update all outputs of this asset as well.
      for (var output in node.outputs) {
        invalidateNodeAndDeps(output, rootChangeType);
      }
    }

    updates.forEach(invalidateNodeAndDeps);

    var newIds = new Set<AssetId>();
    var modifyIds = new Set<AssetId>();
    var removeIds = new Set<AssetId>();
    updates.forEach((id, changeType) {
      if (changeType != ChangeType.ADD && get(id) == null) return;
      switch (changeType) {
        case ChangeType.ADD:
          newIds.add(id);
          break;
        case ChangeType.MODIFY:
          modifyIds.add(id);
          break;
        case ChangeType.REMOVE:
          removeIds.add(id);
          break;
      }
    });

    var newAndModifiedNodes = modifyIds.map(this.get).toList()
      ..addAll(_addSources(newIds));
    // Pre-emptively compute digests for the new and modified nodes we know have
    // outputs.
    await _setLastKnownDigests(
        newAndModifiedNodes.where((node) => node.outputs.isNotEmpty),
        digestReader);

    // Collects the set of all transitive ids to be removed from the graph,
    // based on the removed `SourceAssetNode`s by following the
    // `primaryOutputs`.
    var transitiveRemovedIds = new Set<AssetId>();
    addTransitivePrimaryOutputs(AssetId id) {
      transitiveRemovedIds.add(id);
      get(id).primaryOutputs.forEach(addTransitivePrimaryOutputs);
    }

    removeIds
        .where((id) => get(id) is SourceAssetNode)
        .forEach(addTransitivePrimaryOutputs);

    // The generated nodes to actually delete from the file system.
    var idsToDelete = new Set<AssetId>.from(transitiveRemovedIds)
      ..removeAll(removeIds);

    // For manually deleted generated outputs, we bash away their
    // `previousInputsDigest` to make sure they actually get regenerated.
    for (var deletedOutput
        in removeIds.where((id) => get(id) is GeneratedAssetNode)) {
      (get(deletedOutput) as GeneratedAssetNode).previousInputsDigest = null;
    }

    var allNewAndDeletedIds =
        _addOutputsForSources(buildActions, newIds, rootPackage)
          ..addAll(transitiveRemovedIds);

    // For all new or deleted assets, check if they match any globs.
    for (var id in allNewAndDeletedIds) {
      var samePackageOutputNodes =
          packageNodes(id.package).where((n) => n is GeneratedAssetNode);
      for (var node in samePackageOutputNodes) {
        if ((node as GeneratedAssetNode)
            .globs
            .any((glob) => glob.matches(id.path))) {
          // The change type is irrelevant here.
          invalidateNodeAndDeps(node.id, null);
        }
      }
    }

    // Delete all the invalidated assets, then remove them from the graph. This
    // order is important because some `AssetWriter`s throw if the id is not in
    // the graph.
    await Future.wait(idsToDelete.map(delete));

    // Remove all deleted source assets from the graph, which also recursively
    // removes all their primary outputs.
    removeIds
        .where((id) => get(id) is SourceAssetNode)
        .forEach(_removeRecursive);

    return invalidatedIds;
  }

  /// Returns a set containing [newSources] plus any new generated sources
  /// based on [buildActions], and updates this graph to contain all the
  /// new outputs.
  Set<AssetId> _addOutputsForSources(List<BuildAction> buildActions,
      Set<AssetId> newSources, String rootPackage) {
    var allInputs = new Set<AssetId>.from(newSources);
    for (var phase = 0; phase < buildActions.length; phase++) {
      var phaseOutputs = <AssetId>[];
      var action = buildActions[phase];
      if (action is PackageBuildAction) {
        var outputs = outputIdsForBuilder(action.builder, action.package);
        var invalidOutputs = outputs.where(
            (o) => o.package != rootPackage && !o.path.startsWith('lib/'));
        if (invalidOutputs.isNotEmpty) {
          throw new InvalidPackageBuilderOutputsException(
              action, invalidOutputs, rootPackage);
        }
        // `PackageBuilder`s don't generally care about new files, so we only
        // add the outputs if they don't already exist.
        if (outputs.any((output) => !contains(output))) {
          phaseOutputs.addAll(outputs);
          allInputs.removeAll(_addGeneratedOutputs(outputs, phase));
        }
      } else if (action is AssetBuildAction) {
        var inputs = allInputs.where(action.inputSet.matches).toList();
        for (var input in inputs) {
          // We might have deleted some inputs during this loop, if they turned
          // out to be generated assets.
          if (!allInputs.contains(input)) continue;

          var outputs = expectedOutputs(action.builder, input);
          phaseOutputs.addAll(outputs);
          var node = get(input);
          node.primaryOutputs.addAll(outputs);
          node.outputs.addAll(outputs);
          allInputs.removeAll(
              _addGeneratedOutputs(outputs, phase, primaryInput: input));
        }
      } else {
        throw new InvalidBuildActionException.unrecognizedType(action);
      }
      allInputs.addAll(phaseOutputs);
    }
    return allInputs;
  }

  /// Adds [outputs] as [GeneratedAssetNode]s to the graph.
  ///
  /// If there are existing [SourceAssetNode]s or [SyntheticAssetNode]s  that
  /// overlap the [GeneratedAssetNode]s, then they will be replaced with
  /// [GeneratedAssetNode]s, and all their `primaryOutputs` will be removed
  /// from the graph as well. The return value is the set of assets that were
  /// removed from the graph.
  Set<AssetId> _addGeneratedOutputs(Iterable<AssetId> outputs, int phaseNumber,
      {AssetId primaryInput}) {
    var removed = new Set<AssetId>();
    for (var output in outputs) {
      // When `writeToCache` is false we can pick up old generated outputs as
      // regular `AssetNode`s, we need to delete them and all their primary
      // outputs, and replace them with a `GeneratedAssetNode`.
      if (contains(output)) {
        var node = get(output);
        if (node is GeneratedAssetNode) {
          throw new DuplicateAssetNodeException(node);
        }
        _removeRecursive(output, removedIds: removed);
      }

      _add(new GeneratedAssetNode(
          phaseNumber, primaryInput, true, false, output));
    }
    return removed;
  }

  @override
  String toString() => allNodes.toList().toString();

  // TODO remove once tests are updated
  void add(AssetNode node) => _add(node);
  Set<AssetId> remove(AssetId id) => _removeRecursive(id);
}

/// Computes a [Digest] for [buildActions] which can be used to compare one set
/// of [BuildAction]s against another.
Digest computeBuildActionsDigest(Iterable<BuildAction> buildActions) {
  var digestSink = new AccumulatorSink<Digest>();
  var bytesSink = md5.startChunkedConversion(digestSink);
  for (var action in buildActions) {
    bytesSink.add(UTF8.encode(action.package));
    if (action is AssetBuildAction) {
      bytesSink.add([0]);
      bytesSink.add([action.builder.runtimeType.toString().hashCode]);
      for (var glob in action.inputSet.globs) {
        bytesSink.add([glob.pattern.hashCode]);
      }
      for (var glob in action.inputSet.excludes) {
        bytesSink.add([glob.pattern.hashCode]);
      }
    } else if (action is PackageBuildAction) {
      bytesSink.add([1]);
      bytesSink.add([action.builder.runtimeType.toString().hashCode]);
    }
  }
  bytesSink.close();
  assert(digestSink.events.length == 1);
  return digestSink.events.first;
}
