// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build/experiments.dart' as experiments_zone;
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:built_collection/built_collection.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:package_config/package_config.dart';
import 'package:watcher/watcher.dart';

import '../generate/output_digests.dart';
import '../generate/phase.dart';
import '../package_graph/package_graph.dart';
import '../util/constants.dart';
import 'exceptions.dart';
import 'node.dart';

part 'serialization.dart';

/// All the [AssetId]s involved in a build, and all of their outputs.
class AssetGraph implements GeneratedAssetHider {
  /// All the [AssetNode]s in the graph, indexed by package and then path.
  final _nodesByPackage = <String, Map<String, AssetNode>>{};

  /// A [Digest] of the build actions this graph was originally created with.
  ///
  /// When an [AssetGraph] is deserialized we check whether or not it matches
  /// the new [BuildPhase]s and throw away the graph if it doesn't.
  final Digest buildPhasesDigest;

  /// The [Platform.version] this graph was created with.
  final String dartVersion;

  /// The Dart language experiments that were enabled when this graph was
  /// originally created from the [build] constructor.
  final List<String> enabledExperiments;

  final Map<String, LanguageVersion?> packageLanguageVersions;

  final BuilderOptionsDigests previousBuilderOptionsDigests;
  final BuilderOptionsDigests builderOptionsDigests = BuilderOptionsDigests();

  final FilesystemDigests previousFilesystemDigests;

  AssetGraph._(
    this.buildPhasesDigest,
    this.dartVersion,
    this.packageLanguageVersions,
    this.enabledExperiments,
    this.previousBuilderOptionsDigests,
    this.previousFilesystemDigests,
  );

  /// Deserializes this graph.
  factory AssetGraph.deserialize(List<int> serializedGraph) =>
      _AssetGraphDeserializer(serializedGraph).deserialize();

  static Future<AssetGraph> build(
    List<BuildPhase> buildPhases,
    Set<AssetId> sources,
    Set<AssetId> internalSources,
    PackageGraph packageGraph,
  ) async {
    var packageLanguageVersions = {
      for (var pkg in packageGraph.allPackages.values)
        pkg.name: pkg.languageVersion,
    };
    var graph = AssetGraph._(
      computeBuildPhasesDigest(buildPhases),
      Platform.version,
      packageLanguageVersions,
      experiments_zone.enabledExperiments,
      BuilderOptionsDigests(),
      const NoopFilesystemDigests(),
    );
    var placeholders = graph._addPlaceHolderNodes(packageGraph);
    graph._addSources(sources);
    graph
      .._addBuilderOptionsNodes(buildPhases)
      .._addInternalSources(internalSources)
      .._addOutputsForSources(
        buildPhases,
        sources,
        packageGraph.root.name,
        placeholders: placeholders,
      );
    return graph;
  }

  List<int> serialize(FilesystemDigests digests) =>
      _AssetGraphSerializer(this).serialize(digests);

  Future<void> computeDigests(AssetReader digestReader) async {
    await _setLastKnownDigests(
      allNodes
          .where(
            (node) =>
                (node.type == NodeType.source) ||
                (node.type == NodeType.internal),
          )
          .map((node) => node.id),
      digestReader,
    );
  }

  void prepareForSave(FilesystemDigests digests, OutputDigests outputDigests) {
    final seenIds = <AssetId>{};
    for (final entry in digests.digests) {
      final id = entry.key;
      seenIds.add(id);
      final filesystemDigest = entry.value;

      final node = get(entry.key);
      if (node == null) throw StateError('Missing node for $id');

      final nodeDigest = node.lastKnownDigest;

      if (filesystemDigest != nodeDigest) {
        /*throw StateError(
          'Digest mismatch for $id: '
          'filesystem: $filesystemDigest, node: $nodeDigest',
        );*/
      }
    }

    for (final node in allNodes) {
      if (node.type == NodeType.builderOptions ||
          node.type == NodeType.glob ||
          node.type == NodeType.generated) {
        continue;
      }
      if (node.lastKnownDigest != null && !seenIds.contains(node.id)) {
        throw StateError('Missing in FilesystemDigests: ${node.id}');
      }
    }

    for (final entry in outputDigests.digests) {
      updateNode(entry.key, (nodeBuilder) {
        nodeBuilder.lastKnownDigest = entry.value;
      });
    }
  }

  /// Checks if [id] exists in the graph.
  bool contains(AssetId id) =>
      _nodesByPackage[id.package]?.containsKey(id.path) ?? false;

