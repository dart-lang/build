// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:watcher/watcher.dart';

import '../generate/phase.dart';
import '../package_graph/package_graph.dart';
import 'exceptions.dart';
import 'node.dart';

part 'serialization.dart';

/// All the [AssetId]s involved in a build, and all of their outputs.
class AssetGraph {
  /// A map of phase number to primary inputs that failed during that phase.
  ///
  /// See [markActionFailed] and [markActionSucceeded] for more info.
  final Map<int, Set<AssetId>> _failedActions;
  UnmodifiableMapView<int, Iterable<AssetId>> get failedActions =>
      new UnmodifiableMapView(_failedActions);

  /// All the [AssetNode]s in the graph, indexed by package and then path.
  final _nodesByPackage = <String, Map<String, AssetNode>>{};

  /// A [Digest] of the build actions this graph was originally created with.
  ///
  /// When an [AssetGraph] is deserialized we check whether or not it matches
  /// the new [BuildPhase]s and throw away the graph if it doesn't.
  final Digest buildPhasesDigest;

  /// The [Platform.version] this graph was created with.
  final String dartVersion;

  AssetGraph._(this.buildPhasesDigest, this.dartVersion,
      {Map<int, Set<AssetId>> failedActions})
      : _failedActions = failedActions ?? <int, Set<AssetId>>{};

  /// Deserializes this graph.
  factory AssetGraph.deserialize(List<int> serializedGraph) =>
      new _AssetGraphDeserializer(serializedGraph).deserialize();

  static Future<AssetGraph> build(
      List<BuildPhase> buildPhases,
      Set<AssetId> sources,
      Set<AssetId> internalSources,
      PackageGraph packageGraph,
      AssetReader digestReader) async {
    var graph = new AssetGraph._(
        computeBuildPhasesDigest(buildPhases), Platform.version);
    var placeholders = graph._addPlaceHolderNodes(packageGraph);
    var sourceNodes = graph._addSources(sources);
    graph._addBuilderOptionsNodes(buildPhases);
    graph._addOutputsForSources(buildPhases, sources, packageGraph.root.name,
        placeholders: placeholders);
    // Pre-emptively compute digests for the nodes we know have outputs.
    await graph._setLastKnownDigests(
        sourceNodes.where((node) => node.outputs.isNotEmpty), digestReader);
    // Always compute digests for all internal nodes.
    var internalNodes = graph._addInternalSources(internalSources);
    await graph._setLastKnownDigests(internalNodes, digestReader);
    return graph;
  }

  List<int> serialize() => new _AssetGraphSerializer(this).serialize();

  /// Checks if [id] exists in the graph.
  bool contains(AssetId id) =>
      _nodesByPackage[id.package]?.containsKey(id.path) ?? false;

  /// Gets the [AssetNode] for [id], if one exists.
  AssetNode get(AssetId id) {
    var pkg = _nodesByPackage[id?.package];
    if (pkg == null) return null;
    return pkg[id.path];
  }

  /// Marks an action in [phaseNumber] with [primaryInputId] as having failed.
  void markActionFailed(int phaseNumber, AssetId primaryInputId) {
    _failedActions
        .putIfAbsent(phaseNumber, () => new Set<AssetId>())
        .add(primaryInputId);
  }

  /// Marks an action in [phaseNumber] with [primaryInputId] as having
  /// succeeded.
  void markActionSucceeded(int phaseNumber, AssetId primaryInputId) {
    var phaseSet = _failedActions[phaseNumber];
    if (phaseSet == null) return;
    phaseSet.remove(primaryInputId);
    if (phaseSet.isEmpty) {
      _failedActions.remove(phaseNumber);
    }
  }

