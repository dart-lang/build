// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import '../build/build_state/build_step_id.dart';
import '../build/build_state/exceptions.dart';
import '../constants.dart';
import '../io/generated_asset_hider.dart';
import 'build_phases.dart';
import 'phase.dart';

part 'build_step_plan.g.dart';

/// Planned build steps for one build and their declared outputs.
abstract class BuildStepPlan
    implements Built<BuildStepPlan, BuildStepPlanBuilder>, GeneratedAssetHider {
  BuildPhases get buildPhases;

  BuiltMap<AssetId, BuildStepId> get buildStepsByDeclaredOutput;

  BuiltListMultimap<AssetId, AssetId> get declaredOutputsByPrimaryInput;

  BuiltList<BuiltList<BuildStepId>> get buildStepsByPhase;

  factory BuildStepPlan([void Function(BuildStepPlanBuilder)? updates]) =
      _$BuildStepPlan;
  BuildStepPlan._();

  /// Plans build steps from [buildPhases], placeholder IDs and source IDs.
  factory BuildStepPlan.compute({
    required BuildPhases buildPhases,
    required Iterable<AssetId> placeholderIds,
    required Iterable<AssetId> sources,
  }) {
    final result = BuildStepPlanBuilder()..buildPhases = buildPhases;

    final allInputs = sources.toSet();
    allInputs.addAll(placeholderIds);

    for (
      var phaseNum = 0;
      phaseNum < buildPhases.inBuildPhases.length;
      phaseNum++
    ) {
      final phase = buildPhases.inBuildPhases[phaseNum];
      final phaseOutputs = <AssetId>{};
      final phaseSteps = ListBuilder<BuildStepId>();
      for (final input in allInputs) {
        if (!_actionMatches(
          phase,
          input,
          (id) => result.buildStepsByDeclaredOutput[id],
        )) {
          continue;
        }
        final outputs = expectedOutputs(phase.builder, input);
        phaseOutputs.addAll(outputs);
        result.declaredOutputsByPrimaryInput.addValues(input, outputs);

        final buildStepId = BuildStepId(
          primaryInput: input,
          phaseNumber: phaseNum,
        );
        phaseSteps.add(buildStepId);

        for (final output in outputs) {
          if (result.buildStepsByDeclaredOutput[output] != null) {
            final existingPhase =
                result.buildStepsByDeclaredOutput[output]!.phaseNumber;
            throw DuplicateAssetIdException(
              output,
              buildPhases.inBuildPhases[existingPhase].displayName,
              buildPhases.inBuildPhases[phaseNum].displayName,
            );
          }
          result.buildStepsByDeclaredOutput[output] = buildStepId;
        }
      }
      result.buildStepsByPhase.add(phaseSteps.build());
      allInputs.addAll(phaseOutputs);
    }

    return result.build();
  }

  /// Checks if a builder action matches a primary input.
  bool actionMatches(BuildAction action, AssetId input) =>
      _actionMatches(action, input, (id) => buildStepsByDeclaredOutput[id]);

  static bool _actionMatches(
    BuildAction action,
    AssetId input,
    BuildStepId? Function(AssetId)? stepLookup,
  ) {
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
    if (stepLookup != null) {
      while (true) {
        final buildStep = stepLookup(currentInput);
        if (buildStep == null) break;
        currentInput = buildStep.primaryInput;
      }
    }
    return action.targetSources.matches(currentInput);
  }

  @override
  bool isHidden(AssetId id) {
    if (id.path.startsWith(generatedOutputDirectory) ||
        id.path.startsWith(cacheDirectoryPath)) {
      return false;
    }
    final step = stepForDeclaredOutputOrNull(id);
    if (step == null) return false;
    return buildPhases.inBuildPhases[step.phaseNumber].hideOutput;
  }

  Iterable<AssetId> get declaredOutputs => buildStepsByDeclaredOutput.keys;

  bool isDeclaredOutput(AssetId id) =>
      buildStepsByDeclaredOutput.containsKey(id);

  BuildStepId stepForDeclaredOutput(AssetId id) =>
      buildStepsByDeclaredOutput[id]!;

  BuildStepId? stepForDeclaredOutputOrNull(AssetId id) =>
      buildStepsByDeclaredOutput[id];

  Iterable<AssetId> declaredOutputsOf(AssetId id) =>
      declaredOutputsByPrimaryInput[id];

  Set<AssetId> transitiveDeclaredOutputsOf(Iterable<AssetId> ids) {
    final results = <AssetId>{};

    void addTransitive(AssetId id) {
      if (results.add(id)) {
        for (final output in declaredOutputsOf(id)) {
          addTransitive(output);
        }
      }
    }

    for (final id in ids) {
      addTransitive(id);
    }
    return results;
  }

  Map<AssetId, int> get declaredOutputPhases => {
    for (final entry in buildStepsByDeclaredOutput.entries)
      entry.key: entry.value.phaseNumber,
  };
}
