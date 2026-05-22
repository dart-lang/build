// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
import 'post_process_build_step_id.dart';
import 'post_process_build_step_result.dart';
import 'serializers.dart';
import 'sources.dart';

part 'serialization.dart';

/// Build state that is updated during the build then serialized to allow a
/// follow-on incremental build.
///
/// - Sources and their digests; missing sources.
/// - Planned build steps, updated with results as the build progresses,
///   including digests of outputs and error messages.
/// - Glob results.
/// - Post process build step results.
class BuildState implements GeneratedAssetHider {
  /// Sources and missing sources.
  final Sources _sources;

  /// All standard build step execution results, indexed by [BuildStepId].
  final Map<BuildStepId, BuildStepResult> _buildStepResults;

  /// Declared outputs by primary input.
  final Map<AssetId, Set<AssetId>> _declaredOutputsByPrimaryInput;

  /// Build steps by primary output declared.
  final Map<AssetId, BuildStepId> _buildStepsByDeclaredOutput;

  /// Globs evaluated during the build.
  final Map<GlobId, GlobResult> _globResults;

  /// All post process build steps results, indexed by [PostProcessBuildStepId].
  final Map<PostProcessBuildStepId, PostProcessBuildStepResult>
  _postProcessBuildStepResults;

  /// All post process build step outputs.
  final Set<AssetId> _postProcessOutputs;

  @visibleForTesting
  BuildState.empty()
    : _sources = Sources(),
      _postProcessBuildStepResults = {},
      _postProcessOutputs = {},
      _buildStepResults = {},
      _declaredOutputsByPrimaryInput = {},
      _globResults = {},
      _buildStepsByDeclaredOutput = {};

  /// Creates from build phases, sources and packages.
  factory BuildState.create({
    required BuildPhases buildPhases,
    required BuildPackages buildPackages,
    required Set<AssetId> sources,
  }) {
    final result = BuildState.empty();
    result._sources.addAll(sources);
    result._addOutputsForSources(
      buildPhases,
      sources,
      placeholders: buildPackages.placeholderIds,
    );
    return result;
  }

  BuildState._with({
    required Sources sources,
    required Map<PostProcessBuildStepId, PostProcessBuildStepResult>
    postProcessBuildStepResults,
    required Set<AssetId> postProcessOutputs,
    required Map<BuildStepId, BuildStepResult> buildStepResults,
    required Map<GlobId, GlobResult> globResults,
    required Map<AssetId, BuildStepId> buildStepsByDeclaredOutput,
    required Map<AssetId, Set<AssetId>> declaredOutputsByPrimaryInput,
  }) : _postProcessOutputs = postProcessOutputs,
       _postProcessBuildStepResults = postProcessBuildStepResults,
       _globResults = globResults,
       _buildStepsByDeclaredOutput = buildStepsByDeclaredOutput,
       _declaredOutputsByPrimaryInput = declaredOutputsByPrimaryInput,
       _buildStepResults = buildStepResults,
       _sources = sources;

  /// Copies the state and prepares it for the next build.
  BuildState copyForNextBuild() {
    return BuildState._with(
      sources: _sources.clone(),
      postProcessBuildStepResults: Map.of(_postProcessBuildStepResults),
      postProcessOutputs: Set.of(_postProcessOutputs),
      buildStepResults: Map.of(_buildStepResults),
      globResults: Map.of(_globResults),
      buildStepsByDeclaredOutput: Map.of(_buildStepsByDeclaredOutput),
      declaredOutputsByPrimaryInput: {
        for (final entry in _declaredOutputsByPrimaryInput.entries)
          entry.key: Set.of(entry.value),
      },
    );
  }

  // --  Predicates over IDs and iterables over IDs.

  /// Whether [id] is a placeholder.
  ///
  /// Placeholders are virtual files that exist in every package. They can't be
  /// read, but they can be matched as inputs. This allows builders to generate
  /// a fixed list of outputs for any package.
  bool isPlaceholder(AssetId id) => Placeholders.isPlaceholderPath(id.path);

  /// Whether [id] is one of: source, declared output or actual post process
  /// output.
  bool isFile(AssetId id) =>
      isSource(id) || isDeclaredOutput(id) || isActualPostOutput(id);

  /// Files that are in [package] and match [glob].
  ///
  /// Checks sources and declared outputs. The declared outputs that match might
  /// not exist yet if their build step hasn't run, or might never exist if it
  /// runs but decides not to output them.
  ///
  /// Does not match post process outputs.
  Iterable<AssetId> findFiles({required String package, Glob? glob}) =>
      _sources.findFiles(package, declaredOutputs, glob: glob);

