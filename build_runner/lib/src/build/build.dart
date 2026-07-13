// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

import '../build_plan/build_configs.dart';
import '../build_plan/build_inputs.dart';
import '../build_plan/build_options.dart';
import '../build_plan/build_packages.dart';
import '../build_plan/build_phases.dart';
import '../build_plan/build_plan.dart';
import '../build_plan/build_spec.dart';
import '../build_plan/build_step_plan.dart';
import '../build_plan/phase.dart';
import '../build_plan/testing_overrides.dart';

import '../io/build_output_reader.dart';

import '../logging/build_log.dart';
import '../logging/build_log_logger.dart';
import '../logging/timed_activities.dart';
import 'build_dirs.dart';
import 'build_result.dart';
import 'build_state/build_state.dart';
import 'build_state/build_step_id.dart';
import 'build_state/build_step_result.dart';
import 'build_state/glob_id.dart';
import 'build_state/glob_result.dart';
import 'build_state/post_process_build_step_id.dart';
import 'build_state/post_process_build_step_result.dart';
import 'build_step_impl.dart';
import 'generated_parts.dart';
import 'builder_filesystem.dart';
import 'input_tracker.dart';
import 'library_cycle_graph/asset_deps_loader.dart';
import 'library_cycle_graph/library_cycle_graph.dart';
import 'library_cycle_graph/library_cycle_graph_loader.dart';
import 'library_cycle_graph/phased_asset_deps.dart';
import 'post_process_build_step_impl.dart';
import 'resolver/analysis_driver_model.dart';
import 'resolver/resolvers_impl.dart';

final ResolversImpl _defaultResolvers = ResolversImpl(
  analysisDriverModel: AnalysisDriverModel(),
);

/// A single build.
class Build {
  final BuildPlan buildPlan;

  // Collaborators.
  final ResourceManager resourceManager;
  final LibraryCycleGraphLoader previousLibraryCycleGraphLoader =
      LibraryCycleGraphLoader();
  final AssetDepsLoader? previousDepsLoader;
  final Resolvers resolvers;

  /// If [resolvers] is a `ResolversImpl`, the same instance.
  ///
  /// Otherwise, `null`. A different `Resolvers` implementation can be passed
  /// for testing, including via `build_test`.
  final ResolversImpl? resolversImpl;

  // State.
  final BuildState buildState;
  final lazyPhases = <BuildStepId, Future<Iterable<AssetId>>>{};
  final lazyGlobs = <GlobId, Future<void>>{};

  /// Whether a graph from [previousLibraryCycleGraphLoader] has any changed
  /// transitive source.
  final Map<LibraryCycleGraph, bool> changedGraphs = Map.identity();

  late final BuilderFilesystem _builderFilesystem = BuilderFilesystem(
    buildPackages: buildPackages,
    buildConfigs: buildConfigs,
    buildStepPlan: buildStepPlan,
    buildState: buildState,
    readerWriter: buildPlan.readerWriter,
    assetBuilder: _buildOutput,
    globEvaluator: _evaluateGlob,
  );

  Build({required this.buildPlan, required this.resourceManager})
    : previousDepsLoader = buildPlan.previousBuild.phasedAssetDeps == null
          ? null
          : AssetDepsLoader.fromDeps(buildPlan.previousBuild.phasedAssetDeps!),
      resolvers =
          buildPlan.buildSpec.testingOverrides.resolvers ?? _defaultResolvers,
      resolversImpl = switch (buildPlan.buildSpec.testingOverrides.resolvers ??
          _defaultResolvers) {
        ResolversImpl r => r,
        _ => null,
      },
      buildState = BuildState({
        for (final id in buildPlan.buildInputs.sources)
          id: buildPlan.buildInputs.sourceContents[id],
      });

  BuildSpec get buildSpec => buildPlan.buildSpec;
  BuildOptions get buildOptions => buildSpec.buildOptions;
  TestingOverrides get testingOverrides => buildSpec.testingOverrides;
  BuildPackages get buildPackages => buildSpec.buildPackages;
  BuildConfigs get buildConfigs => buildSpec.buildConfigs;
  BuildPhases get buildPhases => buildPlan.buildStepPlan.buildPhases;
  BuildState? get previousBuildState => buildPlan.previousBuild.buildState;
  BuildInputs get buildInputs => buildPlan.buildInputs;
  BuildStepPlan get buildStepPlan => buildPlan.buildStepPlan;

