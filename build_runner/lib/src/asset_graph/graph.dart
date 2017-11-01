// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:build/build.dart';
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

  /// The start time of the most recent build which created this graph.
  ///
  /// Any assets which have been updated after this time should be invalidated
  /// on subsequent builds.
  ///
  /// This is initialized to a very old value, and should be set to a real
  /// value if you want incremental rebuilds.
  DateTime validAsOf = new DateTime.fromMillisecondsSinceEpoch(0);

  AssetGraph._();

  /// Deserializes this graph.
  factory AssetGraph.deserialize(Map serializedGraph) =>
      new _AssetGraphDeserializer(serializedGraph).deserialize();

  static Future<AssetGraph> build(
      List<BuildAction> buildActions,
      Set<AssetId> sources,
      String rootPackage,
      DigestAssetReader digestReader) async {
    var graph = new AssetGraph._();
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
        _remove(existing.id);
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

  /// Removes the node representing [id] from the graph.
  AssetNode _remove(AssetId id) => _nodesByPackage[id.package].remove(id.path);

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
    // All the assets that should be deleted.
    var idsToDelete = new Set<AssetId>();
    // All the assets that should be removed from the graph entirely.
    var idsToRemove = new Set<AssetId>();

    // Builds up `idsToDelete` and `idsToRemove` by recursively invalidating
    // the outputs of `id`.
    void clearNodeAndDeps(AssetId id, ChangeType rootChangeType,
        {bool rootIsSource}) {
      var node = this.get(id);
      if (node == null) return;
      if (!invalidatedIds.add(id)) return;
      rootIsSource ??= node is SourceAssetNode;

      if (node is GeneratedAssetNode) {
        idsToDelete.add(id);
        if (rootIsSource &&
            rootChangeType == ChangeType.REMOVE &&
            idsToRemove.contains(node.primaryInput)) {
          idsToRemove.add(id);
        } else {
          node.needsUpdate = true;
          node.wasOutput = false;
          node.globs = new Set();
        }
      } else {
        // This is a source
        if (rootChangeType == ChangeType.REMOVE) idsToRemove.add(id);
      }

      // Update all outputs of this asset as well.
      for (var output in node.outputs) {
        clearNodeAndDeps(output, rootChangeType, rootIsSource: rootIsSource);
      }
    }

    updates.forEach(clearNodeAndDeps);

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

    var allNewAndDeletedIds =
        _addOutputsForSources(buildActions, newIds, rootPackage)
          ..addAll(removeIds)
          ..addAll(idsToDelete);

    // For all new or deleted assets, check if they match any globs.
    for (var id in allNewAndDeletedIds) {
      var samePackageOutputNodes =
          packageNodes(id.package).where((n) => n is GeneratedAssetNode);
      for (var node in samePackageOutputNodes) {
        if ((node as GeneratedAssetNode)
            .globs
            .any((glob) => glob.matches(id.path))) {
          // The change type is irrelevant here.
          clearNodeAndDeps(node.id, null);
        }
      }
    }

    // Delete all the invalidated assets, then remove them from the graph. This
    // order is important because some `AssetWriter`s throw if the id is not in
    // the graph.
    await Future.wait(idsToDelete.map(delete));
    idsToRemove.forEach(_remove);

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
          _addGeneratedOutputs(outputs, phase);
        }
      } else if (action is AssetBuildAction) {
        var inputs = allInputs.where(action.inputSet.matches);
        for (var input in inputs) {
          var outputs = expectedOutputs(action.builder, input);
          phaseOutputs.addAll(outputs);
          var node = get(input);
          node.primaryOutputs.addAll(outputs);
          node.outputs.addAll(outputs);
          _addGeneratedOutputs(outputs, phase, primaryInput: input);
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
  /// Replaces any existing [AssetNode]s with [GeneratedAssetNode]s.
  void _addGeneratedOutputs(Iterable<AssetId> outputs, int phaseNumber,
      {AssetId primaryInput}) {
    for (var output in outputs) {
      // When `writeToCache` is false we can pick up old generated outputs as
      // regular `AssetNode`s, this deletes them.
      if (contains(output)) _remove(output);

      _add(new GeneratedAssetNode(
          phaseNumber, primaryInput, true, false, output));
    }
  }

  @override
  String toString() => 'validAsOf: $validAsOf\n${allNodes.toList()}';

  // TODO remove once tests are updated
  void add(AssetNode node) => _add(node);
  AssetNode remove(AssetId id) => _remove(id);
}
