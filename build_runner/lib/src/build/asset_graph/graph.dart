// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build/experiments.dart' as experiments_zone;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:watcher/watcher.dart';

import '../../build_plan/build_packages.dart';
import '../../build_plan/build_phases.dart';
import '../../build_plan/phase.dart';
import '../../constants.dart';
import '../../io/generated_asset_hider.dart';
import '../../io/reader_writer.dart';
import '../library_cycle_graph/phased_asset_deps.dart';
import 'exceptions.dart';
import 'node.dart';
import 'nodes.dart';
import 'post_process_build_step_id.dart';
import 'serializers.dart';

part 'serialization.dart';

/// All the [AssetId]s involved in a build, and all of their outputs.
class AssetGraph implements GeneratedAssetHider {
  /// All the [AssetNode]s in the graph.
  final Nodes _nodes;

  /// A digest of the generated build script kernel and inputs, if available.
  ///
  /// May be `null` in tests.
  final String? kernelDigest;

  /// A [Digest] of the build actions this graph was originally created with.
  ///
  /// When an [AssetGraph] is deserialized we check whether or not it matches
  /// the new [BuildPhase]s and throw away the graph if it doesn't.
  final Digest buildPhasesDigest;

  /// The [Platform.version] this graph was created with.
  final String dartVersion;

  /// The Dart language experiments that were enabled when this graph was
  /// originally created from the [build] constructor.
  final BuiltList<String> enabledExperiments;

  final BuiltMap<String, LanguageVersion?> packageLanguageVersions;

  /// All post process build steps outputs, indexed by package then
  /// [PostProcessBuildStepId].
  ///
  /// Created with empty outputs at the start of the build if it's a new build
  /// step; or deserialized with previous build outputs if it has run before.
  final Map<String, Map<PostProcessBuildStepId, Set<AssetId>>>
  _postProcessBuildStepOutputs;

  /// Digest of the previous build's `BuildTriggers`, or `null` if this is a
  /// clean build.
  Digest? previousBuildTriggersDigest;

  /// Digests from the previous build's [BuildPhases], or `null` if this is a
  /// clean build.
  BuiltList<Digest>? previousInBuildPhasesOptionsDigests;

  /// Digests from the current build's [BuildPhases].
  BuiltList<Digest> inBuildPhasesOptionsDigests;

  /// Digests from the previous build's [BuildPhases], or `null` if this is a
  /// clean build.
  BuiltList<Digest>? previousPostBuildActionsOptionsDigests;

  /// Digests from the current build's [BuildPhases].
  BuiltList<Digest> postBuildActionsOptionsDigests;

  /// Imports of resolved assets in the previous build, or `null` if this is a
  /// clean build.
  PhasedAssetDeps? previousPhasedAssetDeps;

  AssetGraph._(
    this.kernelDigest,
    BuildPhases buildPhases,
    this.dartVersion,
    this.packageLanguageVersions,
    this.enabledExperiments,
  ) : buildPhasesDigest = buildPhases.digest,
      inBuildPhasesOptionsDigests = buildPhases.inBuildPhasesOptionsDigests,
      postBuildActionsOptionsDigests =
          buildPhases.postBuildActionsOptionsDigests,
      _nodes = Nodes(),
      _postProcessBuildStepOutputs = {};

  AssetGraph._fromSerialized(
    this.kernelDigest,
    this.buildPhasesDigest,
    this.inBuildPhasesOptionsDigests,
    this.postBuildActionsOptionsDigests,
    this.dartVersion,
    this.packageLanguageVersions,
    this.enabledExperiments,
  ) : _nodes = Nodes(),
      _postProcessBuildStepOutputs = {};

  AssetGraph._with({
    required Nodes nodes,
    required this.kernelDigest,
    required this.buildPhasesDigest,
    required this.dartVersion,
    required this.enabledExperiments,
    required this.packageLanguageVersions,
    required Map<String, Map<PostProcessBuildStepId, Set<AssetId>>>
    postProcessBuildStepOutputs,
    required this.previousBuildTriggersDigest,
    required this.previousInBuildPhasesOptionsDigests,
    required this.inBuildPhasesOptionsDigests,
    required this.previousPostBuildActionsOptionsDigests,
    required this.postBuildActionsOptionsDigests,
    required this.previousPhasedAssetDeps,
  }) : _nodes = nodes,
       _postProcessBuildStepOutputs = postProcessBuildStepOutputs;

