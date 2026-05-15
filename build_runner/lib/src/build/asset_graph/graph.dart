// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:watcher/watcher.dart';

import '../../build_plan/build_packages.dart';
import '../../build_plan/build_phases.dart';
import '../../build_plan/build_plan.dart';
import '../../build_plan/phase.dart';
import '../../constants.dart';
import '../../io/generated_asset_hider.dart';
import 'build_step_id.dart';
import 'build_step_result.dart';
import 'exceptions.dart';
import 'glob_id.dart';
import 'glob_result.dart';
import 'node.dart';
import 'nodes.dart';
import 'post_process_build_step_id.dart';
import 'post_process_build_step_result.dart';
import 'serializers.dart';

part 'serialization.dart';

/// All the [AssetId]s involved in a build, and all of their outputs.
class AssetGraph implements GeneratedAssetHider {
  BuildPlan? buildPlan;

  /// All the [AssetNode]s in the graph.
  final Nodes _nodes;

  /// All post process build steps results, indexed by package then
  /// [PostProcessBuildStepId].
  ///
  /// Created with empty outputs at the start of the build if it's a new build
  /// step; or deserialized with previous build results if it has run before.
  final Map<String, Map<PostProcessBuildStepId, PostProcessBuildStepResult>>
  _postProcessBuildStepResults;

  /// All standard build step execution results, indexed by [BuildStepId].
  final Map<BuildStepId, BuildStepResult> _buildStepResults;

  final Map<GlobId, GlobResult> _globResults;

  final Map<AssetId, AssetId> _shadowPrimaryInputByOutput;

  AssetGraph()
    : _nodes = Nodes(),
      _postProcessBuildStepResults = {},
      _buildStepResults = {},
      _globResults = {},
      _shadowPrimaryInputByOutput = {};

  AssetGraph._with({
    required Nodes nodes,
    required Map<
      String,
      Map<PostProcessBuildStepId, PostProcessBuildStepResult>
    >
    postProcessBuildStepResults,
    required Map<BuildStepId, BuildStepResult> buildStepResults,
    required Map<GlobId, GlobResult> globResults,
    required Map<AssetId, AssetId> shadowPrimaryInputByOutput,
  }) : _nodes = nodes,
       _postProcessBuildStepResults = postProcessBuildStepResults,
       _buildStepResults = buildStepResults,
       _globResults = globResults,
       _shadowPrimaryInputByOutput = shadowPrimaryInputByOutput;

  /// Copies the graph prepared for the next build.
  AssetGraph copyForNextBuild() {
    return AssetGraph._with(
      nodes: _nodes.clone(),
      postProcessBuildStepResults: {
        for (final entry in _postProcessBuildStepResults.entries)
          entry.key: Map.of(entry.value),
      },
      buildStepResults: Map.of(_buildStepResults),
      globResults: Map.of(_globResults),
      shadowPrimaryInputByOutput: Map.of(_shadowPrimaryInputByOutput),
    );
  }

  /// Deserializes an [AssetGraph] from a [Map].
  ///
  /// Returns `null` if deserialization fails.
  @visibleForTesting
  static AssetGraph? deserialize(String serializedGraph) {
    try {
      final decodedMap = json.decode(serializedGraph);
      if (decodedMap is! Map) return null;
      return deserializeAssetGraph(decodedMap);
    } catch (_) {
      return null;
    }
  }

  static Future<AssetGraph> build(
    BuildPhases buildPhases,
    Set<AssetId> sources,
    BuildPackages buildPackages,
  ) async {
    final graph = AssetGraph();
    graph._addSources(sources);
    graph._addOutputsForSources(buildPhases, sources);
    return graph;
  }

  @visibleForTesting
  String serialize() => json.encode(serializeAssetGraph(this));

  Map<String, Map<PostProcessBuildStepId, PostProcessBuildStepResult>>
  get allPostProcessBuildStepResults => _postProcessBuildStepResults;

