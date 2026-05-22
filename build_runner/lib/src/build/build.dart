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
import 'package:watcher/watcher.dart';

import '../build_plan/build_configs.dart';
import '../build_plan/build_options.dart';
import '../build_plan/build_packages.dart';
import '../build_plan/build_phases.dart';
import '../build_plan/build_plan.dart';
import '../build_plan/phase.dart';
import '../build_plan/testing_overrides.dart';
import '../constants.dart';
import '../io/build_output_reader.dart';
import '../io/create_merged_dir.dart';
import '../io/reader_writer.dart';
import '../logging/build_log.dart';
import '../logging/timed_activities.dart';
import 'build_dirs.dart';
import 'build_result.dart';
import 'build_state/asset_graph_json.dart';
import 'build_state/build_state.dart';
import 'build_state/build_step_id.dart';
import 'build_state/build_step_result.dart';
import 'build_state/glob_id.dart';
import 'build_state/glob_result.dart';
import 'build_state/post_process_build_step_id.dart';
import 'build_state/post_process_build_step_result.dart';
import 'input_tracker.dart';
import 'library_cycle_graph/asset_deps_loader.dart';
import 'library_cycle_graph/library_cycle_graph.dart';
import 'library_cycle_graph/library_cycle_graph_loader.dart';
import 'library_cycle_graph/phased_asset_deps.dart';
import 'resolver/analysis_driver_model.dart';
import 'resolver/resolvers_impl.dart';
import 'run_builder.dart';
import 'run_post_process_builder.dart';
import 'single_step_reader_writer.dart';

final ResolversImpl _defaultResolvers = ResolversImpl(
  analysisDriverModel: AnalysisDriverModel(),
);

/// A single build.
class Build {
  final BuildPlan buildPlan;

  // Collaborators.
  final ResourceManager resourceManager;
  final ReaderWriter readerWriter;
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

  /// Generated outputs that have been processed.
  ///
  /// That means they have been checked to determine whether they
  /// need building; if so, those have been built, and state has been
  /// updated accordingly.
  final Set<AssetId> processedOutputs = {};

  /// Globs that have been processed.
  ///
  /// That means they have been checked to determine whether they
  /// need evaluating, and if so their state has been updated accordingly.
  final Set<GlobId> processedGlobs = {};

  /// Inputs that changed since the last build.
  ///
  /// Filled from the `updates` passed in to the build.
  final Set<AssetId> changedInputs = {};

  /// Assets that were deleted since the last build.
  ///
  /// This is used to distinguish between missing sources that were
  /// already known and missing sources that are newly known.
  final Set<AssetId> deletedAssets = {};

  /// Assets that might be new primary inputs since the previous build.
  ///
  /// This means: new inputs, new generated outputs, or generated outputs
  /// from generators that failed in the previous build and succeed in this
  /// build.
  final Set<AssetId> newPrimaryInputs = {};

  /// Outputs that changed since the last build.
  ///
  /// Filled during the build as each output is produced and its digest is
  /// checked against the digest from the previous build.
  final Set<AssetId> changedOutputs = {};

  /// Glob queries that changed since the last build.
  final Set<GlobId> changedGlobs = {};

  /// Build steps for which errors have been shown.
  final Set<BuildStepId> errorsShownSteps = {};

  /// Whether a graph from [previousLibraryCycleGraphLoader] has any changed
  /// transitive source.
  final Map<LibraryCycleGraph, bool> changedGraphs = Map.identity();

  /// The build output.
  BuildOutputReader? _buildOutputReader;

  Build({
    required this.buildPlan,
    required this.readerWriter,
    required this.resourceManager,
    required this.buildState,
  }) : previousDepsLoader =
           buildPlan.previousPhasedAssetDeps == null
               ? null
               : AssetDepsLoader.fromDeps(buildPlan.previousPhasedAssetDeps!),
       resolvers = buildPlan.testingOverrides.resolvers ?? _defaultResolvers,
       resolversImpl = switch (buildPlan.testingOverrides.resolvers ??
           _defaultResolvers) {
         ResolversImpl r => r,
         _ => null,
       };