  Future<BuildResult> run() async {
    buildLog.configuration = buildLog.configuration.rebuild(
      (b) => b..singleOutputPackage = buildPackages.singleOutputPackage,
    );
    var result = await _safeBuild();
    if (result.status == BuildStatus.success) {
      final failedSteps = buildState.failedSteps;
      if (failedSteps.isNotEmpty) {
        for (final step in failedSteps) {
          final stepResult = buildState.stepResult(step);
          if (!identical(
            stepResult,
            previousBuildState?.stepResultOrNull(step),
          )) {
            // It was run in this build, so the errors were already logged
            // by the builder itself.
            continue;
          }
          final phase = buildPhases.inBuildPhases[step.phaseNumber];
          final logger = buildLog.loggerFor(
            phase: phase,
            primaryInput: step.primaryInput,
            lazy: phase.isOptional,
          );
          for (final error in stepResult.errors) {
            logger.severe(error);
          }
        }
      }

      final failedPostProcessSteps = buildState.failedPostProcessSteps;

      if (failedPostProcessSteps.isNotEmpty) {
        for (final id in failedPostProcessSteps) {
          final action =
              buildPhases.postBuildPhase.builderActions[id.actionNumber];
          final logger = buildLog.loggerForOther(
            action.builderLabel,
            contextId: id.input,
          );
          final stepResult = buildState.postProcessBuildStepResultFor(id)!;
          for (final error in stepResult.errors) {
            logger.severe(error);
          }
        }
      }

      if (failedSteps.isNotEmpty || failedPostProcessSteps.isNotEmpty) {
        result = result.copyWith(status: BuildStatus.failure);
      }
    }
    await resourceManager.disposeAll();

    resolvers.reset();
    return result;
  }

  Future<BuildResult> _safeBuild() {
    final done = Completer<BuildResult>();
    runZonedGuarded(
      () async {
        await resolversImpl?.takeLockAndStartBuild(
          builderFilesystem: _builderFilesystem,
          buildInputs: buildInputs,
        );
        final result = await _runPhases();

        // Combine previous phased asset deps, if any, with the newly loaded
        // deps. Because of skipped builds, the newly loaded deps might just
        // say "not generated yet", in which case the old value is retained.
        final currentPhasedAssetDeps =
            resolversImpl?.phasedAssetDeps() ?? PhasedAssetDeps();
        final updatedPhasedAssetDeps =
            buildPlan.previousBuild.phasedAssetDeps == null
            ? currentPhasedAssetDeps
            : buildPlan.previousBuild.phasedAssetDeps!.update(
                currentPhasedAssetDeps,
              );
        if (!done.isCompleted) {
          done.complete(
            result.copyWith(phasedAssetDeps: updatedPhasedAssetDeps),
          );
        }
      },
      (e, st) {
        if (!done.isCompleted) {
          buildLog.error(
            buildLog.renderThrowable('Unhandled build failure!', e, st),
          );
          done.complete(
            BuildResult(
              status: BuildStatus.failure,
              outputs: BuiltList(),
              buildState: buildState,
              buildOutputReader: BuildOutputReader(
                builderFilesystem: _builderFilesystem.forAfterBuild(),
              ),
            ),
          );
        }
      },
    );

    return done.future;
  }