  // Forwards to [Nodes], see docs on that class.
  bool contains(AssetId id) => _nodes.contains(id);
  AssetNode? get(AssetId id) => _nodes.get(id);
  AssetNode updateNode(AssetId id, void Function(AssetNodeBuilder) updates) =>
      _nodes.updateNode(id, updates);
  AssetNode? updateNodeIfPresent(
    AssetId id,
    void Function(AssetNodeBuilder) updates,
  ) => _nodes.updateNodeIfPresent(id, updates);
  BuildStepResult? buildStepResultFor(BuildStepId buildStepId) =>
      _buildStepResults[buildStepId];
  BuildStepResult? buildStepResultForOutput(AssetId outputId) {
    for (final result in _buildStepResults.values) {
      if (result.outputDigests.containsKey(outputId)) {
        return result;
      }
    }
    return null;
  }

  void updateBuildStepResult(BuildStepId buildStepId, BuildStepResult result) {
    _buildStepResults[buildStepId] = result;
  }

  Map<BuildStepId, BuildStepResult> get buildStepResults => _buildStepResults;

  GlobResult? globResultFor(GlobId globId) => _globResults[globId];
  void updateGlobResult(GlobId globId, GlobResult result) {
    _globResults[globId] = result;
  }

  Map<GlobId, GlobResult> get globResults => _globResults;

  Iterable<AssetNode> get allNodes => _nodes.allNodes;
  Iterable<AssetId> packageFileIds(String package, {Glob? glob}) =>
      _nodes.packageFileIds(package, glob: glob);
  void removeForTest(AssetId id) => _nodes.remove(id);

  /// Adds [assetIds] as [AssetNode.source] to this graph, and returns the newly
  /// created nodes.
  void _addSources(Set<AssetId> assetIds) {
    for (final id in assetIds) {
      _nodes.add(AssetNode.source(id));
    }
  }

  Iterable<AssetId> primaryOutputsOf(AssetId id) {
    final normalOutputs =
        buildPlan != null
            ? buildPlan!.buildStepPlan.primaryOutputsOf(id)
            : _shadowPrimaryInputByOutput.entries
                .where((entry) => entry.value == id)
                .map((entry) => entry.key);
    final postOutputs = _postProcessBuildStepResults.values
        .expand((packageResults) => packageResults.entries)
        .where((entry) => entry.key.input == id)
        .expand((entry) => entry.value.outputs);
    return [...normalOutputs, ...postOutputs];
  }

  /// Changes [id] and its transitive`primaryOutput`s to `missingSource` nodes.
  ///
  /// Removes post build applications with removed assets as inputs.
  void _setMissingRecursive(AssetId id, {Set<AssetId>? removedIds}) {
    removedIds ??= <AssetId>{};
    final node = get(id);
    if (node == null) return;
    removedIds.add(id);
    for (final output in primaryOutputsOf(id).toList()) {
      _setMissingRecursive(output, removedIds: removedIds);
    }
    updateNode(id, (nodeBuilder) {
      nodeBuilder.replace(AssetNode.missingSource(id));
    });

    // Remove post build action applications with removed assets as inputs.
    for (final packageResults in _postProcessBuildStepResults.values) {
      packageResults.removeWhere((id, _) => removedIds!.contains(id.input));
    }
  }

  /// Removes [id] and its transitive`primaryOutput`s from the graph.
  void _removeRecursive(AssetId id, {Set<AssetId>? removedIds}) {
    removedIds ??= <AssetId>{};
    final node = get(id);
    if (node == null) return;
    if (removedIds.add(id)) {
      for (final output in primaryOutputsOf(id).toList()) {
        _removeRecursive(output, removedIds: removedIds);
      }
      _nodes.remove(id);
    }
  }