  @visibleForTesting
  AssetGraph copyWith({String? dartVersion}) => AssetGraph._with(
    nodes: _nodes,
    kernelDigest: kernelDigest,
    buildPhasesDigest: buildPhasesDigest,
    dartVersion: dartVersion ?? this.dartVersion,
    enabledExperiments: enabledExperiments,
    packageLanguageVersions: packageLanguageVersions,
    postProcessBuildStepOutputs: _postProcessBuildStepOutputs,
    previousBuildTriggersDigest: previousBuildTriggersDigest,
    previousInBuildPhasesOptionsDigests: previousInBuildPhasesOptionsDigests,
    inBuildPhasesOptionsDigests: inBuildPhasesOptionsDigests,
    previousPostBuildActionsOptionsDigests:
        previousPostBuildActionsOptionsDigests,
    postBuildActionsOptionsDigests: postBuildActionsOptionsDigests,
    previousPhasedAssetDeps: previousPhasedAssetDeps,
  );

  /// Copies the graph prepared for the next build with [buildPhases].
  AssetGraph copyForNextBuild(BuildPhases buildPhases) {
    // TODO(davidmorgan): clean up so there is a way to copy safely without
    // serializing then deserializing.
    final result = AssetGraph.deserialize(serialize())!;
    result.previousInBuildPhasesOptionsDigests =
        result.inBuildPhasesOptionsDigests;
    result.inBuildPhasesOptionsDigests =
        buildPhases.inBuildPhasesOptionsDigests;
    result.previousPostBuildActionsOptionsDigests =
        result.postBuildActionsOptionsDigests;
    result.postBuildActionsOptionsDigests =
        buildPhases.postBuildActionsOptionsDigests;
    return result;
  }

  /// Deserializes an [AssetGraph] from a [Map].
  ///
  /// Returns `null` if deserialization fails.
  static AssetGraph? deserialize(List<int> serializedGraph) =>
      deserializeAssetGraph(serializedGraph);

  static Future<AssetGraph> build(
    BuildPhases buildPhases,
    Set<AssetId> sources,
    BuildPackages buildPackages,
    ReaderWriter readerWriter, {
    String? kernelDigest,
  }) async {
    final graph = AssetGraph._(
      kernelDigest,
      buildPhases,
      Platform.version,
      buildPackages.languageVersions,
      experiments_zone.enabledExperiments.build(),
    );
    final placeholders = graph._addPlaceHolderNodes(buildPackages);
    graph._addSources(sources);
    graph._addOutputsForSources(
      buildPhases,
      sources,
      placeholders: placeholders,
    );
    // Pre-emptively compute digests for the nodes we know have outputs.
    await graph._setDigests(
      sources.where((id) => graph.get(id)?.primaryOutputs.isNotEmpty == true),
      readerWriter,
    );
    return graph;
  }

  List<int> serialize() => serializeAssetGraph(this);

  @visibleForTesting
  Map<String, Map<PostProcessBuildStepId, Set<AssetId>>>
  get allPostProcessBuildStepOutputs => _postProcessBuildStepOutputs;

  /// Whether this is a clean build, meaning there was no previous build state
  /// loaded or it was discarded as incompatible.
  bool get cleanBuild => previousInBuildPhasesOptionsDigests == null;

  // Forwards to [Nodes], see docs on that class.
  bool contains(AssetId id) => _nodes.contains(id);
  AssetNode? get(AssetId id) => _nodes.get(id);
  AssetNode updateNode(AssetId id, void Function(AssetNodeBuilder) updates) =>
      _nodes.updateNode(id, updates);
  Map<AssetId, Set<AssetId>> computeOutputs() => _nodes.computeOutputs();
  Iterable<AssetNode> get allNodes => _nodes.allNodes;
  Iterable<AssetId> packageFileIds(String package, {Glob? glob}) =>
      _nodes.packageFileIds(package, glob: glob);
  void removeForTest(AssetId id) => _nodes.remove(id);

  /// Adds [AssetNode.placeholder]s for every package in [buildPackages].
  Set<AssetId> _addPlaceHolderNodes(BuildPackages buildPackages) {
    final placeholders = placeholderIdsFor(buildPackages);
    for (final id in placeholders) {
      _nodes.add(AssetNode.placeholder(id));
    }
    return placeholders;
  }

  /// Adds [assetIds] as [AssetNode.source] to this graph, and returns the newly
  /// created nodes.
  void _addSources(Set<AssetId> assetIds) {
    for (final id in assetIds) {
      _nodes.add(AssetNode.source(id));
    }
  }