  /// Runs the actions in [buildPhases] and returns a future which completes
  /// to the [BuildResult] once all [BuildPhase]s are done.
  Future<BuildResult> _runPhases() async {
    final outputs = <AssetId>[];
    // Find inputs for non-optional phases, count them for logging.
    final primaryInputsByPhase = <InBuildPhase, List<AssetId>>{};
    final primaryInputCountsByPhase = <InBuildPhase, int>{};
    for (
      var phaseNum = 0;
      phaseNum < buildPhases.inBuildPhases.length;
      phaseNum++
    ) {
      final phase = buildPhases.inBuildPhases[phaseNum];

      if (phase.isOptional) continue;
      final primaryInputs = await _matchingPrimaryInputs(
        phase.package,
        phaseNum,
      );
      // If `primaryInputs` is empty, the phase will only run lazily,
      // and might not run at all; so don't log it to start with.
      if (primaryInputs.isNotEmpty) {
        primaryInputsByPhase[phase] = primaryInputs;
        primaryInputCountsByPhase[phase] = primaryInputs.length;
      }
    }

    buildLog.startPhases(
      primaryInputCountsByPhase,
      buildPackages: buildPackages,
    );

    // Main build phases.
    for (
      var phaseNum = 0;
      phaseNum < buildPhases.inBuildPhases.length;
      phaseNum++
    ) {
      final phase = buildPhases.inBuildPhases[phaseNum];
      final primaryInputs = primaryInputsByPhase[phase];
      if (primaryInputs == null || primaryInputs.isEmpty) continue;

      for (var i = 0; i != primaryInputs.length; ++i) {
        final primaryInput = primaryInputs[i];
        final buildStepId = BuildStepId(
          primaryInput: primaryInput,
          phaseNumber: phaseNum,
        );
        outputs.addAll(
          await _buildForPrimaryInput(
            buildStepId: buildStepId,
            phase: phase,
            lazy: false,
          ),
        );
      }
    }

    // Post build phase.
    if (buildPhases.postBuildPhase.builderActions.isNotEmpty) {
      outputs.addAll(
        await _runPostBuildPhase(
          buildPhases.inBuildPhases.length,
          buildPhases.postBuildPhase,
        ),
      );
    }

    await Future.forEach(
      lazyPhases.values,
      (Future<Iterable<AssetId>> lazyOuts) async =>
          outputs.addAll(await lazyOuts),
    );
    // Assume success, failed outputs will be checked later.

    final generatedPartOutputs = buildState.primaryInputsWithParts.map(
      (id) => id.partIdForPrimaryInput,
    );
    outputs.addAll(generatedPartOutputs);

    return BuildResult(
      status: BuildStatus.success,
      outputs: outputs.build(),
      buildState: buildState,
      buildOutputReader: BuildOutputReader(
        builderFilesystem: _builderFilesystem.forAfterBuild(),
      ),
    );
  }

  /// Returns primary inputs for [package] in [phaseNumber].
  Future<List<AssetId>> _matchingPrimaryInputs(
    String package,
    int phaseNumber,
  ) async {
    final ids = <AssetId>[];
    final phase = buildPhases[phaseNumber] as InBuildPhase;
    final buildPackage = buildPackages[package]!;

    for (final step in buildStepPlan.buildStepsByPhase[phaseNumber]) {
      final primaryInput = step.primaryInput;
      final outputs = expectedOutputs(phase.builder, primaryInput);

      final assetsToCheck = outputs.isEmpty ? [primaryInput] : outputs;
      var shouldBuild = false;
      for (final id in assetsToCheck) {
        if (!shouldBuildForDirs(
          id,
          buildDirs: buildPlan.buildDirs,
          buildFilters: buildPlan.buildFilters,
          phase: phase,
          buildConfigs: buildConfigs,
        )) {
          continue;
        }

        // Don't build for inputs that aren't visible. This can happen for
        // placeholders like `test/$test$` that are added to each package,
        // since the test dir is not part of the build for non-root packages.
        if (!buildConfigs.isVisibleInBuild(id, buildPackage)) continue;

        shouldBuild = true;
        break;
      }

      if (shouldBuild) {
        ids.add(primaryInput);
      }
    }
    return ids..sort();
  }

  /// If [id] is a generated asset, ensures that it has been built.
  ///
  /// If has already been built according to [buildState], returns
  /// immediately.
  ///
  /// If it is currently being built according to [lazyPhases], waits for it to
  /// be built.
  Future<void> _buildOutput(AssetId id) async {
    final step = buildStepPlan.stepForDeclaredOutputOrNull(id);
    if (step != null &&
        !buildState.isProcessedOutput(buildStepPlan: buildStepPlan, id: id)) {
      await lazyPhases.putIfAbsent(step, () async {
        final phase = buildPhases.inBuildPhases[step.phaseNumber];
        return _buildForPrimaryInput(
          buildStepId: step,
          phase: phase,
          lazy: true,
        );
      });
    }
  }