  /// Gets the [AssetNode] for [id], if one exists.
  AssetNode? get(AssetId id) {
    var pkg = _nodesByPackage[id.package];
    if (pkg == null) return null;
    return pkg[id.path];
  }

  /// Updates a node in the graph with [updates].
  ///
  /// If it does not exist, [StateError] is thrown.
  ///
  /// Returns the updated node.
  AssetNode updateNode(AssetId id, void Function(AssetNodeBuilder) updates) {
    final node = get(id);
    if (node == null) throw StateError('Missing node: $id');
    final updatedNode = node.rebuild(updates);
    _nodesByPackage[id.package]![id.path] = updatedNode;
    if (updatedNode.id.path == 'lib/src/base/errors.dart') {
      print('Update $id here: ${StackTrace.current}');
    }
    return updatedNode;
  }

  /// Updates a node in the graph with [updates].
  ///
  /// If it does not exist, does nothing and returns `null`.
  ///
  /// If it does exist, returns the updated node.
  AssetNode? updateNodeIfPresent(
    AssetId id,
    void Function(AssetNodeBuilder) updates,
  ) {
    final node = get(id);
    if (node == null) return null;
    final updatedNode = node.rebuild(updates);
    _nodesByPackage[id.package]![id.path] = updatedNode;
    return updatedNode;
  }

  /// Adds [node] to the graph if it doesn't exist.
  ///
  /// Throws a [StateError] if it already exists in the graph.
  ///
  /// Returns the updated node: if it replaces an [AssetNode.missingSource] then
  /// `outputs` and `primaryOutputs` are copied to it from that.
  AssetNode _add(AssetNode node) {
    var existing = get(node.id);
    if (existing != null) {
      if (existing.type == NodeType.missingSource) {
        // Don't call _removeRecursive, that recursively removes all transitive
        // primary outputs. We only want to remove this node.
        _nodesByPackage[existing.id.package]!.remove(existing.id.path);
        node = node.rebuild(
          (b) =>
              b
                ..outputs.addAll(existing.outputs)
                ..primaryOutputs.addAll(existing.primaryOutputs),
        );
      } else {
        throw StateError(
          'Tried to add node ${node.id} to the asset graph but it already '
          'exists.',
        );
      }
    }
    _nodesByPackage.putIfAbsent(node.id.package, () => {})[node.id.path] = node;
    return node;
  }

  /// Adds [assetIds] as [AssetNode.internal].
  void _addInternalSources(Set<AssetId> assetIds) {
    for (var id in assetIds) {
      _add(AssetNode.internal(id));
    }
  }

  /// Adds [AssetNode.placeholder]s for every package in [packageGraph].
  Set<AssetId> _addPlaceHolderNodes(PackageGraph packageGraph) {
    var placeholders = placeholderIdsFor(packageGraph);
    for (var id in placeholders) {
      _add(AssetNode.placeholder(id));
    }
    return placeholders;
  }

  /// Adds [assetIds] as [AssetNode.source] to this graph, and returns the newly
  /// created nodes.
  void _addSources(Set<AssetId> assetIds) {
    for (final id in assetIds) {
      _add(AssetNode.source(id));
    }
  }

  /// Adds [AssetNode.builderOptions] for all [buildPhases] to this graph.
  void _addBuilderOptionsNodes(List<BuildPhase> buildPhases) {
    for (var phaseNum = 0; phaseNum < buildPhases.length; phaseNum++) {
      var phase = buildPhases[phaseNum];
      if (phase is InBuildPhase) {
        final id = builderOptionsIdForAction(phase, phaseNum);
        add(AssetNode.builderOptions(id));
        builderOptionsDigests.add(
          id,
          computeBuilderOptionsDigest(phase.builderOptions),
        );
      } else if (phase is PostBuildPhase) {
        var actionNum = 0;
        for (var builderAction in phase.builderActions) {
          final id = builderOptionsIdForAction(builderAction, actionNum);
          add(AssetNode.builderOptions(id));
          builderOptionsDigests.add(
            id,
            computeBuilderOptionsDigest(builderAction.builderOptions),
          );
          actionNum++;
        }
      } else {
        throw StateError('Invalid action type $phase');
      }
    }
  }

