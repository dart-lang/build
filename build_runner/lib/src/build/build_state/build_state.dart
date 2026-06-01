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

  /// All standard build step execution results by [AssetId] then phase number.
  final Map<AssetId, Map<int, BuildStepResult>> _buildStepResultsByPrimaryInput;

  /// Declared outputs by primary input.
  final Map<AssetId, Set<AssetId>> _declaredOutputsByPrimaryInput;

  /// Build steps by primary output declared.
  final Map<AssetId, BuildStepId> _buildStepsByDeclaredOutput;

  /// Globs evaluated during the build.
  final Map<GlobId, GlobResult> _globResults;

  /// All post process build steps results by [AssetId] then action number.
  final Map<AssetId, Map<int, PostProcessBuildStepResult>>
  _postProcessResultsByInput;

  /// All post process build step outputs.
  final Set<AssetId> _postProcessOutputs;

  final Set<AssetId> _partOutputs;

  final Map<AssetId, AssetId> _primaryInputByPartOutput;

  @visibleForTesting
  BuildState.empty()
    : _sources = Sources(),
      _postProcessResultsByInput = {},
      _postProcessOutputs = {},
      _partOutputs = {},
      _primaryInputByPartOutput = {},
      _buildStepResultsByPrimaryInput = {},
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
    required Map<AssetId, Map<int, PostProcessBuildStepResult>>
    postProcessResultsByInput,
    required Set<AssetId> postProcessOutputs,
    required Set<AssetId> partOutputs,
    required Map<AssetId, AssetId> primaryInputByPartOutput,
    required Map<AssetId, Map<int, BuildStepResult>>
    buildStepResultsByPrimaryInput,
    required Map<GlobId, GlobResult> globResults,
    required Map<AssetId, BuildStepId> buildStepsByDeclaredOutput,
    required Map<AssetId, Set<AssetId>> declaredOutputsByPrimaryInput,
  }) : _postProcessOutputs = postProcessOutputs,
       _partOutputs = partOutputs,
       _primaryInputByPartOutput = primaryInputByPartOutput,
       _postProcessResultsByInput = postProcessResultsByInput,
       _globResults = globResults,
       _buildStepsByDeclaredOutput = buildStepsByDeclaredOutput,
       _declaredOutputsByPrimaryInput = declaredOutputsByPrimaryInput,
       _buildStepResultsByPrimaryInput = buildStepResultsByPrimaryInput,
       _sources = sources;

  /// Copies the state and prepares it for the next build.
  BuildState copyForNextBuild() {
    return BuildState._with(
      sources: _sources.clone(),
      postProcessResultsByInput: {
        for (final entry in _postProcessResultsByInput.entries)
          entry.key: Map.of(entry.value),
      },
      postProcessOutputs: Set.of(_postProcessOutputs),
      partOutputs: Set.of(_partOutputs),
      primaryInputByPartOutput: Map.of(_primaryInputByPartOutput),
      buildStepResultsByPrimaryInput: {
        for (final entry in _buildStepResultsByPrimaryInput.entries)
          entry.key: Map.of(entry.value),
      },
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

  /// All the build steps for [phase].
  Iterable<BuildStepId> buildStepsForPhase(String package, int phase) {
    final results = <BuildStepId>[];
    for (final entry in _buildStepResultsByPrimaryInput.entries) {
      final primaryInput = entry.key;
      if (primaryInput.package != package) continue;
      if (entry.value.containsKey(phase)) {
        results.add(
          BuildStepId(primaryInput: primaryInput, phaseNumber: phase),
        );
      }
    }
    return results;
  }

  /// Declared outputs and the phase in which they will be output.
  Map<AssetId, int> get declaredOutputPhases => {
    for (final entry in _buildStepsByDeclaredOutput.entries)
      entry.key: entry.value.phaseNumber,
  };

  /// Actual build step outputs.
  ///
  /// A subset of [declaredOutputs].
  Iterable<AssetId> get actualOutputs => _buildStepResultsByPrimaryInput.values
      .expand((map) => map.values.expand((result) => result.outputs.keys));

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
    ..._partOutputs,
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
      _buildStepResultsByPrimaryInput[buildStep.primaryInput]![buildStep
          .phaseNumber]!;



  /// Exposes all step results grouped by primary input.
  Map<AssetId, Map<int, BuildStepResult>> get buildStepResultsByPrimaryInput =>
      _buildStepResultsByPrimaryInput;

  /// Returns all phase step results for [primaryInput].
  Map<int, BuildStepResult>? stepResultsForPrimaryInput(AssetId primaryInput) =>
      _buildStepResultsByPrimaryInput[primaryInput];

  void addPartOutput(AssetId gpId, AssetId primaryInput) {
    _partOutputs.add(gpId);
    _primaryInputByPartOutput[gpId] = primaryInput;
  }

  bool isPartOutput(AssetId id) => _partOutputs.contains(id);

  AssetId primaryInputForPartOutput(AssetId gpId) =>
      _primaryInputByPartOutput[gpId]!;

  /// Updates a build step result after the step runs.
  void updateBuildStepResult(BuildStepId buildStepId, BuildStepResult result) {
    _buildStepResultsByPrimaryInput.putIfAbsent(
          buildStepId.primaryInput,
          () => {},
        )[buildStepId.phaseNumber] =
        result;
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
    final results = _postProcessResultsByInput.putIfAbsent(
      step.input,
      () => {},
    );
    if (results.containsKey(step.actionNumber)) {
      throw StateError('Already had post process result for $step.');
    }
    results[step.actionNumber] = result;
    _postProcessOutputs.addAll(result.outputs);
  }

  void removePostProcessBuildResult(PostProcessBuildStepId step) {
    final results = _postProcessResultsByInput[step.input];
    if (results == null) return;
    final oldResult = results.remove(step.actionNumber);
    if (oldResult != null) {
      _postProcessOutputs.removeAll(oldResult.outputs);
    }
    if (results.isEmpty) {
      _postProcessResultsByInput.remove(step.input);
    }
  }

  PostProcessBuildStepResult? postProcessBuildStepResultFor(
    PostProcessBuildStepId step,
  ) => _postProcessResultsByInput[step.input]?[step.actionNumber];

  Iterable<PostProcessBuildStepId> get failedPostProcessSteps {
    final results = <PostProcessBuildStepId>[];
    for (final outer in _postProcessResultsByInput.entries) {
      final input = outer.key;
      for (final inner in outer.value.entries) {
        if (inner.value.errors.isNotEmpty) {
          results.add(
            PostProcessBuildStepId(input: input, actionNumber: inner.key),
          );
        }
      }
    }
    return results;
  }

  Set<AssetId> get assetsDeletedByPostProcess {
    final result = <AssetId>{};
    for (final outer in _postProcessResultsByInput.entries) {
      final input = outer.key;
      for (final inner in outer.value.values) {
        if (inner.deletedPrimaryInput) {
          result.add(input);
          break;
        }
      }
    }
    return result;
  }

  // -- Build planning.

  /// Returns whether [action] should run for [input].
  bool actionMatches(BuildAction action, AssetId input) {
    if (input.package != action.package) return false;
    if (!action.generateFor.matches(input)) return false;

    if (action is InBuildPhase) {
      if (!action.builder.matchesInput(input)) return false;
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
    for (final results in _postProcessResultsByInput.values) {
      for (final postProcessResults in results.values) {
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
    final postProcessResults = _postProcessResultsByInput.remove(id);
    if (postProcessResults != null) {
      for (final result in postProcessResults.values) {
        _postProcessOutputs.removeAll(result.outputs);
      }
    }
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
      _buildStepResultsByPrimaryInput.remove(id);
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
    final buildStepId = BuildStepId(
      primaryInput: primaryInput,
      phaseNumber: phaseNumber,
    );
    final existingResults = _buildStepResultsByPrimaryInput[primaryInput];
    final existingResult = existingResults?[phaseNumber];
    final buildStepResultBuilder =
        existingResult?.toBuilder() ?? BuildStepResultBuilder();
    buildStepResultBuilder.isHidden = isHidden;
    _buildStepResultsByPrimaryInput.putIfAbsent(
          primaryInput,
          () => {},
        )[phaseNumber] =
        buildStepResultBuilder.build();

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

      _buildStepsByDeclaredOutput[output] = buildStepId;
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
    if (_partOutputs.contains(id)) {
      final primaryInput = _primaryInputByPartOutput[id];
      if (primaryInput != null) {
        final steps = _buildStepResultsByPrimaryInput[primaryInput];
        if (steps != null) {
          for (final stepResult in steps.values) {
            if (stepResult.succeeded && stepResult.partsWritten.isNotEmpty) {
              if (!stepResult.isHidden) {
                return false;
              }
            }
          }
        }
      }
      return true;
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
    final primaryInput = buildStepId.primaryInput;
    final phaseNumber = buildStepId.phaseNumber;
    final existingResults = _buildStepResultsByPrimaryInput[primaryInput];
    final existingResult = existingResults?[phaseNumber];
    if (existingResult == null) {
      _buildStepResultsByPrimaryInput.putIfAbsent(
        primaryInput,
        () => {},
      )[phaseNumber] = BuildStepResult((b) {
        b.isHidden = isHidden;
        if (digest != null) {
          b.outputs[id] = digest;
        }
      });
    } else {
      if (digest != null) {
        _buildStepResultsByPrimaryInput.putIfAbsent(
          primaryInput,
          () => {},
        )[phaseNumber] = existingResult.rebuild((b) => b..outputs[id] = digest);
      }
    }
  }
}