  /// Runs the builder for [buildStepId] at [phase].
  ///
  /// If outputs are already valid or are optional and not used, does nothing.
  ///
  /// Returns the files written.
  Future<Iterable<AssetId>> _buildForPrimaryInput({
    required BuildStepId buildStepId,
    required InBuildPhase phase,
    required bool lazy,
  }) async {
    buildLog.startStep(
      phase: phase,
      primaryInput: buildStepId.primaryInput,
      lazy: lazy,
    );
    final builder = phase.builder;
    final builderOutputs = expectedOutputs(builder, buildStepId.primaryInput);

    final inputTracker = InputTracker(
      buildPlan.readerWriter.filesystem,
      primaryInput: buildStepId.primaryInput,
      builderLabel: phase.displayName,
    );

    final unusedAssets = <AssetId>{};
    void reportUnusedAssetsForInput(AssetId input, Iterable<AssetId> assets) {
      testingOverrides.reportUnusedAssetsForInput?.call(input, assets);
      unusedAssets.addAll(assets);
    }

    final step = BuildStepImpl(
      inputId: buildStepId.primaryInput,
      expectedOutputs: builderOutputs,
      inputTracker: inputTracker,
      buildFilesystem: _builderFilesystem,
      phase: buildStepId.phaseNumber,
      resolvers: resolvers,
      resourceManager: resourceManager,
      reportUnusedAssets: (Iterable<AssetId> assets) =>
          reportUnusedAssetsForInput(buildStepId.primaryInput, assets),
    );

    final stepAction = await _computeStepAction(buildStepId, builderOutputs);
    if (stepAction.isSkip) {
      buildLog.skipStep(phase: phase, lazy: lazy);
      if (stepAction == StepAction.skipMissingPrimaryInput) {
        _markStepSkipped(buildStepId, builderOutputs);
      } else if (stepAction == StepAction.skipFailedPrimaryInput) {
        await _markStepFailed(buildStepId, builderOutputs);
      } else if (stepAction == StepAction.skipReuse) {
        _builderFilesystem.updateBuildStepResult(
          buildStepId,
          previousBuildState!.stepResult(buildStepId),
        );
      }
      return <AssetId>[];
    }

    // Clear input tracking accumulated during `_buildShouldRun`.
    step.inputTracker.clear();

    final allowedByTriggers = await _allowedByTriggers(
      inputTracker: step.inputTracker,
      phase: phase,
      phaseNum: buildStepId.phaseNumber,
      primaryInput: buildStepId.primaryInput,
    );
    final logger = buildLog.loggerFor(
      phase: phase,
      primaryInput: buildStepId.primaryInput,
      lazy: lazy,
    );
    if (allowedByTriggers) {
      await TimedActivity.build.runAsync<void>(() async {
        try {
          await BuildLogLogger.scopeLogAsync(() async {
            try {
              await builder.build(step);
            } finally {
              await step.complete();
            }
          }, logger);
        } catch (_) {
          // Errors are handled via the logger.
        }
      });
    }

    // Update the state for the build step its outputs based on what was read
    // and written.
    await TimedActivity.track.runAsync(
      () => _setOutputsState(
        buildStepId.primaryInput,
        builderOutputs,
        step,
        logger.errors,
        unusedAssets: unusedAssets,
      ),
    );

    if (allowedByTriggers) {
      buildLog.finishStep(
        phase: phase,
        anyOutputs: step.outputs.isNotEmpty,
        anyChangedOutputs: step.outputs.keys.any(_isChangedOutput),
        lazy: lazy,
      );
    } else {
      buildLog.stepNotTriggered(phase: phase, lazy: lazy);
    }

    return step.outputs.keys;
  }

  /// Whether build triggers allow [phase] to run on [primaryInput].
  ///
  /// This means either the builder does not have `run_only_if_triggered: true`
  /// or it does run only if triggered and is triggered.
  Future<bool> _allowedByTriggers({
    required InputTracker inputTracker,
    required InBuildPhase phase,
    required int phaseNum,
    required AssetId primaryInput,
  }) async {
    final runsIfTriggered = phase.options.config['run_only_if_triggered'];
    if (runsIfTriggered != true) {
      return true;
    }
    final buildTriggers = buildConfigs.buildTriggers[phase.key];
    if (buildTriggers == null) {
      return false;
    }
    inputTracker.add(primaryInput);

    final primaryInputSource = (await _builderFilesystem.contentOf(
      primaryInput,
    )).stringValue();
    final compilationUnit = _parseCompilationUnit(primaryInputSource);
    List<CompilationUnit>? compilationUnits;
    for (final trigger in buildTriggers) {
      if (trigger.checksParts) {
        compilationUnits ??= await _readAndParseCompilationUnits(
          inputTracker,
          primaryInput,
          compilationUnit,
          phaseNum,
        );
        if (trigger.triggersOn(compilationUnits)) return true;
      } else {
        if (trigger.triggersOn([compilationUnit])) return true;
      }
    }
    return false;
  }

  /// TODO(davidmorgan): cache parse results, share with deps parsing and
  /// builder parsing.
  static CompilationUnit _parseCompilationUnit(String content) {
    return parseString(content: content, throwIfDiagnostics: false).unit;
  }