  /// All the post process build steps for `package`.
  Iterable<PostProcessBuildStepId> postProcessBuildStepIds({
    required String package,
  }) => _postProcessBuildStepResults[package]?.keys ?? const [];

  Iterable<AssetId> get allPostProcessOutputIds => _postProcessBuildStepResults
      .values
      .expand((entries) => entries.values.expand((v) => v.outputs));

  /// Creates or updates state for a [PostProcessBuildStepId].
  void updatePostProcessBuildStepResult(
    PostProcessBuildStepId buildStepId,
    PostProcessBuildStepResult result,
  ) {
    _postProcessBuildStepResults.putIfAbsent(
          buildStepId.input.package,
          () => {},
        )[buildStepId] =
        result;
  }

  /// Gets the result of a [PostProcessBuildStepId].
  ///
  /// These are set using [updatePostProcessBuildStepResult] during the build,
  /// then used to clean up prior outputs in the next build.
  PostProcessBuildStepResult? postProcessBuildStepResultFor(
    PostProcessBuildStepId action,
  ) => _postProcessBuildStepResults[action.input.package]?[action];

  /// All the generated outputs in the graph.
  Iterable<AssetId> get outputs =>
      allNodes.where((n) => n.isGenerated).map((n) => n.id);

  /// All the source files in the graph.
  Iterable<AssetId> get sources =>
      allNodes.where((n) => n.type == NodeType.source).map((n) => n.id);

  /// Updates graph structure, invalidating and deleting any outputs that were
  /// affected.
  ///
  /// Outputs that are deleted from the filesystem are retained in the graph as
  /// `missingSource` nodes.
  ///
  /// Returns the set of [AssetId]s to delete.
  Future<Set<AssetId>> updateAndInvalidate(
    BuildPhases buildPhases,
    Map<AssetId, ChangeType> updates,
  ) async {
    final newIds = <AssetId>{};
    final modifyIds = <AssetId>{};
    final removeIds = <AssetId>{};
    for (final entry in updates.entries) {
      final id = entry.key;
      final changeType = entry.value;
      final existingNode = get(id);

      /// Allow changes that are out of sync with the current graph state:
      /// handle an "add" of an existing asset as "modify", a "modify" of a
      /// missing asset as "add", and ignore a "remove" of a missing asset.
      switch (changeType) {
        case ChangeType.ADD:
        case ChangeType.MODIFY:
          if (existingNode == null ||
              existingNode.type == NodeType.missingSource) {
            newIds.add(id);
          } else {
            modifyIds.add(id);
          }
        case ChangeType.REMOVE:
          if (existingNode != null) removeIds.add(id);
      }
    }

    _addSources(newIds);

    // Compute generated nodes that will no longer be output because their
    // primary input was deleted. Delete them.
    final transitiveRemovedIds = <AssetId>{};
    void addTransitivePrimaryOutputs(AssetId id) {
      if (transitiveRemovedIds.add(id)) {
        primaryOutputsOf(id).forEach(addTransitivePrimaryOutputs);
      }
    }

    for (final id in removeIds) {
      final node = get(id);
      if (node != null && node.type == NodeType.source) {
        addTransitivePrimaryOutputs(id);
      }
    }

    // Change deleted source assets and their transitive primary outputs to
    // `missingSource` nodes, rather than deleting them. This allows them to
    // remain referenced in `inputs` in order to trigger rebuilds if necessary.
    for (final id in removeIds) {
      final node = get(id);
      if (node != null && node.type == NodeType.source) {
        _setMissingRecursive(id);
      }
    }

    _addOutputsForSources(buildPhases, newIds);

    _nodes.clearComputationResults();
    transitiveRemovedIds.removeAll(removeIds);
    return transitiveRemovedIds;
  }