  /// Sources.
  ///
  /// Files that were on disk in all packages in the build when the build
  /// started, excluding any that were matched as prior `build_runner` outputs.
  Iterable<AssetId> get sources => _sources.sourceIds;

  /// Whether [id] is a source file.
  bool isSource(AssetId id) => _sources.isSource(id);

  /// Whether [id] is a source file that has never been read.
  ///
  /// That means it is not a primary input and has never been read by any
  /// builder as an additional input.
  bool isUnreadSource(AssetId id) => _sources.isUnreadSource(id);

  /// Whether [id] is a source file that was accessed but did not exist.
  bool isMissingSource(AssetId id) => _sources.isMissingSource(id);

  /// Declared build outputs.
  Iterable<AssetId> get declaredOutputs => _buildStepsByDeclaredOutput.keys;

  /// Whether [id] is a declared build output.
  bool isDeclaredOutput(AssetId id) =>
      _buildStepsByDeclaredOutput.containsKey(id);

  /// Declared outputs of [id].
  Iterable<AssetId> declaredOutputsOf(AssetId id) =>
      _declaredOutputsByPrimaryInput[id] ?? const [];

  /// All the declared outputs for [phase].
  Iterable<AssetId> declaredOutputsForPhase(String package, int phase) =>
      findFiles(
        package: package,
      ).where((id) => _buildStepsByDeclaredOutput[id]?.phaseNumber == phase);

  /// Declared outputs and the phase in which they will be output.
  Map<AssetId, int> get declaredOutputPhases => {
    for (final entry in _buildStepsByDeclaredOutput.entries)
      entry.key: entry.value.phaseNumber,
  };

  /// Actual build step outputs.
  ///
  /// A subset of [declaredOutputs].
  Iterable<AssetId> get actualOutputs =>
      _buildStepResults.values.expand((result) => result.outputs.keys);

  /// Whether [id] is a declared build output that was actually generated.
  bool isActualOutput(AssetId id) {
    final buildStepId = _buildStepsByDeclaredOutput[id];
    if (buildStepId == null) return false;
    return stepResult(buildStepId).outputs.containsKey(id);
  }

  /// Whether [id] is a declared build output that was actually generated by
  /// a build step that succeeded.
  bool isActualSuccessfulOutput(AssetId id) {
    final step = _buildStepsByDeclaredOutput[id];
    if (step == null) return false;
    final stepResult = this.stepResult(step);
    return stepResult.succeeded && stepResult.outputs.containsKey(id);
  }

  /// Post process outputs.
  ///
  /// Note that post process outputs happen after the main build, so during the
  /// main build this is either empty or is the post process outputs from the
  /// previous build.
  Iterable<AssetId> get actualPostOutputs => _postProcessOutputs;

  /// Whether [id] is a post process build output that was actually generated.
  bool isActualPostOutput(AssetId id) => _postProcessOutputs.contains(id);

  /// All declared outputs and all post process outputs.
  Iterable<AssetId> get declaredAndActualOutputs => [
    ..._buildStepsByDeclaredOutput.keys,
    ...actualPostOutputs,
  ];

  // -- Digests.

  /// Updates a source file digest.
  ///
  /// Does nothing for generated files, their digest is set when the build step
  /// result is written.
  void updateSourceDigest(AssetId id, Digest? digest) {
    _sources.updateDigestIfPresent(id, digest);
  }

  /// If [id] is a source or a declared output, returns the latest digest.
  ///
  /// Otherwise, returns `null`. In particular, post process outputs don't have
  /// their digests stored.
  Digest? digestOf(AssetId id) {
    if (isSource(id)) return _sources.digestOfSource(id);
    if (isDeclaredOutput(id)) {
      return stepResult(stepForDeclaredOutput(id)).outputs[id];
    }
    return null;
  }

  /// The digest of source [id], or `null` if it has not been read.
  ///
  /// Throws if it is not a source.
  Digest? digestOfSource(AssetId id) => _sources.digestOfSource(id);

  // -- Missing sources.

  /// Adds a source that a builder tried to access but was missing.
  ///
  /// The builder must check and find there is no declared output or
  /// source before calling this.
  void addMissingSource(AssetId id) => _sources.addMissing(id);

  // -- Build steps.