  Future<List<CompilationUnit>> _readAndParseCompilationUnits(
    InputTracker inputTracker,
    AssetId id,
    CompilationUnit compilationUnit,
    int phaseNum,
  ) async {
    final result = [compilationUnit];
    for (final directive in compilationUnit.directives) {
      if (directive is! PartDirective) continue;
      final partId = AssetId.resolve(
        Uri.parse(directive.uri.stringValue!),
        from: id,
      );
      // Check that the part is readable, including generating it if it's
      // an output from an earlier phase.
      if (!await _builderFilesystem.isReadable(
        partId,
        phaseNum,
        catchInvalidInputs: true,
      )) {
        continue;
      }
      inputTracker.add(partId);
      result.add(
        _parseCompilationUnit(
          (await _builderFilesystem.contentOf(partId)).stringValue(),
        ),
      );
    }
    return result;
  }

  Future<Iterable<AssetId>> _runPostBuildPhase(
    int phaseNum,
    PostBuildPhase phase,
  ) async {
    var actionNum = 0;
    final outputs = <AssetId>[];
    for (final builderAction in phase.builderActions) {
      outputs.addAll(
        await _runPostBuildAction(phaseNum, actionNum++, builderAction),
      );
    }
    return outputs;
  }

  Future<Iterable<AssetId>> _runPostBuildAction(
    int phaseNum,
    int actionNum,
    PostBuildAction action,
  ) async {
    final outputs = <AssetId>[];
    for (final input in buildState.sources.followedBy(
      buildState.actualOutputs,
    )) {
      if (!buildStepPlan.actionMatches(action, input)) continue;
      final buildStepId = PostProcessBuildStepId(
        input: input,
        actionNumber: actionNum,
      );
      outputs.addAll(
        await _runPostProcessBuildStep(
          phaseNum,
          action.builder,
          buildStepId,
          hideOutput: action.hideOutput,
        ),
      );
    }
    return outputs;
  }

  Future<Iterable<AssetId>> _runPostProcessBuildStep(
    int phaseNumber,
    PostProcessBuilder builder,
    PostProcessBuildStepId postProcessBuildStepId, {
    required bool hideOutput,
  }) async {
    final input = postProcessBuildStepId.input;

    if (!await _postProcessBuildStepShouldRun(postProcessBuildStepId)) {
      final oldResult = previousBuildState?.postProcessBuildStepResultFor(
        postProcessBuildStepId,
      );
      if (oldResult != null) {
        buildState.addPostProcessBuildStepResult(
          postProcessBuildStepId,
          oldResult,
        );
      }
      return <AssetId>[];
    }
    // Clean out the impacts of the previous run.

    final logger = buildLog.loggerForOther(
      buildLog.renderId(input),
      contextId: input,
    );
    var deletedPrimaryInput = false;
    final step = PostProcessBuildStepImpl(
      inputId: input,
      buildFilesystem: _builderFilesystem,
      addAsset: (assetId) {
        if (_isFile(assetId)) {
          throw InvalidOutputException(assetId, 'Asset already exists');
        }
      },
      deleteAsset: (assetId) {
        if (!_isFile(assetId)) {
          throw AssetNotFoundException(assetId);
        }
        if (assetId != input) {
          throw InvalidOutputException(
            assetId,
            'Can only delete primary input',
          );
        }
        deletedPrimaryInput = true;
      },
    );

    await BuildLogLogger.scopeLogAsync(() async {
      try {
        await builder.build(step);
      } finally {
        await step.complete();
      }
    }, logger);

    final stepResult = PostProcessBuildStepResult(
      hidden: hideOutput,
      outputs: step.outputs,
      errors: logger.errors,
      deletedPrimaryInput: deletedPrimaryInput,
    );
    buildState.addPostProcessBuildStepResult(
      postProcessBuildStepId,
      stepResult,
    );

    return step.outputs.keys;
  }

  void _markStepSkipped(BuildStepId buildStepId, Iterable<AssetId> outputs) {
    final isHidden =
        buildPhases.inBuildPhases[buildStepId.phaseNumber].hideOutput;
    _builderFilesystem.updateBuildStepResult(
      buildStepId,
      BuildStepResult((b) => b..isHidden = isHidden),
    );
  }

  Future<void> _markStepFailed(
    BuildStepId buildStepId,
    Iterable<AssetId> outputs,
  ) async {
    final isHidden =
        buildPhases.inBuildPhases[buildStepId.phaseNumber].hideOutput;
    _builderFilesystem.updateBuildStepResult(
      buildStepId,
      BuildStepResult((b) {
        b.result = false;
        b.isHidden = isHidden;
      }),
    );
  }

