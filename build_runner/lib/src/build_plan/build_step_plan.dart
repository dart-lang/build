// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' as build;
import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';

import '../build/asset_graph/build_step_id.dart';

import '../build/asset_graph/post_process_build_step_id.dart';
import 'build_packages.dart';
import 'build_phases.dart';
import 'phase.dart';

/// The static declarative blueprint of a build.
///
/// Expands [BuildPhases] against workspace sources and [BuildPackages]
/// to declare scheduled build steps, expected generated outputs, and
/// placeholders.
class ExpectedOutputConfiguration {
  final AssetId primaryInput;
  final int phaseNumber;
  final bool isHidden;

  ExpectedOutputConfiguration({
    required this.primaryInput,
    required this.phaseNumber,
    required this.isHidden,
  });

  BuildStepId get buildStepId =>
      BuildStepId(primaryInput: primaryInput, phaseNumber: phaseNumber);
}

class BuildStepPlan {
  final BuiltSet<AssetId> placeholders;
  final BuiltMap<AssetId, ExpectedOutputConfiguration> expectedOutputs;
  final BuiltMap<BuildStepId, BuiltSet<AssetId>> primaryOutputsByStep;
  final BuiltSet<BuildStepId> scheduledBuildSteps;
  final BuiltSet<PostProcessBuildStepId> scheduledPostProcessSteps;

  BuildStepPlan._({
    required this.placeholders,
    required this.expectedOutputs,
    required this.primaryOutputsByStep,
    required this.scheduledBuildSteps,
    required this.scheduledPostProcessSteps,
  });

  Iterable<AssetId> primaryOutputsOf(AssetId id) => primaryOutputsByStep.entries
      .where((entry) => entry.key.primaryInput == id)
      .expand((entry) => entry.value);

  static BuildStepPlan create({
    required BuildPhases buildPhases,
    required Set<AssetId> sources,
    required BuildPackages buildPackages,
  }) {
    final placeholders = placeholderIdsForPlan(buildPackages);
    final expectedOutputsBuilder =
        MapBuilder<AssetId, ExpectedOutputConfiguration>();
    final primaryOutputsByStep = MapBuilder<BuildStepId, SetBuilder<AssetId>>();
    final scheduledBuildSteps = SetBuilder<BuildStepId>();
    final scheduledPostProcessSteps = SetBuilder<PostProcessBuildStepId>();

    final allInputs = Set<AssetId>.from(sources)..addAll(placeholders);

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
      while (expectedOutputsBuilder[currentInput] != null) {
        currentInput = expectedOutputsBuilder[currentInput]!.primaryInput;
      }
      return action.targetSources.matches(currentInput);
    }

    for (
      var phaseNum = 0;
      phaseNum < buildPhases.inBuildPhases.length;
      phaseNum++
    ) {
      final phase = buildPhases.inBuildPhases[phaseNum];
      final inputs =
          allInputs.where((input) => actionMatches(phase, input)).toList();
      final phaseOutputs = <AssetId>[];

      for (final input in inputs) {
        if (!allInputs.contains(input)) continue;

        final generatedOutputs = build.expectedOutputs(phase.builder, input);
        if (generatedOutputs.isEmpty) continue;

        final buildStepId = BuildStepId(
          primaryInput: input,
          phaseNumber: phaseNum,
        );
        scheduledBuildSteps.add(buildStepId);
        primaryOutputsByStep
            .putIfAbsent(buildStepId, SetBuilder.new)
            .addAll(generatedOutputs);

        for (final output in generatedOutputs) {
          // If this output was previously processed as a source file during
          // this phase, remove any scheduled steps that used it as an input!
          void removeInvalidStepsRecursive(AssetId invalidInput) {
            final invalidSteps =
                scheduledBuildSteps
                    .build()
                    .where((step) => step.primaryInput == invalidInput)
                    .toList();
            for (final invalidStep in invalidSteps) {
              scheduledBuildSteps.remove(invalidStep);
              final invalidOutputs =
                  primaryOutputsByStep[invalidStep]?.build() ??
                  BuiltSet<AssetId>();
              primaryOutputsByStep.remove(invalidStep);
              for (final invalidOutput in invalidOutputs) {
                phaseOutputs.remove(invalidOutput);
                expectedOutputsBuilder.remove(invalidOutput);
                removeInvalidStepsRecursive(invalidOutput);
              }
            }
          }

          removeInvalidStepsRecursive(output);

          expectedOutputsBuilder[output] = ExpectedOutputConfiguration(
            primaryInput: input,
            phaseNumber: phaseNum,
            isHidden: phase.hideOutput,
          );
          phaseOutputs.add(output);
        }
        allInputs.removeAll(generatedOutputs);
      }
      allInputs.addAll(phaseOutputs);
    }

    var actionNumber = 0;
    for (final action in buildPhases.postBuildPhase.builderActions) {
      final inputs = allInputs.where((input) => actionMatches(action, input));
      for (final input in inputs) {
        scheduledPostProcessSteps.add(
          PostProcessBuildStepId(input: input, actionNumber: actionNumber),
        );
      }
      actionNumber++;
    }

    return BuildStepPlan._(
      placeholders: placeholders.build(),
      expectedOutputs: expectedOutputsBuilder.build(),
      primaryOutputsByStep: BuiltMap<BuildStepId, BuiltSet<AssetId>>.from({
        for (final entry in primaryOutputsByStep.build().entries)
          entry.key: entry.value.build(),
      }),
      scheduledBuildSteps: scheduledBuildSteps.build(),
      scheduledPostProcessSteps: scheduledPostProcessSteps.build(),
    );
  }
}

Set<AssetId> placeholderIdsForPlan(BuildPackages buildPackages) =>
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
