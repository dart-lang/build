// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

import '../../build_plan/build_step_plan.dart';
import '../../contracts.dart';
import '../asset_content.dart';
import 'build_step_id.dart';
import 'build_step_result.dart';
import 'incremental_build_state.dart';
import 'post_process_build_step_id.dart';
import 'post_process_build_step_result.dart';

/// Data from the `BuildState` of a finished build.
///
/// Because the build is finished, all file content used in the build is
/// available.
///
/// Used by post-build consumers and to prepare the next incremental build.
@Invariant(
  'contents.keys.every((id) => isFile(id))',
  'sources.every((id) => !buildStepPlan.isDeclaredOutput(id))',
  'sources.every((id) => !isActualPostOutput(id))',
  'actualOutputs.every((id) => buildStepPlan.isDeclaredOutput(id))',
  'incremental.missingSources.every((id) => !isSource(id))',
)
class FinishedBuildState {
  /// Description of the build.
  final BuildStepPlan buildStepPlan;

  /// State that will be persisted for a later build.
  final IncrementalBuildState incremental;

  /// Contents of all files that were used in the build, inputs or outputs.
  ///
  /// This is retained separately to [incremental] because
  /// [IncrementalBuildState] does not store file content.
  final BuiltMap<AssetId, AssetContent> contents;

  FinishedBuildState({
    required this.buildStepPlan,
    required this.incremental,
    required this.contents,
  });

  /// An empty [FinishedBuildState] with no sources and an empty plan.
  @visibleForTesting
  FinishedBuildState.empty()
    : buildStepPlan = BuildStepPlan.empty(),
      incremental = IncrementalBuildState(),
      contents = BuiltMap<AssetId, AssetContent>();

  BuiltSet<AssetId> get sources => incremental.sources;
  BuiltMap<BuildStepId, BuildStepResult> get buildStepResults =>
      incremental.buildStepResults;
  BuiltMap<PostProcessBuildStepId, PostProcessBuildStepResult>
  get postProcessResults => incremental.postProcessResults;

  late final BuiltSet<AssetId> assetsDeletedByPostProcess = () {
    final builder = SetBuilder<AssetId>();
    for (final entry in postProcessResults.entries) {
      if (entry.value.deletedPrimaryInput) {
        builder.add(entry.key.input);
      }
    }
    return builder.build();
  }();

  late final BuiltMap<AssetId, PostProcessBuildStepId> postProcessOutputs = () {
    final builder = MapBuilder<AssetId, PostProcessBuildStepId>();
    for (final entry in postProcessResults.entries) {
      for (final id in entry.value.outputs) {
        builder[id] = entry.key;
      }
    }
    return builder.build();
  }();

  bool isSource(AssetId id) => sources.contains(id);

  BuildStepResult? stepResultOrNull(BuildStepId step) => buildStepResults[step];

  Iterable<AssetId> get actualOutputs =>
      buildStepResults.values.expand((r) => r.outputs);
  Iterable<AssetId> get actualPostOutputs => postProcessOutputs.keys;

  bool isActualPostOutput(AssetId id) => postProcessOutputs.containsKey(id);

  bool isActualOutput(AssetId id) {
    final step = buildStepPlan.stepForDeclaredOutputOrNull(id);
    if (step == null) return false;
    return stepResultOrNull(step)?.outputs.contains(id) ?? false;
  }

  bool _isArtifactTreePostProcessOutput(AssetId id) {
    final step = postProcessOutputs[id];
    if (step == null) return false;
    return postProcessResults[step]?.inArtifactTree ?? false;
  }

  bool isInArtifactTree(AssetId id) =>
      buildStepPlan.isDeclaredOutputInArtifactTree(id) ||
      _isArtifactTreePostProcessOutput(id);

  bool isFile(AssetId id) =>
      isSource(id) ||
      buildStepPlan.isDeclaredOutput(id) ||
      isActualPostOutput(id);

  AssetContent? contentOf(AssetId id) => contents[id];

  Iterable<MapEntry<AssetId, AssetContent>> get sourceContents =>
      contents.entries.where((e) => isSource(e.key));

  Iterable<MapEntry<AssetId, AssetContent>> get outputContents =>
      contents.entries.where((e) => !isSource(e.key));
}