  /// Checks and returns whether any [outputs] need to be updated by
  /// the build step [step].
  ///
  /// As part of checking, builds any inputs that need building.
  Future<StepAction> _computeStepAction(
    BuildStepId step,
    Iterable<AssetId> outputs,
  ) async {
    return await TimedActivity.track.runAsync(() async {
      // Update state for primary input if needed.
      if (buildStepPlan.isDeclaredOutput(step.primaryInput)) {
        if (!buildState.isProcessedOutput(
          buildStepPlan: buildStepPlan,
          id: step.primaryInput,
        )) {
          await _buildOutput(step.primaryInput);
        }
      }

      // If a primary input source file has been deleted, the build is skipped.
      if (!buildStepPlan.isDeclaredOutput(step.primaryInput) &&
          (buildInputs.deletedSources.contains(step.primaryInput) ||
              buildInputs.deletedOutputs.contains(step.primaryInput))) {
        return StepAction.skipMissingPrimaryInput;
      }

      // Propagate results for declared output primary input.
      if (buildStepPlan.isDeclaredOutput(step.primaryInput)) {
        final inputStepResult = buildState.stepResult(
          buildStepPlan.stepForDeclaredOutput(step.primaryInput),
        );

        // If the primary input's generating step failed, this build is also
        // failed.
        if (inputStepResult.failed) {
          return StepAction.skipFailedPrimaryInput;
        }

        // If the primary input succeeded but was not output, this build is
        // skipped.
        if (!buildState.isActualOutput(
          buildStepPlan: buildStepPlan,
          id: step.primaryInput,
        )) {
          return StepAction.skipMissingPrimaryInput;
        }
      }

      if (buildInputs.cleanBuild) return StepAction.run;

      if (buildPlan.previousBuild.triggersChanged) return StepAction.run;

      if (buildPlan.phaseOptionsChanged(step.phaseNumber)) {
        return StepAction.run;
      }

      final primaryInput = step.primaryInput;

      if (buildStepPlan.isDeclaredOutput(primaryInput)) {
        final inputStep = buildStepPlan.stepForDeclaredOutput(primaryInput);
        final oldResult = previousBuildState?.stepResultOrNull(inputStep);
        final newResult = buildState.stepResult(inputStep);
        final oldWasOutput =
            oldResult?.result == true &&
            oldResult!.outputs.containsKey(primaryInput);
        final newWasOutput =
            newResult.result == true &&
            newResult.outputs.containsKey(primaryInput);

        if (!oldWasOutput && newWasOutput) {
          return StepAction.run;
        }
      }

      for (final output in outputs) {
        if (buildInputs.deletedSources.contains(output) ||
            buildInputs.deletedOutputs.contains(output)) {
          return StepAction.run;
        }
      }

      final stepResult = previousBuildState?.stepResultOrNull(step);
      if (stepResult == null || !stepResult.hasRun) return StepAction.run;

      // Check for changes to any secondary inputs.
      for (final input in stepResult.inputs) {
        final changed = await _hasInputChanged(
          phaseNumber: step.phaseNumber,
          input: input,
        );

        if (changed) return StepAction.run;
      }

      // Check for changes to any glob inputs.
      for (final globId in stepResult.globsEvaluated) {
        var currentGlobResult = buildState.globResultFor(globId);
        if (currentGlobResult == null) {
          await _evaluateGlob(globId);
          currentGlobResult = buildState.globResultFor(globId);
        }
        if (previousBuildState?.globResultFor(globId)?.digest !=
            currentGlobResult?.digest) {
          return StepAction.run;
        }
      }

      for (final graphId in stepResult.resolverEntrypoints) {
        if (await _hasInputGraphChanged(
          phaseNumber: step.phaseNumber,
          entrypointId: graphId,
        )) {
          return StepAction.run;
        }
      }

      // No input changes: build is not needed, and outputs state is up to date.
      return StepAction.skipReuse;
    });
  }