  /// Uses [digestReader] to compute the [Digest] for nodes with [ids] and set
  /// the `lastKnownDigest` field.
  Future<void> _setLastKnownDigests(
    Iterable<AssetId> ids,
    AssetReader digestReader,
  ) async {
    await digestReader.cache.invalidate(ids);
    await Future.wait(
      ids.map((id) async {
        final canRead = await digestReader.canRead(id);
        final digest = canRead ? await digestReader.digest(id) : null;
        updateNode(id, (nodeBuilder) {
          nodeBuilder.lastKnownDigest = digest;
        });
      }),
    );
  }

  /// Removes the node representing [id] from the graph, and all of its
  /// `primaryOutput`s.
  ///
  /// Also removes all edges between all removed nodes and remaining nodes.
  ///
  /// Returns the IDs of removed asset nodes.
  Set<AssetId> _removeRecursive(AssetId id, {Set<AssetId>? removedIds}) {
    removedIds ??= <AssetId>{};
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
      updateNodeIfPresent(output, (nodeBuilder) {
        if (nodeBuilder.type == NodeType.generated) {
          nodeBuilder.generatedNodeState.inputs.remove(id);
        } else if (nodeBuilder.type == NodeType.glob) {
          nodeBuilder.globNodeState
            ..inputs.remove(id)
            ..results.remove(id);
        }
      });
    }

    if (node.type == NodeType.generated) {
      for (var input in node.generatedNodeState!.inputs) {
        // We may have already removed this node entirely.
        updateNodeIfPresent(input, (nodeBuilder) {
          nodeBuilder
            ..outputs.remove(id)
            ..primaryOutputs.remove(id);
        });
      }
      updateNode(node.generatedNodeConfiguration!.builderOptionsId, (
        nodeBuilder,
      ) {
        nodeBuilder.outputs.remove(id);
      });
    } else if (node.type == NodeType.glob) {
      for (var input in node.globNodeState!.inputs) {
        // We may have already removed this node entirely.
        updateNodeIfPresent(input, (nodeBuilder) {
          nodeBuilder
            ..outputs.remove(id)
            ..primaryOutputs.remove(id);
        });
      }
    }

    // Missing source nodes need to be kept to retain dependency tracking.
    if (node.type != NodeType.missingSource) {
      _nodesByPackage[id.package]!.remove(id.path);
    }
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
      allNodes.where((n) => n.type == NodeType.generated).map((n) => n.id);

  /// The outputs which were, or would have been, produced by failing actions.
  Iterable<AssetNode> get failedOutputs => allNodes.where(
    (n) =>
        n.type == NodeType.generated &&
        n.generatedNodeState!.isFailure &&
        n.generatedNodeState!.pendingBuildAction == PendingBuildAction.none,
  );

  /// All the generated outputs for a particular phase.
  Iterable<AssetNode> outputsForPhase(String package, int phase) =>
      packageNodes(package).where(
        (n) =>
            n.type == NodeType.generated &&
            n.generatedNodeConfiguration!.phaseNumber == phase,
      );

  /// All the source files in the graph.
  Iterable<AssetId> get sources =>
      allNodes.where((n) => n.type == NodeType.source).map((n) => n.id);

