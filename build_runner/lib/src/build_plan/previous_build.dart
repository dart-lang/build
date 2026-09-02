// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import '../build/build_state/asset_graph_json.dart';
import '../build/build_state/build_step_id.dart';
import '../build/build_state/build_step_result.dart';
import '../build/build_state/finished_build_state.dart';
import '../build/build_state/glob_id.dart';
import '../build/build_state/glob_result.dart';
import '../build/build_state/incremental_build_state.dart';
import '../build/build_state/post_process_build_step_id.dart';
import '../build/build_state/post_process_build_step_result.dart';
import '../build/library_cycle_graph/phased_asset_deps.dart';
import '../constants.dart';
import '../contracts.dart';

import 'build_packages.dart';
import 'build_spec.dart';
import 'build_spec_digest.dart';
import 'build_step_plan.dart';

part 'previous_build.g.dart';

/// Information about the previous build run and how it relates to the current
/// configuration.
@Invariant(
  'incrementalState == null || incompatibleBuildOutputsToDelete.isEmpty',
  'incrementalState == null || buildStepPlan != null',
  'buildStepPlan == null || '
      'phaseOptionsChangedList.length == '
      'buildStepPlan!.buildPhases.inBuildPhases.length',
  'buildStepPlan == null || '
      'postBuildOptionsChangedList.length == '
      'buildStepPlan!.buildPhases.postBuildPhase.builderActions.length',
  'incompatibleBuildOutputsToDelete.every('
      '(id) => id.package.isNotEmpty && id.path.isNotEmpty)',
)
abstract class PreviousBuild
    implements Built<PreviousBuild, PreviousBuildBuilder> {
  /// The `IncrementalBuildState` of the previous build, or null if it was
  /// missing or incompatible.
  IncrementalBuildState? get incrementalState;

  /// The build step plan from the previous build, or null.
  BuildStepPlan? get buildStepPlan;

  /// Phased asset dependencies from the previous run, or null.
  PhasedAssetDeps? get phasedAssetDeps;

  /// Whether the configuration triggers changed since the last run.
  bool get triggersChanged;

  /// Whether options changed per-phase.
  BuiltList<bool> get phaseOptionsChangedList;
  BuiltList<bool> get postBuildOptionsChangedList;

  /// If the previous build is not compatible, these are the package path
  /// outputs from it that should be deleted.
  BuiltList<AssetId> get incompatibleBuildOutputsToDelete;

  factory PreviousBuild([void Function(PreviousBuildBuilder) updates]) =
      _$PreviousBuild;

  @visibleForTesting
  factory PreviousBuild.fromFinishedBuildState(
    FinishedBuildState finishedBuildState, {
    PhasedAssetDeps? phasedAssetDeps,
  }) => PreviousBuild((b) {
    b.triggersChanged = false;
    b.incrementalState.replace(finishedBuildState.incremental);
    b.buildStepPlan.replace(finishedBuildState.buildStepPlan);
    b.phaseOptionsChangedList.replace(
      List.filled(
        finishedBuildState.buildStepPlan.buildPhases.inBuildPhases.length,
        false,
      ),
    );
    b.postBuildOptionsChangedList.replace(
      List.filled(
        finishedBuildState
            .buildStepPlan
            .buildPhases
            .postBuildPhase
            .builderActions
            .length,
        false,
      ),
    );
    if (phasedAssetDeps != null) {
      b.phasedAssetDeps.replace(phasedAssetDeps);
    }
  });

  BuiltSet<AssetId> get sources =>
      incrementalState?.sources ?? BuiltSet<AssetId>();
  BuiltMap<AssetId, Digest> get digests =>
      incrementalState?.digests ?? BuiltMap<AssetId, Digest>();
  BuiltSet<AssetId> get missingSources =>
      incrementalState?.missingSources ?? BuiltSet<AssetId>();
  BuiltMap<BuildStepId, BuildStepResult> get buildStepResults =>
      incrementalState?.buildStepResults ??
      BuiltMap<BuildStepId, BuildStepResult>();
  BuiltMap<PostProcessBuildStepId, PostProcessBuildStepResult>
  get postProcessResults =>
      incrementalState?.postProcessResults ??
      BuiltMap<PostProcessBuildStepId, PostProcessBuildStepResult>();
  BuiltMap<GlobId, GlobResult> get globResults =>
      incrementalState?.globResults ?? BuiltMap<GlobId, GlobResult>();

  @memoized
  BuiltMap<AssetId, PostProcessBuildStepId> get postProcessOutputs {
    final builder = MapBuilder<AssetId, PostProcessBuildStepId>();
    for (final entry in postProcessResults.entries) {
      for (final id in entry.value.outputs) {
        builder[id] = entry.key;
      }
    }
    return builder.build();
  }

  bool isSource(AssetId id) => sources.contains(id);
  bool isMissingSource(AssetId id) => missingSources.contains(id);

  BuildStepResult? stepResultOrNull(BuildStepId step) => buildStepResults[step];
  BuildStepResult stepResult(BuildStepId step) => stepResultOrNull(step)!;
  PostProcessBuildStepResult? postProcessBuildStepResultFor(
    PostProcessBuildStepId step,
  ) => postProcessResults[step];
  GlobResult? globResultFor(GlobId id) => globResults[id];

  Iterable<BuildStepResult> get actualStepResults => buildStepResults.values;
  Iterable<PostProcessBuildStepResult> get actualPostProcessResults =>
      postProcessResults.values;

  Iterable<AssetId> get actualOutputs =>
      buildStepResults.values.expand((r) => r.outputs);
  Iterable<AssetId> get actualPostOutputs => postProcessOutputs.keys;

  bool isActualPostOutput(AssetId id) => postProcessOutputs.containsKey(id);

  bool isActualOutput(AssetId id) {
    final step = buildStepPlan?.stepForDeclaredOutputOrNull(id);
    if (step == null) return false;
    return stepResultOrNull(step)?.outputs.contains(id) ?? false;
  }

  bool _isInArtifactTreePostProcessOutput(AssetId id) {
    final step = postProcessOutputs[id];
    if (step == null) return false;
    return postProcessResults[step]?.inArtifactTree ?? false;
  }

  /// Whether the output id is written in the artifact tree.
  bool isInArtifactTree(AssetId id) =>
      (buildStepPlan?.isDeclaredOutputInArtifactTree(id) ?? false) ||
      _isInArtifactTreePostProcessOutput(id);

  bool isFile(AssetId id) =>
      isSource(id) ||
      (buildStepPlan?.isDeclaredOutput(id) ?? false) ||
      isActualPostOutput(id);

  Digest? digestOf(AssetId id) => digests[id];

  /// Deserializes information about the previous build and compares it to
  /// [buildSpec] to determine whether an incremental build is possible.
  ///
  /// If so then [incrementalState], [buildStepPlan], and [phasedAssetDeps] hold
  /// detailed information about the previous build, and [triggersChanged],
  /// [phaseOptionsChangedList], and [postBuildOptionsChangedList] give more
  /// detail on compatibility.
  ///
  /// If the previous build cannot be used for an incremental build then
  /// [incompatibleBuildOutputsToDelete] is filled with its package path outputs
  /// that should be deleted.
  static Future<PreviousBuild> load(BuildSpec buildSpec) async {
    final readerWriter = buildSpec.readerWriter;
    final buildPackages = buildSpec.buildPackages;
    final buildPlanDigest = buildSpec.buildPlanDigest;
    final assetGraphJsonId = AssetId(
      buildPackages.outputRoot,
      assetGraphJsonPath,
    );
    BuildSpecDigest? previousBuildPlanDigest;
    IncrementalBuildState? incrementalBuildState;
    BuildStepPlan? previousBuildStepPlan;
    final incompatibleBuildOutputsToDelete = <AssetId>{};
    PhasedAssetDeps? previousPhasedAssetDeps;

    if (await readerWriter.canRead(assetGraphJsonId)) {
      final assetGraphJson = AssetGraphJson.deserialize(
        await readerWriter.readAsBytes(assetGraphJsonId) as Uint8List,
      );
      if (assetGraphJson != null) {
        incrementalBuildState = assetGraphJson.incrementalBuildState;
        previousBuildPlanDigest = assetGraphJson.buildPlanDigest;
        previousPhasedAssetDeps = assetGraphJson.phasedAssetDeps;
      }
      if (incrementalBuildState != null) {
        final forceCleanBuild =
            buildSpec.restartIsNeeded ||
            buildPackages.hasNewerAlternateRootBuild ||
            !buildPlanDigest.canIncrementallyBuildFrom(previousBuildPlanDigest);

        if (forceCleanBuild) {
          incompatibleBuildOutputsToDelete.addAll(
            _outputsToDelete(
              buildState: incrementalBuildState,
              buildPackages: buildPackages,
            ),
          );
          incrementalBuildState = null;
        } else {
          previousBuildStepPlan = BuildStepPlan.compute(
            buildPhases: buildSpec.buildPhases,
            placeholderIds: buildPackages.placeholderIds,
            sources: incrementalBuildState.sources,
          );
        }
      }
    }

    final triggersChanged = !buildPlanDigest.hasSameTriggersAs(
      previousBuildPlanDigest,
    );
    final phaseOptionsChanged = buildPlanDigest.computeChangedPhaseOptions(
      previousBuildPlanDigest,
    );
    final postBuildOptionsChanged = buildPlanDigest
        .computeChangedPostBuildOptions(previousBuildPlanDigest);

    return PreviousBuild((b) {
      b.incrementalState = incrementalBuildState?.toBuilder();
      if (previousBuildStepPlan != null) {
        b.buildStepPlan.replace(previousBuildStepPlan);
      }
      if (previousPhasedAssetDeps != null) {
        b.phasedAssetDeps.replace(previousPhasedAssetDeps);
      }
      b.triggersChanged = triggersChanged;
      b.phaseOptionsChangedList.replace(phaseOptionsChanged);
      b.postBuildOptionsChangedList.replace(postBuildOptionsChanged);
      b.incompatibleBuildOutputsToDelete.replace(
        incompatibleBuildOutputsToDelete,
      );
    });
  }

  /// Returns a new instance ready for the next incremental build.
  ///
  /// Sets state, content maps, and [previousPhasedAssetDeps].
  ///
  /// Clears `triggersChanged` and other fields related to checking whether an
  /// incremental build is possible.
  PreviousBuild updateForNextBuild({
    required FinishedBuildState finishedBuildState,
    required PhasedAssetDeps previousPhasedAssetDeps,
  }) => rebuild((b) {
    b.triggersChanged = false;
    b.incrementalState.replace(finishedBuildState.incremental);
    b.buildStepPlan.replace(finishedBuildState.buildStepPlan);
    b.phasedAssetDeps = previousPhasedAssetDeps.toBuilder();
    b.phaseOptionsChangedList.replace(
      List.filled(phaseOptionsChangedList.length, false),
    );
    b.postBuildOptionsChangedList.replace(
      List.filled(postBuildOptionsChangedList.length, false),
    );
    b.incompatibleBuildOutputsToDelete.clear();
  });

  PreviousBuild._();
}

/// Computes declared and post process outputs in [buildState] to delete for
/// [buildPackages].
Iterable<AssetId> _outputsToDelete({
  required IncrementalBuildState buildState,
  required BuildPackages buildPackages,
}) {
  final result = <AssetId>[];
  for (final stepResult in buildState.buildStepResults.values) {
    if (!stepResult.inArtifactTree) {
      for (final id in stepResult.outputs) {
        if (buildPackages.outputPackages.contains(id.package)) result.add(id);
      }
    }
  }
  for (final postProcessResult in buildState.postProcessResults.values) {
    if (!postProcessResult.inArtifactTree) {
      for (final id in postProcessResult.outputs) {
        if (buildPackages.outputPackages.contains(id.package)) result.add(id);
      }
    }
  }
  return result;
}