  /// The build step that declared [id].
  BuildStepId stepForDeclaredOutput(AssetId id) =>
      _buildStepsByDeclaredOutput[id]!;

  /// The result of [buildStep].
  BuildStepResult stepResult(BuildStepId buildStep) =>
      _buildStepResults[buildStep]!;

  /// Updates a build step result after the step runs.
  void updateBuildStepResult(BuildStepId buildStepId, BuildStepResult result) {
    _buildStepResults[buildStepId] = result;
  }

  // -- Globs.

  GlobResult? globResultFor(GlobId globId) => _globResults[globId];

  void updateGlobResult(GlobId globId, GlobResult result) {
    _globResults[globId] = result;
  }

  // -- Post process build steps.

  void addPostProcessBuildStepResult(
    PostProcessBuildStepId step,
    PostProcessBuildStepResult result,
  ) {
    final updated = _postProcessBuildStepResults.putIfAbsent(
      step,
      () => result,
    );
    if (!identical(updated, result)) {
      throw StateError('Already had post process result for $step.');
    }
    _postProcessOutputs.addAll(result.outputs);
  }

  void removePostProcessBuildResult(PostProcessBuildStepId step) {
    final oldResult = _postProcessBuildStepResults.remove(step);
    if (oldResult != null) {
      _postProcessOutputs.removeAll(oldResult.outputs);
    }
  }

  PostProcessBuildStepResult? postProcessBuildStepResultFor(
    PostProcessBuildStepId step,
  ) => _postProcessBuildStepResults[step];

  /// All [PostProcessBuildStepResult] by [PostProcessBuildStepId].
  Iterable<MapEntry<PostProcessBuildStepId, PostProcessBuildStepResult>>
  get postProcessBuildStepResults => _postProcessBuildStepResults.entries;

  // -- Build planning.

