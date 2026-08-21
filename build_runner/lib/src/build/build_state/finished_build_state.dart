// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';

import '../../build_plan/build_step_plan.dart';
import '../asset_content.dart';
import 'build_step_id.dart';
import 'build_step_result.dart';
import 'glob_id.dart';
import 'glob_result.dart';
import 'post_process_build_step_id.dart';
import 'post_process_build_step_result.dart';
import 'serialized_build_state.dart';

/// State of a finished build, pairing the [SerializedBuildState] with the
/// [BuildStepPlan].
///
/// Offers functionality used after the build, for example in serving files,
/// and in preparation for the next build.
class FinishedBuildState {
  final SerializedBuildState serialized;
  final BuildStepPlan buildStepPlan;

  FinishedBuildState({required this.serialized, required this.buildStepPlan});

  /// An empty [FinishedBuildState] with no sources and an empty plan.
  FinishedBuildState.empty()
    : serialized = SerializedBuildState(),
      buildStepPlan = BuildStepPlan.empty();

  BuiltSet<AssetId> get sources => serialized.sources;
  BuiltMap<AssetId, AssetContent> get sourceContents =>
      serialized.sourceContents;
  BuiltSet<AssetId> get missingSources => serialized.missingSources;
  BuiltMap<BuildStepId, BuildStepResult> get buildStepResults =>
      serialized.buildStepResults;
  BuiltMap<PostProcessBuildStepId, PostProcessBuildStepResult>
  get postProcessResults => serialized.postProcessResults;
  BuiltMap<GlobId, GlobResult> get globResults => serialized.globResults;

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
      for (final id in entry.value.outputs.keys) {
        builder[id] = entry.key;
      }
    }
    return builder.build();
  }();

  bool isSource(AssetId id) => sources.contains(id);
  bool isMissingSource(AssetId id) => missingSources.contains(id);
  AssetContent? contentOfSource(AssetId id) => sourceContents[id];

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
      buildStepResults.values.expand((r) => r.outputs.keys);
  Iterable<AssetId> get actualPostOutputs => postProcessOutputs.keys;

  bool isActualPostOutput(AssetId id) => postProcessOutputs.containsKey(id);

  bool isActualOutput(AssetId id) {
    final step = buildStepPlan.stepForDeclaredOutputOrNull(id);
    if (step == null) return false;
    return stepResultOrNull(step)?.outputs.containsKey(id) ?? false;
  }

  bool isHiddenDeclaredOutput(AssetId id) {
    final step = buildStepPlan.stepForDeclaredOutputOrNull(id);
    if (step == null) return false;
    return stepResultOrNull(step)?.isHidden ?? buildStepPlan.isHidden(id);
  }

  bool isHiddenPostProcessOutput(AssetId id) {
    final step = postProcessOutputs[id];
    if (step == null) return false;
    return postProcessResults[step]?.hidden ?? false;
  }

  bool isHidden(AssetId id) =>
      isHiddenDeclaredOutput(id) || isHiddenPostProcessOutput(id);

  bool isActualHiddenOutput(AssetId id) =>
      isHidden(id) && (isActualOutput(id) || isActualPostOutput(id));

  /// Whether [id] is one of: source, declared output or actual post process
  /// output.
  bool isFile(AssetId id) =>
      isSource(id) ||
      buildStepPlan.isDeclaredOutput(id) ||
      isActualPostOutput(id);

  AssetContent? contentOf(AssetId id) {
    if (isSource(id)) return sourceContents[id];
    final step = buildStepPlan.stepForDeclaredOutputOrNull(id);
    if (step != null) {
      return stepResultOrNull(step)?.outputs[id];
    }
    final postStep = postProcessOutputs[id];
    if (postStep != null) {
      return postProcessResults[postStep]?.outputs[id];
    }
    return null;
  }
}
