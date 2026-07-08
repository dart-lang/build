// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import '../build/build_state/asset_graph_json.dart';
import '../build/build_state/build_state.dart';
import '../build/library_cycle_graph/phased_asset_deps.dart';
import '../constants.dart';

import 'build_spec.dart';
import 'build_spec_digest.dart';

part 'previous_build.g.dart';

/// Information about the previous build run and how it relates to the current
/// configuration.
abstract class PreviousBuild
    implements Built<PreviousBuild, PreviousBuildBuilder> {
  /// The deserialized build state (asset graph) from the previous run,
  /// or null if it was missing or incompatible.
  BuildState? get buildState;

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
  /// If so then [buildState] and [phasedAssetDeps] hold detailed information
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
    BuildState? previousBuildState;
    final incompatibleBuildOutputsToDelete = <AssetId>{};
    PhasedAssetDeps? previousPhasedAssetDeps;

    if (await readerWriter.canRead(assetGraphJsonId)) {
      final assetGraphJson = AssetGraphJson.deserialize(
        await readerWriter.readAsBytes(assetGraphJsonId) as Uint8List,
      );
      if (assetGraphJson != null) {
        previousBuildState = assetGraphJson.buildState;
        previousBuildPlanDigest = assetGraphJson.buildPlanDigest;
        previousPhasedAssetDeps = assetGraphJson.phasedAssetDeps;
      }
      if (previousBuildState != null) {
        final forceCleanBuild =
            buildSpec.restartIsNeeded ||
            buildPackages.hasNewerAlternateRootBuild ||
            !buildPlanDigest.canIncrementallyBuildFrom(previousBuildPlanDigest);

        if (forceCleanBuild) {
          incompatibleBuildOutputsToDelete.addAll(
            previousBuildState.outputsToDelete(buildPackages),
          );
          previousBuildState = null;
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
      b.buildState = previousBuildState;
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
  /// Sets [previousBuildState] and [previousPhasedAssetDeps].
  ///
  /// Clears `triggersChanged` and other fields related to checking
  /// whether an incremental build is possible.
  PreviousBuild updateForNextBuild({
    required BuildState previousBuildState,
    required PhasedAssetDeps previousPhasedAssetDeps,
  }) => rebuild((b) {
    b.triggersChanged = false;
    b.buildState = previousBuildState;
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