  BuildOptions get buildOptions => buildPlan.buildOptions;
  TestingOverrides get testingOverrides => buildPlan.testingOverrides;
  BuildPackages get buildPackages => buildPlan.buildPackages;
  BuildConfigs get buildConfigs => buildPlan.buildConfigs;
  BuildPhases get buildPhases => buildPlan.buildPhases;

  BuildOutputReader get buildOutputReader =>
      _buildOutputReader ??= BuildOutputReader(
        buildPlan: buildPlan,
        readerWriter: readerWriter,
        buildState: buildState,
        processedOutputs: processedOutputs,
      );

  Future<BuildResult> run(Set<AssetId> updates) async {
    buildLog.configuration = buildLog.configuration.rebuild(
      (b) => b..singleOutputPackage = buildPackages.singleOutputPackage,
    );
    var result = await _safeBuild(updates);
    if (result.status == BuildStatus.success) {
      final failedSteps = <BuildStepId>{};
      for (final output in processedOutputs) {
        if (!buildState.isDeclaredOutput(output)) continue;
        final step = buildState.stepForDeclaredOutput(output);
        final stepResult = buildState.stepResult(step);
        if (stepResult.failed) {
          failedSteps.add(step);
        }
      }
      if (failedSteps.isNotEmpty) {
        for (final step in failedSteps) {
          if (errorsShownSteps.contains(step)) continue;
          final phase = buildPhases.inBuildPhases[step.phaseNumber];
          final logger = buildLog.loggerFor(
            phase: phase,
            primaryInput: step.primaryInput,
            lazy: phase.isOptional,
          );
          final stepResult = buildState.stepResult(step);
          for (final error in stepResult.errors) {
            logger.severe(error);
          }
        }
      }

      final failedPostProcessSteps = <PostProcessBuildStepId>[];
      for (final entry in buildState.postProcessBuildStepResults) {
        if (entry.value.errors.isNotEmpty) {
          failedPostProcessSteps.add(entry.key);
        }
      }

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
    readerWriter.cache.flush();
    await resourceManager.disposeAll();

    // If requested, create output directories. If that fails, fail the build.
    if (buildPlan.buildOptions.buildDirs.any(
          (target) => target.outputLocation?.path.isNotEmpty ?? false,
        ) &&
        result.status == BuildStatus.success) {
      if (!await createMergedOutputDirectories(
        buildPackages: buildPackages,
        outputSymlinksOnly: buildOptions.outputSymlinksOnly,
        buildDirs: buildOptions.buildDirs,
        buildOutputReader: buildOutputReader,
        readerWriter: readerWriter,
      )) {
        result = result.copyWith(
          status: BuildStatus.failure,
          failureType: FailureType.cantCreate,
        );
      }
    }

    resolvers.reset();
    result = result.copyWith(
      errors: buildLog.finishBuild(
        result: result.status == BuildStatus.success,
        outputs: result.outputs.length,
      ),
    );
    return result;
  }

  Future<Set<AssetId>> _updateBuildState(Set<AssetId> updates) async {
    changedInputs.clear();
    deletedAssets.clear();

    // Check what actually changed for each asset in `updates`.
    readerWriter.cache.invalidate(updates);
    final resolvedUpdates = <AssetId, ChangeType>{};
    final previousSources = <AssetId>{};
    final newDigests = <AssetId, Digest>{};
    for (final id in updates) {
      final oldIsSource = buildState.isSource(id);
      if (oldIsSource) {
        previousSources.add(id);
      }
      final oldExisted = buildState.isFile(id);
      final oldDigest = oldIsSource ? buildState.digestOfSource(id) : null;
      var exists = false;
      Digest? newDigest;
      if (await readerWriter.canRead(id)) {
        exists = true;
        // Assets are only eagerly read if they were an input in the previous
        // build. In that case, they have a digest. Compute the new digest to
        // check if the file changed.
        if (oldDigest != null) {
          try {
            newDigest = await readerWriter.digest(id);
            newDigests[id] = newDigest;
          } catch (_) {
            // Was deleted after `canRead`.
            exists = false;
          }
        }
      }

      if (oldExisted && !exists) {
        resolvedUpdates[id] = ChangeType.REMOVE;
        deletedAssets.add(id);
      } else if (!oldExisted && exists) {
        changedInputs.add(id);
        newPrimaryInputs.add(id);
        resolvedUpdates[id] = ChangeType.ADD;
      } else if (oldExisted &&
          oldDigest != null &&
          exists &&
          oldDigest != newDigest) {
        changedInputs.add(id);
        resolvedUpdates[id] = ChangeType.MODIFY;
      }
    }

    final deleted = buildState.updateForNextBuild(buildPhases, resolvedUpdates);
    for (final id in deleted) {
      await readerWriter.delete(id);
    }
    deletedAssets.addAll(deleted);
    for (final entry in newDigests.entries) {
      buildState.updateSourceDigest(entry.key, entry.value);
    }

    final invalidatedSources = <AssetId>{};
    for (final entry in resolvedUpdates.entries) {
      final id = entry.key;
      final changeType = entry.value;
      if (changeType != ChangeType.ADD && previousSources.contains(id)) {
        invalidatedSources.add(id);
      }
    }
    return invalidatedSources;
  }

  /// Runs a build inside a zone with an error handler and stack chain
  /// capturing.
  Future<BuildResult> _safeBuild(Set<AssetId> idsToCheck) {
    final done = Completer<BuildResult>();
    runZonedGuarded(
      () async {
        final invalidatedSources =
            buildPlan.cleanBuild ? null : await _updateBuildState(idsToCheck);
        for (final id in buildState.sources) {
          if (buildState.isUnreadSource(id) &&
              buildState.declaredOutputsOf(id).isNotEmpty) {
            final digest = await readerWriter.digest(id);
            buildState.updateSourceDigest(id, digest);
          }
        }
        await resolversImpl?.takeLockAndStartBuild(
          buildState,
          invalidatedSources: invalidatedSources,
        );
        final result = await _runPhases();

        // Combine previous phased asset deps, if any, with the newly loaded
        // deps. Because of skipped builds, the newly loaded deps might just
        // say "not generated yet", in which case the old value is retained.
        final currentPhasedAssetDeps =
            resolversImpl?.phasedAssetDeps() ?? PhasedAssetDeps();
        final updatedPhasedAssetDeps =
            buildPlan.previousPhasedAssetDeps == null
                ? currentPhasedAssetDeps
                : buildPlan.previousPhasedAssetDeps!.update(
                  currentPhasedAssetDeps,
                );
        await readerWriter.writeAsBytes(
          AssetId(buildPackages.outputRoot, assetGraphJsonPath),
          AssetGraphJson.serialize(
            buildPlanDigest: buildPlan.buildPlanDigest,
            buildState: buildState,
            phasedAssetDeps: updatedPhasedAssetDeps,
          ),
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
              buildOutputReader: buildOutputReader,
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
    return BuildResult(
      status: BuildStatus.success,
      outputs: outputs.build(),
      buildOutputReader: buildOutputReader,
    );
  }

  /// Returns primary inputs for [package] in [phaseNumber].
  Future<List<AssetId>> _matchingPrimaryInputs(
    String package,
    int phaseNumber,
  ) async {
    // Accumulate in a `Set` because inputs are found once per output.
    final ids = <AssetId>{};
    final phase = buildPhases[phaseNumber] as InBuildPhase;
    final buildPackage = buildPackages[package]!;

    for (final outputId in buildState
        .declaredOutputsForPhase(package, phaseNumber)
        .toList(growable: false)) {
      if (!shouldBuildForDirs(
        outputId,
        buildDirs: buildPlan.buildOptions.buildDirs,
        buildFilters: buildPlan.buildOptions.buildFilters,
        phase: phase,
        buildConfigs: buildConfigs,
      )) {
        continue;
      }

      // Don't build for inputs that aren't visible. This can happen for
      // placeholders like `test/$test$` that are added to each package,
      // since the test dir is not part of the build for non-root packages.
      if (!buildConfigs.isVisibleInBuild(outputId, buildPackage)) continue;

      ids.add(buildState.stepForDeclaredOutput(outputId).primaryInput);
    }
    return ids.toList()..sort();
  }

  /// If [id] is a generated asset, ensures that it has been built.
  ///
  /// If has already been built according to [processedOutputs], returns
  /// immediately.
  ///
  /// If it is currently being built according to [lazyPhases], waits for it to
  /// be built.
  Future<void> _buildOutput(AssetId id) async {
    if (buildState.isDeclaredOutput(id) && !processedOutputs.contains(id)) {
      final step = buildState.stepForDeclaredOutput(id);
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
    final singleStepReaderWriter = SingleStepReaderWriter(
      runningBuild: RunningBuild(
        buildPackages: buildPackages,
        buildConfigs: buildConfigs,
        buildState: buildState,
        assetBuilder: _buildOutput,
        assetIsProcessedOutput: processedOutputs.contains,
        globEvaluator: _evaluateGlob,
      ),
      runningBuildStep: RunningBuildStep(
        phaseNumber: buildStepId.phaseNumber,

        buildPhase: phase,
        primaryPackage: buildStepId.primaryInput.package,
      ),
      readerWriter: readerWriter,
      inputTracker: InputTracker(
        readerWriter.filesystem,
        primaryInput: buildStepId.primaryInput,
        builderLabel: phase.displayName,
      ),
      assetsWritten: {},
    );

    final builderOutputs = expectedOutputs(builder, buildStepId.primaryInput);
    if (!await _buildShouldRun(
      buildStepId,
      builderOutputs,
      singleStepReaderWriter,
    )) {
      buildLog.skipStep(phase: phase, lazy: lazy);
      for (final output in builderOutputs) {
        processedOutputs.add(output);
      }
      return <AssetId>[];
    }

    await _cleanUpStaleOutputs(builderOutputs);

    // Clear input tracking accumulated during `_buildShouldRun`.
    singleStepReaderWriter.inputTracker.clear();

    final unusedAssets = <AssetId>{};
    void reportUnusedAssetsForInput(AssetId input, Iterable<AssetId> assets) {
      testingOverrides.reportUnusedAssetsForInput?.call(input, assets);
      unusedAssets.addAll(assets);
    }

    // Pass `readerWriter` so that if `_allowedByTriggers` reads files to
    // evaluate triggers then they are tracked as inputs.
    final allowedByTriggers = await _allowedByTriggers(
      readerWriter: singleStepReaderWriter,
      phase: phase,
      primaryInput: buildStepId.primaryInput,
    );
    final logger = buildLog.loggerFor(
      phase: phase,
      primaryInput: buildStepId.primaryInput,
      lazy: lazy,
    );
    if (allowedByTriggers) {
      await TimedActivity.build.runAsync(() {
        return runBuilder(
          builder,
          [buildStepId.primaryInput],
          singleStepReaderWriter,
          resolvers,
          logger: logger,
          resourceManager: resourceManager,
          reportUnusedAssetsForInput: reportUnusedAssetsForInput,
          packageConfig: buildPackages.asPackageConfig,
        ).catchError((void _) {
          // Errors tracked through the logger.
        });
      });
    }

    // Update the state for the build step its outputs based on what was read
    // and written.
    await TimedActivity.track.runAsync(
      () => _setOutputsState(
        buildStepId.primaryInput,
        builderOutputs,
        singleStepReaderWriter,
        logger.errors,
        unusedAssets: unusedAssets,
      ),
    );

    if (allowedByTriggers) {
      buildLog.finishStep(
        phase: phase,
        anyOutputs: singleStepReaderWriter.assetsWritten.isNotEmpty,
        anyChangedOutputs: singleStepReaderWriter.assetsWritten.any(
          changedOutputs.contains,
        ),
        lazy: lazy,
      );
    } else {
      buildLog.stepNotTriggered(phase: phase, lazy: lazy);
    }

    return singleStepReaderWriter.assetsWritten;
  }

  /// Whether build triggers allow [phase] to run on [primaryInput].
  ///
  /// This means either the builder does not have `run_only_if_triggered: true`
  /// or it does run only if triggered and is triggered.
  Future<bool> _allowedByTriggers({
    required SingleStepReaderWriter readerWriter,
    required InBuildPhase phase,
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
    final primaryInputSource = await readerWriter.readAsString(primaryInput);
    final compilationUnit = _parseCompilationUnit(primaryInputSource);
    List<CompilationUnit>? compilationUnits;
    for (final trigger in buildTriggers) {
      if (trigger.checksParts) {
        compilationUnits ??= await _readAndParseCompilationUnits(
          readerWriter,
          primaryInput,
          compilationUnit,
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

  static Future<List<CompilationUnit>> _readAndParseCompilationUnits(
    SingleStepReaderWriter stepReaderWriter,
    AssetId id,
    CompilationUnit compilationUnit,
  ) async {
    final result = [compilationUnit];
    for (final directive in compilationUnit.directives) {
      if (directive is! PartDirective) continue;
      final partId = AssetId.resolve(
        Uri.parse(directive.uri.stringValue!),
        from: id,
      );
      if (!await stepReaderWriter.canRead(partId)) continue;
      result.add(
        _parseCompilationUnit(await stepReaderWriter.readAsString(partId)),
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
      if (!buildState.actionMatches(action, input)) continue;
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
    final stepReaderWriter = SingleStepReaderWriter(
      runningBuild: RunningBuild(
        buildPackages: buildPackages,
        buildConfigs: buildConfigs,
        buildState: buildState,
        assetBuilder: _buildOutput,
        assetIsProcessedOutput: processedOutputs.contains,
        globEvaluator: _evaluateGlob,
      ),
      runningBuildStep: RunningBuildStep(
        phaseNumber: phaseNumber,
        buildPhase: buildPhases.postBuildPhase,
        primaryPackage: input.package,
      ),
      readerWriter: readerWriter,
      inputTracker: InputTracker(readerWriter.filesystem, primaryInput: input),
      assetsWritten: {},
    );

    final existingOutputs =
        buildState
            .postProcessBuildStepResultFor(postProcessBuildStepId)
            ?.outputs ??
        const <AssetId>{};
    if (!await _postProcessBuildStepShouldRun(
      postProcessBuildStepId,
      stepReaderWriter,
    )) {
      processedOutputs.addAll(existingOutputs);
      return <AssetId>[];
    }
    // Clear input tracking accumulated during `_buildShouldRun`.
    stepReaderWriter.inputTracker.clear();

    // Clean out the impacts of the previous run.
    await _cleanUpStaleOutputs(existingOutputs);
    buildState.removePostProcessBuildResult(postProcessBuildStepId);

    final logger = buildLog.loggerForOther(
      buildLog.renderId(input),
      contextId: input,
    );
    final outputs = <AssetId>{};
    var deletedPrimaryInput = false;
    await runPostProcessBuilder(
      builder,
      input,
      stepReaderWriter,
      logger,
      addAsset: (assetId) {
        if (buildState.isFile(assetId)) {
          throw InvalidOutputException(assetId, 'Asset already exists');
        }
        outputs.add(assetId);
      },
      deleteAsset: (assetId) {
        if (!buildState.isFile(assetId)) {
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
    ).catchError((void _) {
      // Errors tracked through the logger
    });

    final assetsWritten = stepReaderWriter.assetsWritten.toSet();

    final stepResult = PostProcessBuildStepResult(
      hidden: hideOutput,
      outputs: assetsWritten,
      errors: logger.errors,
      deletedPrimaryInput: deletedPrimaryInput,
    );
    buildState.addPostProcessBuildStepResult(
      postProcessBuildStepId,
      stepResult,
    );

    return assetsWritten;
  }

  void _markStepSkipped(BuildStepId buildStepId, Iterable<AssetId> outputs) {
    final isHidden = buildState.stepResult(buildStepId).isHidden;
    buildState.updateBuildStepResult(
      buildStepId,
      BuildStepResult((b) => b..isHidden = isHidden),
    );
    for (final output in outputs) {
      processedOutputs.add(output);
    }
  }

  /// Marks the build step as failed and clears output digests.
  Future<void> _markStepFailed(
    BuildStepId buildStepId,
    Iterable<AssetId> outputs,
  ) async {
    final isHidden = buildState.stepResult(buildStepId).isHidden;
    buildState.updateBuildStepResult(
      buildStepId,
      BuildStepResult((b) {
        b.result = false;
        b.isHidden = isHidden;
      }),
    );
    for (final output in outputs) {
      processedOutputs.add(output);
    }
  }

  /// Checks and returns whether any [outputs] need to be updated by
  /// the build step [step].
  ///
  /// As part of checking, builds any inputs that need building.
  Future<bool> _buildShouldRun(
    BuildStepId step,
    Iterable<AssetId> outputs,
    SingleStepReaderWriter readerWriter,
  ) async {
    return await TimedActivity.track.runAsync(() async {
      // Update state for primary input if needed.
      if (buildState.isDeclaredOutput(step.primaryInput)) {
        if (!processedOutputs.contains(step.primaryInput)) {
          await _buildOutput(step.primaryInput);
        }
      }

      // If the primary input has been deleted, the build is skipped.
      if (deletedAssets.contains(step.primaryInput)) {
        if (buildState.isMissingSource(step.primaryInput)) {
          await _cleanUpStaleOutputs(outputs);
          _markStepSkipped(step, outputs);
          return false;
        }
      }

      // Propagate results for declared output primary input.
      if (buildState.isDeclaredOutput(step.primaryInput)) {
        final inputStepResult = buildState.stepResult(
          buildState.stepForDeclaredOutput(step.primaryInput),
        );

        // If the primary input's generating step failed, this build is also
        // failed.
        if (inputStepResult.failed) {
          await _markStepFailed(step, outputs);
          return false;
        }

        // If the primary input succeeded but was not output, this build is
        // skipped.
        if (!buildState.isActualOutput(step.primaryInput)) {
          await _cleanUpStaleOutputs(outputs);
          _markStepSkipped(step, outputs);
          return false;
        }
      }

      if (buildPlan.cleanBuild) return true;

      if (buildPlan.triggersChanged) return true;

      if (buildPlan.phaseOptionsChanged(step.phaseNumber)) {
        return true;
      }

      if (newPrimaryInputs.contains(step.primaryInput)) return true;

      for (final output in outputs) {
        if (deletedAssets.contains(output)) return true;
      }

      final stepResult = buildState.stepResult(step);
      if (!stepResult.hasRun) return true;

      // Check for changes to any secondary inputs.
      for (final input in stepResult.inputs) {
        final changed = await _hasInputChanged(
          phaseNumber: step.phaseNumber,
          input: input,
        );

        if (changed) return true;
      }

      // Check for changes to any glob inputs.
      for (final globId in stepResult.globsEvaluated) {
        if (!processedGlobs.contains(globId)) {
          await _evaluateGlob(globId);
        }
        if (changedGlobs.contains(globId)) return true;
      }

      for (final graphId in stepResult.resolverEntrypoints) {
        if (await _hasInputGraphChanged(
          phaseNumber: step.phaseNumber,
          entrypointId: graphId,
        )) {
          return true;
        }
      }

      // No input changes: build is not needed, and outputs state is up to date.
      for (final output in outputs) {
        processedOutputs.add(output);
      }

      return false;
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
    final entrypointGraph = (await previousLibraryCycleGraphLoader
        .libraryCycleGraphOf(
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
    if (buildState.isDeclaredOutput(input)) {
      final phase = buildState.stepForDeclaredOutput(input).phaseNumber;
      if (phase >= phaseNumber) {
        // It's not readable in this phase.
        return false;
      }
      // Ensure that the input was built, so [changedOutputs] is updated.
      if (!processedOutputs.contains(input)) {
        await _buildOutput(input);
      }
      if (changedOutputs.contains(input)) {
        return true;
      }
    } else if (buildState.isSource(input)) {
      if (changedInputs.contains(input)) {
        return true;
      }
    } else if (buildState.isMissingSource(input)) {
      // It's only a newly-deleted asset if it's also in [deletedAssets].
      if (deletedAssets.contains(input)) {
        return true;
      }
    }
    return false;
  }

  /// Whether the post process build step [buildStepId] should run.
  ///
  /// It should run if its builder options changed or its input changed.
  Future<bool> _postProcessBuildStepShouldRun(
    PostProcessBuildStepId buildStepId,
    SingleStepReaderWriter stepReaderWriter,
  ) async {
    final input = buildStepId.input;

    if (buildPlan.cleanBuild) {
      return true;
    }

    if (buildPlan.postBuildOptionsChanged(buildStepId.actionNumber)) {
      return true;
    }

    if (buildState.isDeclaredOutput(input)) {
      // Check that the input was built, so [changedOutputs] is updated.
      if (!processedOutputs.contains(input)) {
        await _buildOutput(input);
      }
      if (changedOutputs.contains(input)) {
        return true;
      }
    } else if (buildState.isSource(input)) {
      if (changedInputs.contains(input)) {
        return true;
      }
    } else {
      throw StateError('Expected declared output or source: $input');
    }

    return false;
  }

  /// Deletes any of [outputs] which previously were output.
  ///
  /// This should be called after deciding that an asset really needs to be
  /// regenerated based on its inputs hash changing. All assets in [outputs]
  /// must be generated assets.
  Future<void> _cleanUpStaleOutputs(Iterable<AssetId> outputs) async {
    for (final output in outputs) {
      if (buildState.isActualOutput(output) ||
          buildState.isActualPostOutput(output)) {
        await _delete(output);
      }
    }
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
    if (processedGlobs.contains(globId)) {
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
        glob: glob,
      )) {
        if (buildState.isDeclaredOutput(id)) {
          // Only outputs from an earlier phase can match.
          if (buildState.stepForDeclaredOutput(id).phaseNumber <
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
        final stepResult = buildState.stepResult(
          buildState.stepForDeclaredOutput(id),
        );
        if (buildState.isActualOutput(id) && stepResult.succeeded) {
          generatedFileResults.add(id);
        }
      }

      final results = [...otherInputs, ...generatedFileResults];
      final digest = md5.convert(utf8.encode(results.join(' ')));

      final previousGlobResult = buildState.globResultFor(globId);
      if (previousGlobResult == null || previousGlobResult.digest != digest) {
        changedGlobs.add(globId);
      }
      processedGlobs.add(globId);

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
    SingleStepReaderWriter stepReaderWriter,
    Iterable<String> errors, {
    Set<AssetId>? unusedAssets,
  }) async {
    if (outputs.isEmpty) return;
    final inputTracker = stepReaderWriter.inputTracker;
    final usedInputs =
        unusedAssets != null && unusedAssets.isNotEmpty
            ? inputTracker.inputs.difference(unusedAssets)
            : inputTracker.inputs;
    final result = errors.isEmpty;
    final phaseNum = stepReaderWriter.phase;

    final buildStepResultBuilder =
        BuildStepResultBuilder()
          ..result = result
          ..isHidden = buildPhases.inBuildPhases[phaseNum].hideOutput
          ..inputs.replace(usedInputs)
          ..globsEvaluated.replace(inputTracker.globsEvaluated)
          ..resolverEntrypoints.replace(inputTracker.resolverEntrypoints)
          ..errors.replace(errors);
    for (final output in outputs) {
      if (stepReaderWriter.assetsWritten.contains(output)) {
        buildStepResultBuilder.outputs[output] = await readerWriter.digest(
          output,
        );
      }
    }
    final buildStepResult = buildStepResultBuilder.build();

    final buildStepId = BuildStepId(primaryInput: input, phaseNumber: phaseNum);
    final previousBuildStepResult = buildState.stepResult(buildStepId);
    final previousResult = previousBuildStepResult.result;
    buildState.updateBuildStepResult(buildStepId, buildStepResult);

    if (result == false) {
      errorsShownSteps.add(buildStepId);
    }

    for (final output in outputs) {
      final oldDigest = previousBuildStepResult.outputs[output];
      final newDigest = buildStepResult.outputs[output];

      // A transition from (missing or failed) to (written and not failed) is
      // a new primary input that triggers generation even if no content
      // changed.
      if ((oldDigest == null || previousResult == false) &&
          (newDigest != null && result)) {
        newPrimaryInputs.add(output);
      }
      // Only a change to content matters for non-primary inputs.
      if (oldDigest != newDigest) {
        changedOutputs.add(output);
      }

      processedOutputs.add(output);
    }
  }

  Future _delete(AssetId id) => readerWriter.delete(id);
}