  /// Uses [readerWriter] to compute the [Digest] for nodes with [ids] and set
  /// the `lastKnownDigest` field.
  Future<void> _setDigests(
    Iterable<AssetId> ids,
    ReaderWriter readerWriter,
  ) async {
    for (final id in ids) {
      final digest = await readerWriter.digest(id);
      updateNode(id, (nodeBuilder) {
        nodeBuilder.digest = digest;
      });
    }
  }

  /// Changes [id] and its transitive`primaryOutput`s to `missingSource` nodes.
  ///
  /// Removes post build applications with removed assets as inputs.
  void _setMissingRecursive(AssetId id, {Set<AssetId>? removedIds}) {
    removedIds ??= <AssetId>{};
    final node = get(id);
    if (node == null) return;
    removedIds.add(id);
    for (final output in node.primaryOutputs.toList()) {
      _setMissingRecursive(output, removedIds: removedIds);
    }
    updateNode(id, (nodeBuilder) {
      nodeBuilder.replace(AssetNode.missingSource(id));
    });

    // Remove post build action applications with removed assets as inputs.
    for (final packageOutputs in _postProcessBuildStepOutputs.values) {
      packageOutputs.removeWhere((id, _) => removedIds!.contains(id.input));
    }
  }

  /// Removes [id] and its transitive`primaryOutput`s from the graph.
  void _removeRecursive(AssetId id, {Set<AssetId>? removedIds}) {
    removedIds ??= <AssetId>{};
    final node = get(id);
    if (node == null) return;
    if (removedIds.add(id)) {
      for (final output in node.primaryOutputs.toList()) {
        _removeRecursive(output, removedIds: removedIds);
      }
      _nodes.remove(id);
    }
  }

  /// All the post process build steps for `package`.
  Iterable<PostProcessBuildStepId> postProcessBuildStepIds({
    required String package,
  }) => _postProcessBuildStepOutputs[package]?.keys ?? const [];

  /// Creates or updates state for a [PostProcessBuildStepId].
  void updatePostProcessBuildStep(
    PostProcessBuildStepId buildStepId, {
    required Set<AssetId> outputs,
  }) {
    _postProcessBuildStepOutputs.putIfAbsent(
          buildStepId.input.package,
          () => {},
        )[buildStepId] =
        outputs;
  }

  /// Gets outputs of a [PostProcessBuildStepId].
  ///
  /// These are set using [updatePostProcessBuildStep] during the build, then
  /// used to clean up prior outputs in the next build.
  Iterable<AssetId> postProcessBuildStepOutputs(PostProcessBuildStepId action) {
    return _postProcessBuildStepOutputs[action.input.package]![action]!;
  }

  /// All the generated outputs in the graph.
  Iterable<AssetId> get outputs =>
      allNodes.where((n) => n.type == NodeType.generated).map((n) => n.id);