  /// Crawl up primary inputs to see if the original Source file matches the
  /// glob on [action].
  bool _actionMatches(
    BuildAction action,
    AssetId input,
    Map<AssetId, AssetId> primaryInputByOutput,
  ) {
    if (input.package != action.package) return false;
    if (!action.generateFor.matches(input)) return false;

    if (action is InBuildPhase) {
      if (!action.builder.hasOutputFor(input)) return false;
    } else if (action is PostBuildAction) {
      final inputExtensions = action.builder.inputExtensions;
      if (!inputExtensions.any(input.path.endsWith)) {
        return false;
      }
    } else {
      throw StateError('Unrecognized action type $action');
    }

    var currentInput = input;
    while (primaryInputByOutput[currentInput] != null) {
      currentInput = primaryInputByOutput[currentInput]!;
    }
    return action.targetSources.matches(currentInput);
  }

  /// Returns a set containing [newSources] plus any new generated sources
  /// based on [buildPhases], and updates this graph to contain all the
  /// new outputs.
  ///
  /// May remove nodes if sources overlap with generated outputs.
  void _addOutputsForSources(BuildPhases buildPhases, Set<AssetId> newSources) {
    final allInputs = Set<AssetId>.from(newSources);
    final primaryInputByOutput = <AssetId, AssetId>{};
    for (
      var phaseNum = 0;
      phaseNum < buildPhases.inBuildPhases.length;
      phaseNum++
    ) {
      allInputs.addAll(
        _addInBuildPhaseOutputs(
          buildPhases.inBuildPhases[phaseNum],
          phaseNum,
          allInputs,
          buildPhases,
          primaryInputByOutput,
        ),
      );
    }
    _addPostBuildActionApplications(
      buildPhases.postBuildPhase,
      allInputs,
      primaryInputByOutput,
    );
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
    BuildPhases buildPhases,
    Map<AssetId, AssetId> primaryInputByOutput,
  ) {
    final phaseOutputs = <AssetId>{};
    final inputs =
        allInputs
            .where(
              (input) => _actionMatches(phase, input, primaryInputByOutput),
            )
            .toList();
    for (final input in inputs) {
      // We might have deleted some inputs during this loop, if they turned
      // out to be generated assets.
      if (!allInputs.contains(input)) continue;
      final outputs = expectedOutputs(phase.builder, input);
      phaseOutputs.addAll(outputs);
      for (final output in outputs) {
        primaryInputByOutput[output] = input;
        _shadowPrimaryInputByOutput[output] = input;
      }
      final deleted = _addGeneratedOutputs(outputs, phaseNum, buildPhases);
      allInputs.removeAll(deleted);
      // We may delete source nodes that were producing outputs previously.
      // Detect this by checking for deleted nodes that no longer exist in the
      // graph at all, and remove them from `phaseOutputs`.
      phaseOutputs.removeAll(deleted.where((id) => !contains(id)));
    }
    return phaseOutputs;
  }

  /// Adds all [PostProcessBuildStepId]s for [phase] given [allInputs];
  void _addPostBuildActionApplications(
    PostBuildPhase phase,
    Set<AssetId> allInputs,
    Map<AssetId, AssetId> primaryInputByOutput,
  ) {
    var actionNumber = 0;
    for (final action in phase.builderActions) {
      final inputs = allInputs.where(
        (input) => _actionMatches(action, input, primaryInputByOutput),
      );
      for (final input in inputs) {
        updatePostProcessBuildStepResult(
          PostProcessBuildStepId(input: input, actionNumber: actionNumber),
          PostProcessBuildStepResult(hidden: action.hideOutput),
        );
      }
      actionNumber++;
    }
  }