  /// Whether any source in the _previous build_ transitive import graph
  /// of [entrypointId] has a change visible at [phaseNumber].
  ///
  /// There is a tradeoff between returning early when a first change is
  /// encountered and continuing to process the graph to produce results that
  /// might be useful later. This implementation is eager, it computes whether
  /// every subgraph reachable from [entrypointId] has changed.
  Future<bool> _hasInputGraphChanged({
    required AssetId entrypointId,
    required int phaseNumber,
  }) async {
    // If the result has already been calculated, return it.
    final entrypointGraph =
        (await previousLibraryCycleGraphLoader.libraryCycleGraphOf(
          previousDepsLoader!,
          entrypointId,
        )).valueAt(phase: phaseNumber);
    final maybeResult = changedGraphs[entrypointGraph];
    if (maybeResult != null) {
      return maybeResult;
    }

    final graphsToCheckStack = [entrypointGraph];

    while (graphsToCheckStack.isNotEmpty) {
      final nextGraph = graphsToCheckStack.last;

      // If there are multiple paths to an entrypoint graph, it might have been
      // calculated for another path.
      if (changedGraphs.containsKey(nextGraph)) {
        graphsToCheckStack.removeLast();
        continue;
      }

      // Determine whether there are child graphs not yet evaluated.
      //
      // If so, add them to the stack and "continue" to evaluate those before
      // returning to this graph.
      final childGraphsWithWorkToDo = <LibraryCycleGraph>[];
      for (final childGraph in nextGraph.children) {
        final maybeChildResult = changedGraphs[childGraph];
        if (maybeChildResult == null) {
          childGraphsWithWorkToDo.add(childGraph);
        }
      }
      if (childGraphsWithWorkToDo.isNotEmpty) {
        graphsToCheckStack.addAll(childGraphsWithWorkToDo);
        continue;
      }

      // Determine whether the graph root library cycle has any changed IDs. If
      // so, the graph has changed; if not, check whether any child graph
      // changed.
      var rootLibraryCycleHasChanged = false;
      for (final id in nextGraph.root.ids) {
        if (await _hasInputChanged(phaseNumber: phaseNumber, input: id)) {
          rootLibraryCycleHasChanged = true;
          break;
        }
      }
      if (rootLibraryCycleHasChanged) {
        changedGraphs[nextGraph] = true;
      } else {
        var anyChildHasChanged = false;
        for (final childGraph in nextGraph.children) {
          final childResult = changedGraphs[childGraph];
          if (childResult == null) {
            throw StateError('Child graphs should have been checked.');
          } else if (childResult) {
            anyChildHasChanged = true;
            break;
          }
        }
        changedGraphs[nextGraph] = anyChildHasChanged;
      }
      graphsToCheckStack.removeLast();
    }

    return changedGraphs[entrypointGraph]!;
  }

  /// Whether [input] has a change visible at [phaseNumber].
  Future<bool> _hasInputChanged({
    required AssetId input,
    required int phaseNumber,
  }) async {
    if (buildStepPlan.isDeclaredOutput(input)) {
      final phase = buildStepPlan.stepForDeclaredOutput(input).phaseNumber;
      if (phase >= phaseNumber) {
        // It's not readable in this phase.
        return false;
      }
      // Ensure that the input was built.
      if (!buildState.isProcessedOutput(
        buildStepPlan: buildStepPlan,
        id: input,
      )) {
        await _buildOutput(input);
      }
      if (_isChangedOutput(input)) {
        return true;
      }
    } else if (buildState.isSource(input)) {
      if (buildInputs.updatedSources.contains(input)) {
        return true;
      }
    } else if (buildInputs.deletedSources.contains(input) ||
        buildInputs.deletedOutputs.contains(input)) {
      return true;
    }
    return false;
  }

  /// Whether the post process build step [buildStepId] should run.
  ///
  /// It should run if its builder options changed or its input changed.
  Future<bool> _postProcessBuildStepShouldRun(
    PostProcessBuildStepId buildStepId,
  ) async {
    final input = buildStepId.input;

    if (buildInputs.cleanBuild) {
      return true;
    }

    if (buildPlan.postBuildOptionsChanged(buildStepId.actionNumber)) {
      return true;
    }

    if (buildStepPlan.isDeclaredOutput(input)) {
      // Check that the input was built.
      if (!buildState.isProcessedOutput(
        buildStepPlan: buildStepPlan,
        id: input,
      )) {
        await _buildOutput(input);
      }
      if (_isChangedOutput(input)) {
        return true;
      }
    } else if (buildState.isSource(input)) {
      if (buildInputs.updatedSources.contains(input)) {
        return true;
      }
    } else {
      throw StateError('Expected declared output or source: $input');
    }

    return false;
  }

