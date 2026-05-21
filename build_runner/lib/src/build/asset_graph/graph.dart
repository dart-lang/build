// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:watcher/watcher.dart';

import '../../build_plan/build_packages.dart';
import '../../build_plan/build_phases.dart';
import '../../build_plan/phase.dart';
import '../../build_plan/placeholders.dart';
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
  /// All the [AssetNode]s in the graph.
  final Nodes _nodes;

  /// All standard build step execution results, indexed by [BuildStepId].
  final Map<BuildStepId, BuildStepResult> buildStepResults;

  /// Declared outputs by primary input.
  final Map<AssetId, Set<AssetId>> declaredOutputsByPrimaryInput;

  /// Build steps by primary output declared.
  final Map<AssetId, BuildStepId> buildStepsByDeclaredOutput;

  /// Globs evaluated during the build.
  final Map<GlobId, GlobResult> globResults;

  /// All post process build steps results, indexed by [PostProcessBuildStepId].
  final Map<PostProcessBuildStepId, PostProcessBuildStepResult>
  postProcessBuildStepResults;

  /// All post process build step outputs.
  final Set<AssetId> postProcessOutputs;

  AssetGraph()
    : _nodes = Nodes(),
      postProcessBuildStepResults = {},
      postProcessOutputs = {},
      buildStepResults = {},
      declaredOutputsByPrimaryInput = {},
      globResults = {},
      buildStepsByDeclaredOutput = {};

  AssetGraph._with({
    required Nodes nodes,
    required this.postProcessBuildStepResults,
    required this.postProcessOutputs,
    required this.buildStepResults,
    required this.globResults,
    required this.buildStepsByDeclaredOutput,
    required this.declaredOutputsByPrimaryInput,
  }) : _nodes = nodes;

  /// Copies the graph prepared for the next build.
  AssetGraph copyForNextBuild() {
    return AssetGraph._with(
      nodes: _nodes.clone(),
      postProcessBuildStepResults: Map.of(postProcessBuildStepResults),
      postProcessOutputs: Set.of(postProcessOutputs),
      buildStepResults: Map.of(buildStepResults),
      globResults: Map.of(globResults),
      buildStepsByDeclaredOutput: Map.of(buildStepsByDeclaredOutput),
      declaredOutputsByPrimaryInput: {
        for (final entry in declaredOutputsByPrimaryInput.entries)
          entry.key: Set.of(entry.value),
      },
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
    graph._addOutputsForSources(
      buildPhases,
      sources,
      placeholders: buildPackages.placeholderIds,
    );
    return graph;
  }

  @visibleForTesting
  String serialize() => json.encode(serializeAssetGraph(this));

  AssetNode? get(AssetId id) => _nodes.get(id);
  AssetNode updateNode(AssetId id, void Function(AssetNodeBuilder) updates) =>
      _nodes.updateNode(id, updates);

  /// Whether [id) is a placeholder.
  bool isPlaceholder(AssetId id) => Placeholders.isPlaceholderPath(id.path);

  /// Whether [id] is one of: source, output or post process output.
  bool isKnownFile(AssetId id) =>
      isSource(id) || isDeclaredOutput(id) || isActualPostOutput(id);

  /// Whether [id) is a source file.
  bool isSource(AssetId id) => _nodes.get(id)?.type == NodeType.source;

  /// Whether [id] is a source file that was accessed but did not exist.
  bool isMissingSource(AssetId id) =>
      _nodes.get(id)?.type == NodeType.missingSource;

  /// Whether [id] is a declared build output.
  bool isDeclaredOutput(AssetId id) =>
      buildStepsByDeclaredOutput.containsKey(id);

  /// Whether [id] is a declared build output that was actually generated.
  bool isActualOutput(AssetId id) {
    final buildStepId = buildStepsByDeclaredOutput[id];
    if (buildStepId == null) return false;
    return buildStepResultFor(buildStepId)!.outputs.containsKey(id);
  }

  /// Whether [id] is a post process build output that was actually generated.
  bool isActualPostOutput(AssetId id) => postProcessOutputs.contains(id);

  BuildStepResult? buildStepResultFor(BuildStepId buildStepId) =>
      buildStepResults[buildStepId];
  void updateBuildStepResult(BuildStepId buildStepId, BuildStepResult result) {
    buildStepResults[buildStepId] = result;
  }

  GlobResult? globResultFor(GlobId globId) => globResults[globId];
  void updateGlobResult(GlobId globId, GlobResult result) {
    globResults[globId] = result;
  }

  Iterable<AssetNode> get allNodes => _nodes.allNodes;
  Iterable<AssetId> packageFileIds(String package, {Glob? glob}) =>
      _nodes.packageFileIds(package, [
        ...buildStepsByDeclaredOutput.keys,
        ...allPostProcessOutputIds,
      ], glob: glob);
  void removeForTest(AssetId id) => _nodes.remove(id);

  /// Adds [assetIds] as [AssetNode.source] to this graph, and returns the newly
  /// created nodes.
  void _addSources(Set<AssetId> assetIds) {
    for (final id in assetIds) {
      _nodes.add(AssetNode.source(id));
    }
  }

  Iterable<AssetId> primaryOutputsOf(AssetId id) =>
      declaredOutputsByPrimaryInput[id] ?? const [];

  // For use by tests and `_addInBuildPhaseOutputs`.
  @visibleForTesting
  void declareOutputs(AssetId id, Iterable<AssetId> outputs) {
    declaredOutputsByPrimaryInput.putIfAbsent(id, () => {}).addAll(outputs);
  }

  /// Changes [id] and its transitive`primaryOutput`s to `missingSource` nodes.
  ///
  /// Removes post build applications with removed assets as inputs.
  void _setMissingRecursive(AssetId id, {Set<AssetId>? removedIds}) {
    removedIds ??= <AssetId>{};
    removedIds.add(id);
    for (final output in primaryOutputsOf(id).toList()) {
      _setMissingRecursive(output, removedIds: removedIds);
    }
    buildStepsByDeclaredOutput.remove(id);
    declaredOutputsByPrimaryInput.remove(id);
    if (_nodes.contains(id)) {
      updateNode(id, (nodeBuilder) {
        nodeBuilder.replace(AssetNode.missingSource(id));
      });
    } else {
      _nodes.add(AssetNode.missingSource(id));
    }

    // Remove post build action applications with removed assets as inputs.
    postProcessBuildStepResults.removeWhere((id, result) {
      if (removedIds!.contains(id.input)) {
        postProcessOutputs.removeAll(result.outputs);
        return true;
      }
      return false;
    });
  }

  /// Removes [id] and its transitive`primaryOutput`s from the graph.
  void _removeRecursive(AssetId id, {Set<AssetId>? removedIds}) {
    removedIds ??= <AssetId>{};
    if (removedIds.add(id)) {
      for (final output in primaryOutputsOf(id).toList()) {
        _removeRecursive(output, removedIds: removedIds);
      }
      _nodes.remove(id);
      buildStepsByDeclaredOutput.remove(id);
      declaredOutputsByPrimaryInput.remove(id);
    }
  }

  Iterable<AssetId> get allPostProcessOutputIds => postProcessOutputs;

  /// Creates or updates state for a [PostProcessBuildStepId].
  void updatePostProcessBuildStepResult(
    PostProcessBuildStepId buildStepId,
    PostProcessBuildStepResult result,
  ) {
    final oldResult = postProcessBuildStepResults[buildStepId];
    if (oldResult != null) {
      postProcessOutputs.removeAll(oldResult.outputs);
    }
    postProcessBuildStepResults[buildStepId] = result;
    postProcessOutputs.addAll(result.outputs);
  }

  /// Gets the result of a [PostProcessBuildStepId].
  ///
  /// These are set using [updatePostProcessBuildStepResult] during the build,
  /// then used to clean up prior outputs in the next build.
  PostProcessBuildStepResult? postProcessBuildStepResultFor(
    PostProcessBuildStepId action,
  ) => postProcessBuildStepResults[action];

  /// All declared outputs in the graph.
  Iterable<AssetId> get outputs => [
    ...buildStepsByDeclaredOutput.keys,
    ...allPostProcessOutputIds,
  ];

  /// All declared outputs and the phases in which they are output.
  Map<AssetId, int> get outputPhases => {
    for (final entry in buildStepsByDeclaredOutput.entries)
      entry.key: entry.value.phaseNumber,
  };

  /// All the generated outputs for a particular phase.
  Iterable<AssetId> outputsForPhase(String package, int phase) =>
      packageFileIds(
        package,
      ).where((id) => buildStepsByDeclaredOutput[id]?.phaseNumber == phase);

  /// All source files.
  Iterable<AssetId> get sources =>
      allNodes.where((n) => n.type == NodeType.source).map((n) => n.id);

  /// All actual outputs.
  Iterable<AssetId> get actualOutputs =>
      buildStepResults.values.expand((result) => result.outputs.keys);

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
  bool actionMatches(BuildAction action, AssetId input) {
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
    while (true) {
      final buildStep = buildStepsByDeclaredOutput[currentInput];
      if (buildStep == null) break;
      currentInput = buildStep.primaryInput;
    }
    return action.targetSources.matches(currentInput);
  }

  /// Adds outputs for [newSources] and optionally [placeholders].
  ///
  /// May remove nodes if sources overlap with generated outputs.
  void _addOutputsForSources(
    BuildPhases buildPhases,
    Set<AssetId> newSources, {
    Iterable<AssetId>? placeholders,
  }) {
    final allInputs = Set<AssetId>.from(newSources);
    if (placeholders != null) allInputs.addAll(placeholders);
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
        ),
      );
    }
  }

  /// Adds all generated asset outputs for [phase] given [allInputs].
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
  ) {
    final phaseOutputs = <AssetId>{};
    final inputs =
        allInputs.where((input) => actionMatches(phase, input)).toList();
    for (final input in inputs) {
      // We might have deleted some inputs during this loop, if they turned
      // out to be generated assets.
      if (!allInputs.contains(input)) continue;
      final outputs = expectedOutputs(phase.builder, input);
      phaseOutputs.addAll(outputs);
      declareOutputs(input, outputs);
      final deleted = _addGeneratedOutputs(
        outputs,
        phaseNum,
        buildPhases,
        primaryInput: input,
        isHidden: phase.hideOutput,
      );
      allInputs.removeAll(deleted);
      // We may delete source nodes that were producing outputs previously.
      // Detect this by checking for deleted nodes that no longer exist in the
      // graph at all, and remove them from `phaseOutputs`.
      phaseOutputs.removeAll(deleted.where((id) => !isDeclaredOutput(id)));
    }
    return phaseOutputs;
  }

  /// Adds [outputs] to the graph.
  ///
  /// If there are existing source or missing source nodes
  /// that overlap the outputs, then they will be replaced,
  /// and their transitive `primaryOutputs` will be
  /// removed from the graph.
  ///
  /// The return value is the set of assets that were removed from the graph.
  Set<AssetId> _addGeneratedOutputs(
    Iterable<AssetId> outputs,
    int phaseNumber,
    BuildPhases buildPhases, {
    required AssetId primaryInput,
    required bool isHidden,
  }) {
    final removed = <AssetId>{};
    for (final output in outputs) {
      if (isSource(output)) {
        // An old generated source was picked up as a source file. Remove it and
        // its outputs.
        _removeRecursive(output, removedIds: removed);
      } else if (isDeclaredOutput(output)) {
        // The output was already declared by another builder.
        final buildStep = buildStepsByDeclaredOutput[output]!;
        final existingPhase = buildStep.phaseNumber;
        throw DuplicateAssetNodeException(
          output,
          buildPhases.inBuildPhases[existingPhase].displayName,
          buildPhases.inBuildPhases[phaseNumber].displayName,
        );
      }

      final buildStepId = BuildStepId(
        primaryInput: primaryInput,
        phaseNumber: phaseNumber,
      );
      buildStepsByDeclaredOutput[output] = buildStepId;
      final buildStepResultBuilder =
          buildStepResults[buildStepId]?.toBuilder() ??
          BuildStepResultBuilder();
      buildStepResultBuilder.isHidden = isHidden;
      buildStepResults[buildStepId] = buildStepResultBuilder.build();
    }
    return removed;
  }

  @override
  String toString() => allNodes.toList().toString();

  @visibleForTesting
  void add(AssetNode node) => _nodes.add(node);

  @visibleForTesting
  void addGeneratedForTest(
    AssetId id,
    BuildStepId buildStepId, {
    bool isHidden = true,
    Digest? digest,
  }) {
    buildStepsByDeclaredOutput[id] = buildStepId;
    final existingResult = buildStepResults[buildStepId];
    if (existingResult == null) {
      buildStepResults[buildStepId] = BuildStepResult((b) {
        b.isHidden = isHidden;
        if (digest != null) {
          b.outputs[id] = digest;
        }
      });
    } else {
      if (digest != null) {
        buildStepResults[buildStepId] = existingResult.rebuild(
          (b) => b..outputs[id] = digest,
        );
      }
    }
  }

  Digest? digestFor(AssetId id) {
    final buildStep = buildStepsByDeclaredOutput[id];
    if (buildStep != null) {
      return buildStepResultFor(buildStep)!.outputs[id];
    }
    final node = get(id);
    if (node == null) return null;
    return node.digest;
  }

  /// Updates a source file digest.
  ///
  /// Does nothing for generated files, their digest is set when the build step
  /// result is written.
  void updateSourceDigest(AssetId id, Digest? digest) {
    _nodes.updateNodeIfPresent(id, (b) => b.digest = digest);
  }

  /// Adds a source that a builder tried to access but was missing.
  void addMissingSource(AssetId id) => _nodes.add(AssetNode.missingSource(id));

  @override
  bool isHidden(AssetId id) {
    if (id.path.startsWith(generatedOutputDirectory) ||
        id.path.startsWith(cacheDirectoryPath)) {
      return false;
    }
    if (!isDeclaredOutput(id)) {
      return false;
    }
    final buildStepId = buildStepsByDeclaredOutput[id];
    if (buildStepId != null) {
      return buildStepResultFor(buildStepId)!.isHidden;
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
    // Delete all the non-hidden outputs.
    for (final id in actualOutputs) {
      if (!isHidden(id)) {
        final idToDelete = checkAndMoveId(id);
        if (idToDelete != null) result.add(idToDelete);
      }
    }
    for (final postProcessResults in postProcessBuildStepResults.values) {
      if (!postProcessResults.hidden) {
        for (final id in postProcessResults.outputs) {
          final idToDelete = checkAndMoveId(id);
          if (idToDelete != null) result.add(idToDelete);
        }
      }
    }
    return result;
  }
}