  /// Adds [node] to the graph if it doesn't exist.
  ///
  /// Throws a [StateError] if it already exists in the graph.
  void _add(AssetNode node) {
    var existing = get(node.id);
    if (existing != null) {
      if (existing is SyntheticSourceAssetNode) {
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

  /// Adds [assetIds] as [InternalAssetNode]s to this graph.
  Iterable<AssetNode> _addInternalSources(Set<AssetId> assetIds) sync* {
    for (var id in assetIds) {
      var node = new InternalAssetNode(id);
      _add(node);
      yield node;
    }
  }

  /// Adds [PlaceHolderAssetNode]s for every package in [packageGraph].
  Set<AssetId> _addPlaceHolderNodes(PackageGraph packageGraph) {
    var placeholders = placeholderIdsFor(packageGraph);
    for (var id in placeholders) {
      _add(new PlaceHolderAssetNode(id));
    }
    return placeholders;
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

  /// Adds [BuilderOptionsAssetNode]s for all [buildPhases] to this graph.
  void _addBuilderOptionsNodes(List<BuildPhase> buildPhases) {
    for (var phaseNum = 0; phaseNum < buildPhases.length; phaseNum++) {
      var phase = buildPhases[phaseNum];
      if (phase is InBuildPhase) {
        add(new BuilderOptionsAssetNode(
            builderOptionsIdForAction(phase, phaseNum),
            computeBuilderOptionsDigest(phase.builderOptions)));
      } else if (phase is PostBuildPhase) {
        var actionNum = 0;
        for (var builderAction in phase.builderActions) {
          add(new BuilderOptionsAssetNode(
              builderOptionsIdForAction(builderAction, actionNum),
              computeBuilderOptionsDigest(builderAction.builderOptions)));
          actionNum++;
        }
      } else {
        throw new StateError('Invalid action type $phase');
      }
    }
  }

  /// Uses [digestReader] to compute the [Digest] for [nodes] and set the
  /// `lastKnownDigest` field.
  Future<Null> _setLastKnownDigests(
      Iterable<AssetNode> nodes, AssetReader digestReader) async {
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
    for (var anchor in node.anchorOutputs.toList()) {
      _removeRecursive(anchor, removedIds: removedIds);
    }
    for (var output in node.primaryOutputs.toList()) {
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
        if (inputNode != null) {
          inputNode.outputs.remove(id);
          inputNode.primaryOutputs.remove(id);
        }
      }
      var builderOptionsNode = get(node.builderOptionsId);
      builderOptionsNode.outputs.remove(id);
      markActionSucceeded(node.phaseNumber, node.primaryInput);
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
      allNodes.where((n) => n.isGenerated).map((n) => n.id);

  /// All the generated outputs for a particular phase.
  Iterable<GeneratedAssetNode> outputsForPhase(String package, int phase) =>
      packageNodes(package)
          .where((n) => n is GeneratedAssetNode && n.phaseNumber == phase)
          .cast<GeneratedAssetNode>();

  /// All the source files in the graph.
  Iterable<AssetId> get sources =>
      allNodes.where((n) => n is SourceAssetNode).map((n) => n.id);

  /// Updates graph structure, invalidating and deleting any outputs that were
  /// affected.
  ///
  /// Returns the list of [AssetId]s that were invalidated.
  Future<Set<AssetId>> updateAndInvalidate(
      List<BuildPhase> buildPhases,
      Map<AssetId, ChangeType> updates,
      String rootPackage,
      Future delete(AssetId id),
      AssetReader digestReader) async {
    var invalidatedIds = new Set<AssetId>();

    // Transitively invalidates all assets.
    void invalidateNodeAndDeps(AssetId id, ChangeType rootChangeType,
        {bool forceUpdate: false}) {
      var node = get(id);
      if (node == null) return;
      if (!invalidatedIds.add(id)) return;

      if (node is GeneratedAssetNode) {
        node.state = GeneratedNodeState.mayNeedUpdate;
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

    var newAndModifiedNodes = modifyIds.map(get).toList()
      ..addAll(_addSources(newIds));
    // Pre-emptively compute digests for the new and modified nodes we know have
    // outputs.
    await _setLastKnownDigests(
        newAndModifiedNodes.where((node) =>
            node.isValidInput &&
            (node.outputs.isNotEmpty || node.lastKnownDigest != null)),
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
        _addOutputsForSources(buildPhases, newIds, rootPackage)
          ..addAll(transitiveRemovedIds);

    // For all new or deleted assets, check if they match any globs.
    for (var id in allNewAndDeletedIds) {
      var samePackageOutputNodes =
          packageNodes(id.package).where((node) => node is GeneratedAssetNode);
      for (GeneratedAssetNode node in samePackageOutputNodes) {
        if (node.globs.any((glob) => glob.matches(id.path))) {
          // The change type is irrelevant here.
          invalidateNodeAndDeps(node.id, null);
          // Override to the `definitelyNeedsUpdate` state for glob changes.
          //
          // The regular input hash checks won't pick up glob changes.
          node.state = GeneratedNodeState.definitelyNeedsUpdate;
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

  /// Crawl up primary inputs to see if the original Source file matches the
  /// glob on [action].
  bool _actionMatches(BuildAction action, AssetId input) {
    if (input.package != action.package) return false;
    if (!action.generateFor.matches(input)) return false;
    Iterable<String> inputExtensions;
    if (action is InBuildPhase) {
      inputExtensions = action.builder.buildExtensions.keys;
    } else if (action is PostBuildAction) {
      inputExtensions = action.builder.inputExtensions;
    } else {
      throw new StateError('Unrecognized action type $action');
    }
    if (!inputExtensions.any(input.path.endsWith)) {
      return false;
    }
    var inputNode = get(input);
    while (inputNode is GeneratedAssetNode) {
      inputNode = get((inputNode as GeneratedAssetNode).primaryInput);
    }
    return action.targetSources.matches(inputNode.id);
  }

  /// Returns a set containing [newSources] plus any new generated sources
  /// based on [buildPhases], and updates this graph to contain all the
  /// new outputs.
  ///
  /// If [placeholders] is supplied they will be added to [newSources] to create
  /// the full input set.
  Set<AssetId> _addOutputsForSources(
      List<BuildPhase> buildPhases, Set<AssetId> newSources, String rootPackage,
      {Set<AssetId> placeholders}) {
    var allInputs = new Set<AssetId>.from(newSources);
    if (placeholders != null) allInputs.addAll(placeholders);

    for (var phaseNum = 0; phaseNum < buildPhases.length; phaseNum++) {
      var phase = buildPhases[phaseNum];
      if (phase is InBuildPhase) {
        allInputs.addAll(_addInBuildPhaseOutputs(phase, phaseNum, allInputs));
      } else if (phase is PostBuildPhase) {
        _addPostBuildPhaseAnchors(phase, allInputs);
      } else {
        throw new StateError('Unrecognized phase type $phase');
      }
    }
    return allInputs;
  }

  /// Adds all [GeneratedAssetNode]s for [phase] given [allInputs].
  ///
  /// May remove some items from [allInputs], if they are deemed to actually be
  /// outputs of this phase an not original sources.
  ///
  /// Returns all newly created asset ids.
  Set<AssetId> _addInBuildPhaseOutputs(
      InBuildPhase phase, int phaseNum, Set<AssetId> allInputs) {
    var phaseOutputs = new Set<AssetId>();
    var buildOptionsNodeId = builderOptionsIdForAction(phase, phaseNum);
    var builderOptionsNode = get(buildOptionsNodeId) as BuilderOptionsAssetNode;
    var inputs =
        allInputs.where((input) => _actionMatches(phase, input)).toList();
    for (var input in inputs) {
      // We might have deleted some inputs during this loop, if they turned
      // out to be generated assets.
      if (!allInputs.contains(input)) continue;
      var node = get(input);
      assert(node != null, 'The node from `$input` does not exist.');

      var outputs = expectedOutputs(phase.builder, input);
      phaseOutputs.addAll(outputs);
      node.primaryOutputs.addAll(outputs);
      node.outputs.addAll(outputs);
      var deleted = _addGeneratedOutputs(outputs, phaseNum, builderOptionsNode,
          primaryInput: input, isHidden: phase.hideOutput);
      allInputs.removeAll(deleted);
      // We may delete source nodes that were producing outputs previously.
      // Detect this by checking for deleted nodes that no longer exist in the
      // graph at all, and remove them from `phaseOutputs`.
      phaseOutputs.removeAll(deleted.where((id) => !contains(id)));
    }
    return phaseOutputs;
  }

  /// Adds all [PostProcessAnchorNode]s for [phase] given [allInputs];
  ///
  /// Does not return anything because [PostProcessAnchorNode]s are synthetic
  /// and should not be treated as inputs.
  void _addPostBuildPhaseAnchors(PostBuildPhase phase, Set<AssetId> allInputs) {
    var actionNum = 0;
    for (var action in phase.builderActions) {
      var inputs = allInputs.where((input) => _actionMatches(action, input));
      for (var input in inputs) {
        var buildOptionsNodeId = builderOptionsIdForAction(action, actionNum);
        var anchor = new PostProcessAnchorNode.forInputAndAction(
            input, actionNum, buildOptionsNodeId);
        add(anchor);
        get(input).anchorOutputs.add(anchor.id);
      }
      actionNum++;
    }
  }

  /// Adds [outputs] as [GeneratedAssetNode]s to the graph.
  ///
  /// If there are existing [SourceAssetNode]s or [SyntheticSourceAssetNode]s
  /// that overlap the [GeneratedAssetNode]s, then they will be replaced with
  /// [GeneratedAssetNode]s, and all their `primaryOutputs` will be removed
  /// from the graph as well. The return value is the set of assets that were
  /// removed from the graph.
  Set<AssetId> _addGeneratedOutputs(Iterable<AssetId> outputs, int phaseNumber,
      BuilderOptionsAssetNode builderOptionsNode,
      {AssetId primaryInput, @required bool isHidden}) {
    var removed = new Set<AssetId>();
    for (var output in outputs) {
      // When any outputs aren't hidden we can pick up old generated outputs as
      // regular `AssetNode`s, we need to delete them and all their primary
      // outputs, and replace them with a `GeneratedAssetNode`.
      if (contains(output)) {
        var node = get(output);
        if (node is GeneratedAssetNode) {
          throw new DuplicateAssetNodeException(node);
        }
        _removeRecursive(output, removedIds: removed);
      }

      var newNode = new GeneratedAssetNode(output,
          phaseNumber: phaseNumber,
          primaryInput: primaryInput,
          state: GeneratedNodeState.definitelyNeedsUpdate,
          wasOutput: false,
          builderOptionsId: builderOptionsNode.id,
          isHidden: isHidden);
      builderOptionsNode.outputs.add(output);
      _add(newNode);
    }
    return removed;
  }

  @override
  String toString() => allNodes.toList().toString();

  // TODO remove once tests are updated
  void add(AssetNode node) => _add(node);
  Set<AssetId> remove(AssetId id) => _removeRecursive(id);
}

/// Computes a [Digest] for [buildPhases] which can be used to compare one set
/// of [BuildPhase]s against another.
Digest computeBuildPhasesDigest(Iterable<BuildPhase> buildPhases) {
  var digestSink = new AccumulatorSink<Digest>();
  var bytesSink = md5.startChunkedConversion(digestSink);
  bytesSink.add(buildPhases.map((phase) => phase.identity).toList());
  bytesSink.close();
  assert(digestSink.events.length == 1);
  return digestSink.events.first;
}

Digest computeBuilderOptionsDigest(BuilderOptions options) =>
    md5.convert(utf8.encode(json.encode(options.config)));

AssetId builderOptionsIdForAction(BuildAction action, int actionNum) {
  if (action is InBuildPhase) {
    return new AssetId(action.package, 'Phase$actionNum.builderOptions');
  } else if (action is PostBuildAction) {
    return new AssetId(action.package, 'PostPhase$actionNum.builderOptions');
  } else {
    throw new StateError('Unsupported action type $action');
  }
}

Set<AssetId> placeholderIdsFor(PackageGraph packageGraph) =>
    new Set<AssetId>.from(packageGraph.allPackages.keys.expand((package) => [
          new AssetId(package, r'lib/$lib$'),
          new AssetId(package, r'test/$test$'),
          new AssetId(package, r'web/$web$'),
        ]));