  /// All the generated outputs for a particular phase.
  Iterable<AssetNode> outputsForPhase(String package, int phase) =>
      packageFileIds(package)
          .map((id) => get(id)!)
          .where(
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
  /// Outputs that are deleted from the filesystem are retained in the graph as
  /// `missingSource` nodes.
  ///
  /// Returns the set of [AssetId]s that were deleted.
  Future<Set<AssetId>> updateAndInvalidate(
    BuildPhases buildPhases,
    Map<AssetId, ChangeType> updates,
    Future Function(AssetId id) delete,
    ReaderWriter readerWriter,
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

    final newAndModifiedNodes = [
      for (final id in modifyIds.followedBy(newIds)) get(id)!,
    ];
    // Pre-emptively compute digests for the new and modified nodes we know have
    // outputs.
    await _setDigests(
      newAndModifiedNodes
          .where(
            (node) =>
                node.isTrackedInput &&
                (node.primaryOutputs.isNotEmpty || node.digest != null),
          )
          .map((node) => node.id),
      readerWriter,
    );

    // Compute generated nodes that will no longer be output because their
    // primary input was deleted. Delete them.
    final transitiveRemovedIds = <AssetId>{};
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
    final idsToDelete = Set<AssetId>.from(transitiveRemovedIds)
      ..removeAll(removeIds);
    await Future.wait(idsToDelete.map(delete));

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
    return idsToDelete;
  }

  /// Crawl up primary inputs to see if the original Source file matches the
  /// glob on [action].
  bool _actionMatches(BuildAction action, AssetId input) {
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
  ///
  /// May remove nodes if sources overlap with generated outputs.
  void _addOutputsForSources(
    BuildPhases buildPhases,
    Set<AssetId> newSources, {
    Set<AssetId>? placeholders,
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
    _addPostBuildActionApplications(buildPhases.postBuildPhase, allInputs);
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
  ) {
    final phaseOutputs = <AssetId>{};
    final inputs =
        allInputs.where((input) => _actionMatches(phase, input)).toList();
    for (final input in inputs) {
      // We might have deleted some inputs during this loop, if they turned
      // out to be generated assets.
      if (!allInputs.contains(input)) continue;
      final outputs = expectedOutputs(phase.builder, input);
      phaseOutputs.addAll(outputs);
      updateNode(input, (nodeBuilder) {
        nodeBuilder.primaryOutputs.addAll(outputs);
      });
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
      phaseOutputs.removeAll(deleted.where((id) => !contains(id)));
    }
    return phaseOutputs;
  }

  /// Adds all [PostProcessBuildStepId]s for [phase] given [allInputs];
  void _addPostBuildActionApplications(
    PostBuildPhase phase,
    Set<AssetId> allInputs,
  ) {
    var actionNumber = 0;
    for (final action in phase.builderActions) {
      final inputs = allInputs.where((input) => _actionMatches(action, input));
      for (final input in inputs) {
        updatePostProcessBuildStep(
          PostProcessBuildStepId(input: input, actionNumber: actionNumber),
          outputs: {},
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
    BuildPhases buildPhases, {
    required AssetId primaryInput,
    required bool isHidden,
  }) {
    final removed = <AssetId>{};
    Map<AssetId, Set<AssetId>>? computedOutputsBeforeRemoves;
    for (final output in outputs) {
      AssetNode? existing;
      // When any outputs aren't hidden we can pick up old generated outputs as
      // regular `AssetNode`s, we need to delete them and all their primary
      // outputs, and replace them with a `GeneratedAssetNode`.
      if (contains(output)) {
        computedOutputsBeforeRemoves = _nodes.computeOutputs();
        existing = get(output)!;
        if (existing.type == NodeType.generated) {
          final existingConfiguration = existing.generatedNodeConfiguration!;
          throw DuplicateAssetNodeException(
            existing.id,
            buildPhases
                .inBuildPhases[existingConfiguration.phaseNumber]
                .displayName,
            buildPhases.inBuildPhases[phaseNumber].displayName,
          );
        }
        _removeRecursive(output, removedIds: removed);
      }

      final newNode = AssetNode.generated(
        output,
        phaseNumber: phaseNumber,
        primaryInput: primaryInput,
        isHidden: isHidden,
      );
      if (existing != null) {
        // Ensure we set up the reverse link for NodeWithInput nodes.
        _addInput(computedOutputsBeforeRemoves![output] ?? <AssetId>{}, output);
      }
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

  /// Adds [input] to all [outputs] if they track inputs.
  ///
  /// Nodes that track inputs are [AssetNode.generated] or [AssetNode.glob].
  void _addInput(Iterable<AssetId> outputs, AssetId input) {
    for (final output in outputs) {
      _nodes.updateNodeIfPresent(output, (nodeBuilder) {
        if (nodeBuilder.type == NodeType.generated) {
          nodeBuilder.generatedNodeState.inputs.add(input);
        } else if (nodeBuilder.type == NodeType.glob) {
          nodeBuilder.globNodeState.inputs.add(input);
        }
      });
    }
  }

  @override
  bool isHidden(AssetId id) {
    if (id.path.startsWith(generatedOutputDirectory) ||
        id.path.startsWith(cacheDirectoryPath)) {
      return false;
    }
    if (!contains(id)) {
      return false;
    }
    final assetNode = get(id)!;
    if (assetNode.type == NodeType.generated &&
        assetNode.generatedNodeConfiguration!.isHidden) {
      return true;
    }
    return false;
  }

  /// Returns outputs that were written to the source tree.
  Iterable<AssetId> outputsToDelete(BuildPackages buildPackages) {
    final result = <AssetId>[];
    // Delete all the non-hidden outputs.
    for (final id in outputs) {
      final node = get(id)!;
      final nodeConfiguration = node.generatedNodeConfiguration!;
      if (node.wasOutput && !nodeConfiguration.isHidden) {
        var idToDelete = id;
        // If the package no longer exists, then the user might have renamed
        // it. So move `idToDelete` to the single package being built, if there
        // is one, to delete for that case.
        if (buildPackages[id.package] == null) {
          final singleOutputPackage = buildPackages.singleOutputPackage;
          if (singleOutputPackage == null) continue;
          idToDelete = AssetId(singleOutputPackage, id.path);
        }
        result.add(idToDelete);
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