  /// Adds [outputs] as [AssetNode.generated]s to the graph.
  ///
  /// If there are existing [AssetNode.source]s or [AssetNode.missingSource]s
  /// that overlap the [AssetNode.generated]s, then they will be replaced with
  /// [AssetNode.generated]s, and their transitive `primaryOutputs` will be
  /// removed from the graph.
  ///
  /// The return value is the set of assets that were removed from the graph.
  Set<AssetId> _addGeneratedOutputs(
    Iterable<AssetId> outputs,
    int phaseNumber,
    BuildPhases buildPhases,
  ) {
    final removed = <AssetId>{};
    for (final output in outputs) {
      AssetNode? existing;
      // When any outputs aren't hidden we can pick up old generated outputs as
      // regular `AssetNode`s, we need to delete them and all their primary
      // outputs, and replace them with a `GeneratedAssetNode`.
      if (contains(output)) {
        existing = get(output)!;
        if (existing.type == NodeType.generated) {
          throw DuplicateAssetNodeException(
            existing.id,
            'an earlier phase',
            buildPhases.inBuildPhases[phaseNumber].displayName,
          );
        }
        _removeRecursive(output, removedIds: removed);
      }

      final newNode = AssetNode.generated(output);
      _nodes.add(newNode);
    }
    return removed;
  }

  @override
  String toString() => allNodes.toList().toString();

  void add(AssetNode node) => _nodes.add(node);

  /// Removes a generated node that was output by a post process build step.
  /// TODO(davidmorgan): look at removing them from the graph altogether.
  void removePostProcessOutput(AssetId id) => _nodes.remove(id);

  @override
  bool isHidden(AssetId id) {
    if (id.path.startsWith(generatedOutputDirectory) ||
        id.path.startsWith(cacheDirectoryPath)) {
      return false;
    }
    final config = buildPlan?.buildStepPlan.expectedOutputs[id];
    if (config != null) {
      return config.isHidden;
    }
    final stepResult = buildStepResultForOutput(id);
    if (stepResult != null) {
      return stepResult.isHidden ?? false;
    }
    return false;
  }

  bool wasOutput(AssetId id) {
    final node = get(id);
    if (node == null) return false;
    if (node.type == NodeType.postGenerated) {
      return true;
    }
    if (node.type == NodeType.generated) {
      final stepResult = buildStepResultForOutput(id);
      if (stepResult == null) return false;
      return stepResult.outputDigests.containsKey(id);
    }
    return false;
  }

  /// Returns outputs that were written to the source tree.
  Iterable<AssetId> outputsToDelete(BuildPackages buildPackages) {
    // Checks if `id` is in a known package. If so, returns it.
    //
    // If not, and a single package is being built, returns `id` moved to that
    // package. This allows old generated output to be deleted if the package
    // was renamed since the last build.
    //
    // If `id` is not in a known package and a single package is not being
    // built, returns `null`.
    AssetId? checkAndMoveId(AssetId id) {
      if (buildPackages[id.package] != null) {
        return id;
      }
      final singleOutputPackage = buildPackages.singleOutputPackage;
      if (singleOutputPackage == null) return null;
      return AssetId(singleOutputPackage, id.path);
    }

    final result = <AssetId>[];
    for (final stepResult in _buildStepResults.values) {
      if (!(stepResult.isHidden ?? false)) {
        for (final id in stepResult.outputDigests.keys) {
          final idToDelete = checkAndMoveId(id);
          if (idToDelete != null) result.add(idToDelete);
        }
      }
    }
    for (final packagePostProcessResults
        in _postProcessBuildStepResults.values) {
      for (final postProcessResults in packagePostProcessResults.values) {
        if (!postProcessResults.hidden) {
          for (final id in postProcessResults.outputs) {
            final idToDelete = checkAndMoveId(id);
            if (idToDelete != null) result.add(idToDelete);
          }
        }
      }
    }
    return result;
  }
}

Set<AssetId> placeholderIdsFor(BuildPackages buildPackages) =>
    Set<AssetId>.from(
      buildPackages.packages.keys.expand(
        (package) => [
          AssetId(package, r'lib/$lib$'),
          AssetId(package, r'test/$test$'),
          AssetId(package, r'web/$web$'),
          AssetId(package, r'$package$'),
        ],
      ),
    );