  /// Evaluates the glob for [globId].
  ///
  /// This means finding matches of the glob and building them if necessary.
  ///
  /// Generated files are special for two reasons.
  ///
  /// First, they are only visible to the glob if they are generated in an
  /// earlier phase than the phase in which the glob is evaluated. If not, they
  /// are totally invisible: nothing is done for them.
  ///
  /// Second, a generated file might not actually be generated: its builder
  /// might choose at runtime to output nothing. In this case, the non-existent
  /// generated file is still tracked as an input that matched the glob, but is
  /// not useful to something that wants to read the file. In the glob result,
  /// it ends up in `inputs` but not in `results`.
  Future<void> _evaluateGlob(GlobId globId) async {
    if (buildState.hasGlobResult(globId)) {
      return;
    }

    return lazyGlobs.putIfAbsent(globId, () async {
      final glob = Glob(globId.glob);

      // Generated files that match the glob.
      final generatedFileInputs = <AssetId>[];
      // Other types of file that match the glob.
      final otherInputs = <AssetId>[];

      for (final id in buildState.findFiles(
        package: globId.package,
        buildStepPlan: buildStepPlan,
        glob: glob,
      )) {
        if (buildStepPlan.isDeclaredOutput(id)) {
          // Only outputs from an earlier phase can match.
          if (buildStepPlan.stepForDeclaredOutput(id).phaseNumber <
              globId.phaseNumber) {
            generatedFileInputs.add(id);
          }
        } else {
          otherInputs.add(id);
        }
      }

      // Request to build the matching generated files.
      for (final id in generatedFileInputs) {
        await _buildOutput(id);
      }

      // The generated file matches that were output are part of the results of
      // the glob.
      final generatedFileResults = <AssetId>[];
      for (final id in generatedFileInputs) {
        final stepResult = buildState.stepResultOrNull(
          buildStepPlan.stepForDeclaredOutput(id),
        );
        if (stepResult != null &&
            stepResult.succeeded &&
            stepResult.outputs.containsKey(id)) {
          generatedFileResults.add(id);
        }
      }

      final results = [...otherInputs, ...generatedFileResults];
      final digest = md5.convert(utf8.encode(results.join(' ')));

      final globResult = GlobResult((b) {
        b.results.addAll(results);
        b.inputs.addAll(generatedFileInputs.followedBy(otherInputs));
        b.digest = digest;
      });
      buildState.updateGlobResult(globId, globResult);

      unawaited(lazyGlobs.remove(globId));
    });
  }

  /// Sets the state for all [outputs] of a build step, by:
  ///
  /// - Setting `digest` based on what was written.
  /// - Setting `result` based on action success.
  /// - Setting `inputs` based on `inputTracker` and `unusedAssets`.
  /// - Setting `errors`.
  /// - Updating `newPrimaryInputs` and `changedOutputs` as needed.
  Future<void> _setOutputsState(
    AssetId input,
    Iterable<AssetId> outputs,
    BuildStepImpl step,
    Iterable<String> errors, {
    Set<AssetId>? unusedAssets,
  }) async {
    final inputTracker = step.inputTracker;
    final usedInputs = unusedAssets != null && unusedAssets.isNotEmpty
        ? inputTracker.inputs.difference(unusedAssets)
        : inputTracker.inputs;
    final result = errors.isEmpty;
    final phaseNum = step.phase;

    final buildStepResultBuilder = BuildStepResultBuilder()
      ..result = result
      ..isHidden = buildPhases.inBuildPhases[phaseNum].hideOutput
      ..inputs.replace(usedInputs)
      ..globsEvaluated.replace(inputTracker.globsEvaluated)
      ..resolverEntrypoints.replace(inputTracker.resolverEntrypoints)
      ..errors.replace(errors)
      ..partContribution = step.partContribution;
    for (final output in outputs) {
      if (step.outputs.containsKey(output)) {
        final content = step.outputs[output]!;
        buildStepResultBuilder.outputs[output] = content;
      }
    }
    final buildStepResult = buildStepResultBuilder.build();

    final buildStepId = BuildStepId(primaryInput: input, phaseNumber: phaseNum);
    _builderFilesystem.updateBuildStepResult(buildStepId, buildStepResult);
  }

  bool _isFile(AssetId id) =>
      buildState.isFile(buildStepPlan: buildStepPlan, id: id);

  bool _isChangedOutput(AssetId output) {
    final generatingStep = buildStepPlan.stepForDeclaredOutput(output);
    final oldContent = previousBuildState
        ?.stepResultOrNull(generatingStep)
        ?.outputs[output];
    final newContent = buildState.stepResult(generatingStep).outputs[output];
    return oldContent?.digest != newContent?.digest;
  }
}

enum StepAction {
  run,
  skipReuse,
  skipMissingPrimaryInput,
  skipFailedPrimaryInput;

  bool get isSkip => this != run;
}