  /// Updates graph structure, invalidating and deleting any outputs that were
  /// affected.
  ///
  /// Returns the list of [AssetId]s that were invalidated.
  Future<Set<AssetId>> updateAndInvalidate(
    List<BuildPhase> buildPhases,
    Map<AssetId, ChangeType> updates,
    String rootPackage,
    Future Function(AssetId id) delete,
    AssetReader digestReader,
  ) async {
    var newIds = <AssetId>{};
    var modifyIds = <AssetId>{};
    var removeIds = <AssetId>{};
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

    _addSources(newIds);
    var newAndModifiedNodes = [
      for (var id in modifyIds.followedBy(newIds)) get(id)!,
    ];
    // Pre-emptively compute digests for the new and modified nodes we know have
    // outputs.
    await _setLastKnownDigests(
      newAndModifiedNodes
          .where(
            (node) =>
                node.isTrackedInput &&
                (node.outputs.isNotEmpty ||
                    node.primaryOutputs.isNotEmpty ||
                    node.lastKnownDigest != null),
          )
          .map((node) => node.id),
      digestReader,
    );

    // Collects the set of all transitive ids to be removed from the graph,
    // based on the removed `SourceAssetNode`s by following the
    // `primaryOutputs`.
    var transitiveRemovedIds = <AssetId>{};
    void addTransitivePrimaryOutputs(AssetId id) {
      if (transitiveRemovedIds.add(id)) {
        get(id)!.primaryOutputs.forEach(addTransitivePrimaryOutputs);
      }
    }

    for (final id in removeIds) {
      final node = get(id);
      if (node != null && node.type == NodeType.source) {
        addTransitivePrimaryOutputs(id);
      }
    }

    // The generated nodes to actually delete from the file system.
    var idsToDelete = Set<AssetId>.from(transitiveRemovedIds)
      ..removeAll(removeIds);

    // We definitely need to update manually deleted outputs.
    for (var deletedOutput in removeIds
        .map(get)
        .nonNulls
        .where((n) => n.type == NodeType.generated)) {
      updateNode(deletedOutput.id, (nodeBuilder) {
        nodeBuilder.generatedNodeState.pendingBuildAction =
            PendingBuildAction.build;
      });
    }

    var newGeneratedOutputs = _addOutputsForSources(
      buildPhases,
      newIds,
      rootPackage,
    );
    var allNewAndDeletedIds = {...newGeneratedOutputs, ...transitiveRemovedIds};

    // Transitively invalidates all assets. This needs to happen after the
    // structure of the graph has been updated.
    var invalidatedIds = <AssetId>{};

    void invalidateNodeAndDeps(AssetId startNodeId) {
      if (!invalidatedIds.add(startNodeId)) return;
      var nodesToInvalidate = [startNodeId];

      while (nodesToInvalidate.isNotEmpty) {
        final nextNodes = nodesToInvalidate;
        nodesToInvalidate = [];
        for (final id in nextNodes) {
          final invalidatedNode = updateNodeIfPresent(id, (nodeBuilder) {
            if (nodeBuilder.type == NodeType.generated) {
              final nodeState = nodeBuilder.generatedNodeState;
              if (nodeState.pendingBuildAction == PendingBuildAction.none) {
                nodeBuilder.generatedNodeState.pendingBuildAction =
                    PendingBuildAction.buildIfInputsChanged;
              }
            } else if (nodeBuilder.type == NodeType.glob) {
              final nodeState = nodeBuilder.globNodeState;
              if (nodeState.pendingBuildAction == PendingBuildAction.none) {
                nodeBuilder.globNodeState.pendingBuildAction =
                    PendingBuildAction.buildIfInputsChanged;
              }
            }
          });

          if (invalidatedNode != null) {
            for (final id in invalidatedNode.outputs) {
              if (invalidatedIds.add(id)) {
                nodesToInvalidate.add(id);
              }
            }
          }
        }
      }
    }

    for (var changed in updates.keys.followedBy(newGeneratedOutputs)) {
      invalidateNodeAndDeps(changed);
    }

    // For all new or deleted assets, check if they match any glob nodes and
    // invalidate those.
    for (var id in allNewAndDeletedIds) {
      var samePackageGlobNodes = packageNodes(id.package).where(
        (n) =>
            n.type == NodeType.glob &&
            n.globNodeState!.pendingBuildAction == PendingBuildAction.none,
      );
      for (final node in samePackageGlobNodes) {
        final nodeConfiguration = node.globNodeConfiguration!;
        final glob = Glob(nodeConfiguration.glob);
        if (glob.matches(id.path)) {
          invalidateNodeAndDeps(node.id);
          updateNode(node.id, (nodeBuilder) {
            nodeBuilder.globNodeState.pendingBuildAction =
                PendingBuildAction.buildIfInputsChanged;
          });
        }
      }
    }

    // Delete all the invalidated assets, then remove them from the graph. This
    // order is important because some `AssetWriter`s throw if the id is not in
    // the graph.
    await Future.wait(idsToDelete.map(delete));

    // Remove all deleted source assets from the graph, which also recursively
    // removes all their primary outputs.
    for (final id in removeIds) {
      final node = get(id);
      if (node != null && node.type == NodeType.source) {
        invalidateNodeAndDeps(id);
        _removeRecursive(id);
      }
    }

    return invalidatedIds;
  }