  /// Returns whether [action] should run for [input].
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
      final buildStep = _buildStepsByDeclaredOutput[currentInput];
      if (buildStep == null) break;
      currentInput = buildStep.primaryInput;
    }
    return action.targetSources.matches(currentInput);
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
    for (final postProcessResults in _postProcessBuildStepResults.values) {
      if (!postProcessResults.hidden) {
        for (final id in postProcessResults.outputs) {
          final idToDelete = checkAndMoveId(id);
          if (idToDelete != null) result.add(idToDelete);
        }
      }
    }
    return result;
  }

  // -- Creation of the state and updates for incremental builds.

  /// Updates for the next build.
  ///
  /// Returns the set of [AssetId]s to delete.
  Set<AssetId> updateForNextBuild(
    BuildPhases buildPhases,
    Map<AssetId, ChangeType> updates,
  ) {
    final newIds = <AssetId>{};
    final modifyIds = <AssetId>{};
    final removeIds = <AssetId>{};
    for (final entry in updates.entries) {
      final id = entry.key;
      final changeType = entry.value;
      switch (changeType) {
        case ChangeType.ADD:
        case ChangeType.MODIFY:
          if (!isSource(id) || isMissingSource(id)) {
            newIds.add(id);
          } else {
            modifyIds.add(id);
          }
        case ChangeType.REMOVE:
          if (isSource(id)) removeIds.add(id);
      }
    }

    _sources.addAll(newIds);

    // Compute declared outputs that will no longer be output because their
    // primary input was deleted. Delete them.
    final transitiveRemovedIds = <AssetId>{};
    void addTransitivePrimaryOutputs(AssetId id) {
      if (transitiveRemovedIds.add(id)) {
        declaredOutputsOf(id).forEach(addTransitivePrimaryOutputs);
      }
    }

    for (final id in removeIds) {
      if (isSource(id)) {
        addTransitivePrimaryOutputs(id);
      }
    }

    // Change deleted source assets and their transitive declared outputs to
    // missing sources, rather than deleting them. This allows them to remain
    // referenced in `inputs` in order to trigger rebuilds if necessary.
    for (final id in removeIds) {
      if (isSource(id)) {
        _setMissingRecursive(id);
      }
    }

    _addOutputsForSources(buildPhases, newIds);

    _sources.clearComputationResults();
    transitiveRemovedIds.removeAll(removeIds);
    return transitiveRemovedIds;
  }

  /// Changes [id] and its transitive primary outputs to missing sources.
  ///
  /// Removes post build applications with removed assets as inputs.
  void _setMissingRecursive(AssetId id, {Set<AssetId>? removedIds}) {
    removedIds ??= <AssetId>{};
    removedIds.add(id);
    for (final output in declaredOutputsOf(id).toList()) {
      _setMissingRecursive(output, removedIds: removedIds);
    }
    _buildStepsByDeclaredOutput.remove(id);
    _declaredOutputsByPrimaryInput.remove(id);
    _sources.setMissing(id);

    // Remove post build action applications with removed assets as inputs.
    _postProcessBuildStepResults.removeWhere((id, result) {
      if (removedIds!.contains(id.input)) {
        _postProcessOutputs.removeAll(result.outputs);
        return true;
      }
      return false;
    });
  }

  /// Removes [id] and its transitive declared outputs.
  void _removeRecursive(AssetId id, {Set<AssetId>? removedIds}) {
    removedIds ??= <AssetId>{};
    if (removedIds.add(id)) {
      for (final output in declaredOutputsOf(id).toList()) {
        _removeRecursive(output, removedIds: removedIds);
      }
      _sources.remove(id);
      _buildStepsByDeclaredOutput.remove(id);
      _declaredOutputsByPrimaryInput.remove(id);
    }
  }

  /// Adds outputs for [newSources] and optionally [placeholders].
  ///
  /// If a source now clashes with an output, it means an old generated output
  /// was incorrectly treated as a source. Clean that up: remove any outputs
  /// that were added because the output was treated as a source.
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
  /// Removes ids from [allInputs] if they are recognized as outputs of the
  /// phase.
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
      _declaredOutputsByPrimaryInput
          .putIfAbsent(input, () => {})
          .addAll(outputs);
      final deleted = _addGeneratedOutputs(
        outputs,
        phaseNum,
        buildPhases,
        primaryInput: input,
        isHidden: phase.hideOutput,
      );
      allInputs.removeAll(deleted);
      // We may delete sources that were producing outputs previously.
      // Detect this by checking for deleted files that are no longer declared
      // outputs, and remove them from `phaseOutputs`.
      phaseOutputs.removeAll(deleted.where((id) => !isDeclaredOutput(id)));
    }
    return phaseOutputs;
  }

  /// Adds [outputs] to the state.
  ///
  /// If there are existing source or missing sources that match outputs,
  /// replace them with outputs and remove incorrect transitive outputs.
  ///
  /// The return value is the set of assets that were removed from the
  /// build state.
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
        final buildStep = _buildStepsByDeclaredOutput[output]!;
        final existingPhase = buildStep.phaseNumber;
        throw DuplicateAssetIdException(
          output,
          buildPhases.inBuildPhases[existingPhase].displayName,
          buildPhases.inBuildPhases[phaseNumber].displayName,
        );
      }

      final buildStepId = BuildStepId(
        primaryInput: primaryInput,
        phaseNumber: phaseNumber,
      );
      _buildStepsByDeclaredOutput[output] = buildStepId;
      final buildStepResultBuilder =
          _buildStepResults[buildStepId]?.toBuilder() ??
          BuildStepResultBuilder();
      buildStepResultBuilder.isHidden = isHidden;
      _buildStepResults[buildStepId] = buildStepResultBuilder.build();
    }
    return removed;
  }

  // -- GeneratedAssetHider implementation.

  @override
  bool isHidden(AssetId id) {
    if (id.path.startsWith(generatedOutputDirectory) ||
        id.path.startsWith(cacheDirectoryPath)) {
      return false;
    }
    if (!isDeclaredOutput(id)) {
      return false;
    }
    final buildStepId = _buildStepsByDeclaredOutput[id];
    if (buildStepId != null) {
      return stepResult(buildStepId).isHidden;
    }
    return false;
  }

  // -- Testing.

  @visibleForTesting
  void addSourceForTest(AssetId id, {Digest? digest}) =>
      _sources.add(id, digest: digest);

  @visibleForTesting
  void addGeneratedForTest(
    AssetId id,
    BuildStepId buildStepId, {
    bool isHidden = true,
    Digest? digest,
  }) {
    _buildStepsByDeclaredOutput[id] = buildStepId;
    final existingResult = _buildStepResults[buildStepId];
    if (existingResult == null) {
      _buildStepResults[buildStepId] = BuildStepResult((b) {
        b.isHidden = isHidden;
        if (digest != null) {
          b.outputs[id] = digest;
        }
      });
    } else {
      if (digest != null) {
        _buildStepResults[buildStepId] = existingResult.rebuild(
          (b) => b..outputs[id] = digest,
        );
      }
    }
  }
}
