// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import '../build/build_state/asset_graph_json.dart';
import '../build/build_state/finished_build_state.dart';
import '../build/build_state/incremental_build_state.dart';
import '../build/library_cycle_graph/phased_asset_deps.dart';
import '../constants.dart';

import 'build_packages.dart';
import 'build_spec.dart';
import 'build_spec_digest.dart';
import 'build_step_plan.dart';

part 'previous_build.g.dart';

/// Information about the previous build run and how it relates to the current
/// configuration.
abstract class PreviousBuild
    implements Built<PreviousBuild, PreviousBuildBuilder> {
  /// The `FinishedBuildState` of the previous build, or null if it was missing
  /// or incompatible.
  FinishedBuildState? get state;

  /// Phased asset dependencies from the previous run, or null.
  PhasedAssetDeps? get phasedAssetDeps;

  /// Whether the configuration triggers changed since the last run.
  bool get triggersChanged;

  /// Whether options changed per-phase.
  BuiltList<bool> get phaseOptionsChangedList;
  BuiltList<bool> get postBuildOptionsChangedList;

  /// If the previous build is not compatible, source tree outputs from it to
  /// delete.
  BuiltList<AssetId> get incompatibleBuildOutputsToDelete;

  /// Deserializes information about the previous build and compares it to
  /// [buildSpec] to determine whether an incremental build is possible.
  ///
  /// If so then [state] and [phasedAssetDeps] hold detailed information
  /// about the previous build, and [triggersChanged], [phaseOptionsChangedList]
  /// and [postBuildOptionsChangedList] give more detail on compatibility.
  ///
  /// If the previous build cannot be used for an incremental build then
  /// [incompatibleBuildOutputsToDelete] is filled with its source tree outputs
  /// to delete.
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
    FinishedBuildState? previousFinishedBuildState;
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
        } else {
          final previousBuildStepPlan = BuildStepPlan.compute(
            buildPhases: buildSpec.buildPhases,
            placeholderIds: buildPackages.placeholderIds,
            sources: incrementalBuildState.sources,
          );
          previousFinishedBuildState = FinishedBuildState(
            incremental: incrementalBuildState,
            buildStepPlan: previousBuildStepPlan,
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
      b.state = previousFinishedBuildState;
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
  /// Sets [finishedBuildState] and [previousPhasedAssetDeps].
  ///
  /// Clears `triggersChanged` and other fields related to checking
  /// whether an incremental build is possible.
  PreviousBuild updateForNextBuild({
    required FinishedBuildState finishedBuildState,
    required PhasedAssetDeps previousPhasedAssetDeps,
  }) => rebuild((b) {
    b.triggersChanged = false;
    b.state = finishedBuildState;
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
  factory PreviousBuild([void Function(PreviousBuildBuilder) updates]) =
      _$PreviousBuild;
}

/// Computes declared and post process outputs in [buildState] to delete for
/// [buildPackages].
Iterable<AssetId> _outputsToDelete({
  required IncrementalBuildState buildState,
  required BuildPackages buildPackages,
}) {
  final result = <AssetId>[];
  for (final stepResult in buildState.buildStepResults.values) {
    if (!stepResult.isHidden) {
      for (final id in stepResult.outputs.keys) {
        if (buildPackages[id.package] != null) result.add(id);
      }
    }
  }
  for (final postProcessResult in buildState.postProcessResults.values) {
    if (!postProcessResult.hidden) {
      for (final id in postProcessResult.outputs.keys) {
        if (buildPackages[id.package] != null) result.add(id);
      }
    }
  }
  return result;
}