  /// Crawl up primary inputs to see if the original Source file matches the
  /// glob on [action].
  bool _actionMatches(BuildAction action, AssetId input) {
    if (input.package != action.package) return false;
    if (!action.generateFor.matches(input)) return false;

    if (action is InBuildPhase) {
      if (!action.builder.hasOutputFor(input)) return false;
    } else if (action is PostBuildAction) {
      var inputExtensions = action.builder.inputExtensions;
      if (!inputExtensions.any(input.path.endsWith)) {
        return false;
      }
    } else {
      throw StateError('Unrecognized action type $action');
    }

    var inputNode = get(input)!;
    while (inputNode.type == NodeType.generated) {
      final inputNodeConfiguration = inputNode.generatedNodeConfiguration!;
      inputNode = get(inputNodeConfiguration.primaryInput)!;
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
    List<BuildPhase> buildPhases,
    Set<AssetId> newSources,
    String rootPackage, {
    Set<AssetId>? placeholders,
  }) {
    var allInputs = Set<AssetId>.from(newSources);
    if (placeholders != null) allInputs.addAll(placeholders);

    for (var phaseNum = 0; phaseNum < buildPhases.length; phaseNum++) {
      var phase = buildPhases[phaseNum];
      if (phase is InBuildPhase) {
        allInputs.addAll(
          _addInBuildPhaseOutputs(
            phase,
            phaseNum,
            allInputs,
            buildPhases,
            rootPackage,
          ),
        );
      } else if (phase is PostBuildPhase) {
        _addPostBuildPhaseAnchors(phase, allInputs);
      } else {
        throw StateError('Unrecognized phase type $phase');
      }
    }
    return allInputs;
  }

  /// Adds all [AssetNode.generated]s for [phase] given [allInputs].
  ///
  /// May remove some items from [allInputs], if they are deemed to actually be
  /// outputs of this phase and not original sources.
  ///
  /// Returns all newly created asset ids.
  Set<AssetId> _addInBuildPhaseOutputs(
    InBuildPhase phase,
    int phaseNum,
    Set<AssetId> allInputs,
    List<BuildPhase> buildPhases,
    String rootPackage,
  ) {
    var phaseOutputs = <AssetId>{};
    var buildOptionsNodeId = builderOptionsIdForAction(phase, phaseNum);
    var builderOptionsNode = get(buildOptionsNodeId)!;
    var inputs =
        allInputs.where((input) => _actionMatches(phase, input)).toList();
    for (var input in inputs) {
      // We might have deleted some inputs during this loop, if they turned
      // out to be generated assets.
      if (!allInputs.contains(input)) continue;
      var outputs = expectedOutputs(phase.builder, input);
      phaseOutputs.addAll(outputs);
      updateNode(input, (nodeBuilder) {
        nodeBuilder.primaryOutputs.addAll(outputs);
      });
      var deleted = _addGeneratedOutputs(
        outputs,
        phaseNum,
        builderOptionsNode,
        buildPhases,
        rootPackage,
        primaryInput: input,
        isHidden: phase.hideOutput,
      );
      allInputs.removeAll(deleted);
      // We may delete source nodes that were producing outputs previously.
      // Detect this by checking for deleted nodes that no longer exist in the
      // graph at all, and remove them from `phaseOutputs`.
      phaseOutputs.removeAll(deleted.where((id) => !contains(id)));
    }
    return phaseOutputs;
  }

  /// Adds all [AssetNode.postProcessAnchor]s for [phase] given [allInputs];
  ///
  /// Does not return anything because [AssetNode.postProcessAnchor]s are
  /// synthetic and should not be treated as inputs.
  void _addPostBuildPhaseAnchors(PostBuildPhase phase, Set<AssetId> allInputs) {
    var actionNum = 0;
    for (var action in phase.builderActions) {
      var inputs = allInputs.where((input) => _actionMatches(action, input));
      for (var input in inputs) {
        var buildOptionsNodeId = builderOptionsIdForAction(action, actionNum);
        var anchor = AssetNode.postProcessAnchorForInputAndAction(
          input,
          actionNum,
          buildOptionsNodeId,
        );
        add(anchor);
        updateNode(input, (nodeBuilder) {
          nodeBuilder.anchorOutputs.add(anchor.id);
        });
      }
      actionNum++;
    }
  }

  /// Adds [outputs] as [AssetNode.generated]s to the graph.
  ///
  /// If there are existing [AssetNode.source]s or [AssetNode.missingSource]s
  /// that overlap the [AssetNode.generated]s, then they will be replaced with
  /// [AssetNode.generated]s, and all their `primaryOutputs` will be removed
  /// from from the graph as well. The return value is the set of assets that
  /// were removed from the graph.
  Set<AssetId> _addGeneratedOutputs(
    Iterable<AssetId> outputs,
    int phaseNumber,
    AssetNode builderOptionsNode,
    List<BuildPhase> buildPhases,
    String rootPackage, {
    required AssetId primaryInput,
    required bool isHidden,
  }) {
    if (builderOptionsNode.type != NodeType.builderOptions) {
      throw ArgumentError('Expected node of type NodeType.builderOptionsNode');
    }
    var removed = <AssetId>{};
    for (var output in outputs) {
      AssetNode? existing;
      // When any outputs aren't hidden we can pick up old generated outputs as
      // regular `AssetNode`s, we need to delete them and all their primary
      // outputs, and replace them with a `GeneratedAssetNode`.
      if (contains(output)) {
        existing = get(output)!;
        if (existing.type == NodeType.generated) {
          final existingConfiguration = existing.generatedNodeConfiguration!;
          throw DuplicateAssetNodeException(
            rootPackage,
            existing.id,
            (buildPhases[existingConfiguration.phaseNumber] as InBuildPhase)
                .builderLabel,
            (buildPhases[phaseNumber] as InBuildPhase).builderLabel,
          );
        }
        _removeRecursive(output, removedIds: removed);
      }

      var newNode = AssetNode.generated(
        output,
        phaseNumber: phaseNumber,
        primaryInput: primaryInput,
        pendingBuildAction: PendingBuildAction.build,
        wasOutput: false,
        isFailure: false,
        builderOptionsId: builderOptionsNode.id,
        isHidden: isHidden,
      );
      if (existing != null) {
        newNode = newNode.rebuild((b) => b..outputs.addAll(existing!.outputs));
        // Ensure we set up the reverse link for NodeWithInput nodes.
        _addInput(existing.outputs, output);
      }
      updateNode(builderOptionsNode.id, (nodeBuilder) {
        nodeBuilder.outputs.add(output);
      });
      _add(newNode);
    }
    return removed;
  }

  @override
  String toString() => allNodes.toList().toString();

  // TODO remove once tests are updated
  void add(AssetNode node) => _add(node);
  Set<AssetId> remove(AssetId id) => _removeRecursive(id);

  /// Adds [input] to all [outputs] if they track inputs.
  ///
  /// Nodes that track inputs are [AssetNode.generated] or [AssetNode.glob].
  void _addInput(Iterable<AssetId> outputs, AssetId input) {
    for (var output in outputs) {
      updateNodeIfPresent(output, (nodeBuilder) {
        if (nodeBuilder.type == NodeType.generated) {
          nodeBuilder.generatedNodeState.inputs.add(input);
        } else if (nodeBuilder.type == NodeType.glob) {
          nodeBuilder.globNodeState.inputs.add(input);
        }
      });
    }
  }

  @override
  AssetId maybeHide(AssetId id, String rootPackage) {
    if (id.path.startsWith(generatedOutputDirectory) ||
        id.path.startsWith(cacheDir)) {
      return id;
    }
    if (!contains(id)) {
      return id;
    }
    final assetNode = get(id)!;
    if (assetNode.type == NodeType.generated &&
        assetNode.generatedNodeConfiguration!.isHidden) {
      return AssetId(
        rootPackage,
        '$generatedOutputDirectory/${id.package}/${id.path}',
      );
    }
    return id;
  }
}

/// Computes a [Digest] for [buildPhases] which can be used to compare one set
/// of [BuildPhase]s against another.
Digest computeBuildPhasesDigest(Iterable<BuildPhase> buildPhases) {
  var digestSink = AccumulatorSink<Digest>();
  md5.startChunkedConversion(digestSink)
    ..add(buildPhases.map((phase) => phase.identity).toList())
    ..close();
  assert(digestSink.events.length == 1);
  return digestSink.events.first;
}

Digest computeBuilderOptionsDigest(BuilderOptions options) =>
    md5.convert(utf8.encode(json.encode(options.config)));

AssetId builderOptionsIdForAction(BuildAction action, int actionNum) {
  if (action is InBuildPhase) {
    return AssetId(action.package, 'Phase$actionNum.builderOptions');
  } else if (action is PostBuildAction) {
    return AssetId(action.package, 'PostPhase$actionNum.builderOptions');
  } else {
    throw StateError('Unsupported action type $action');
  }
}

Set<AssetId> placeholderIdsFor(PackageGraph packageGraph) => Set<AssetId>.from(
  packageGraph.allPackages.keys.expand(
    (package) => [
      AssetId(package, r'lib/$lib$'),
      AssetId(package, r'test/$test$'),
      AssetId(package, r'web/$web$'),
      AssetId(package, r'$package$'),
    ],
  ),
);
