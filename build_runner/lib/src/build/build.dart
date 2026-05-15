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
import '../build_plan/build_step_plan.dart';
import '../build_plan/phase.dart';
import '../build_plan/testing_overrides.dart';
import '../constants.dart';
import '../io/build_output_reader.dart';
import '../io/create_merged_dir.dart';
import '../io/reader_writer.dart';
import '../logging/build_log.dart';
import '../logging/timed_activities.dart';
import 'asset_graph/asset_graph_json.dart';
import 'asset_graph/build_step_id.dart';
import 'asset_graph/build_step_result.dart';
import 'asset_graph/glob_id.dart';
import 'asset_graph/glob_result.dart';
import 'asset_graph/graph.dart';
import 'asset_graph/node.dart';
import 'asset_graph/post_process_build_step_id.dart';
import 'asset_graph/post_process_build_step_result.dart';
import 'build_dirs.dart';
import 'build_result.dart';
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
  BuildPlan buildPlan;

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
  final AssetGraph assetGraph;
  final lazyPhases = <String, Future<Iterable<AssetId>>>{};
  final lazyGlobs = <GlobId, Future<void>>{};

  /// Generated outputs that have been processed.
  ///
  /// That means they have been checked to determine whether they
  /// need building; if so, those have been built, and state has been
  /// updated accordingly.
  final Set<AssetId> processedOutputs = {};

  /// Glob nodes that have been processed.
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
  /// This is used to distinguish between `missingSource` nodes that were
  /// already missing and `missingSource` nodes that are newly missing.
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
    required this.assetGraph,
  }) : previousDepsLoader =
           buildPlan.previousPhasedAssetDeps == null
               ? null
               : AssetDepsLoader.fromDeps(buildPlan.previousPhasedAssetDeps!),
       resolvers = buildPlan.testingOverrides.resolvers ?? _defaultResolvers,
       resolversImpl = switch (buildPlan.testingOverrides.resolvers ??
           _defaultResolvers) {
         ResolversImpl r => r,
         _ => null,
       } {
    assetGraph.buildPlan = buildPlan;
  }

  BuildOptions get buildOptions => buildPlan.buildOptions;
  TestingOverrides get testingOverrides => buildPlan.testingOverrides;
  BuildPackages get buildPackages => buildPlan.buildPackages;
  BuildConfigs get buildConfigs => buildPlan.buildConfigs;
  BuildPhases get buildPhases => buildPlan.buildPhases;

  BuildOutputReader get buildOutputReader =>
      _buildOutputReader ??= BuildOutputReader(
        buildPlan: buildPlan,
        readerWriter: readerWriter,
        assetGraph: assetGraph,
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
        final node = assetGraph.get(output);
        if (node == null || node.type != NodeType.generated) continue;
        final config = buildPlan.buildStepPlan.expectedOutputs[output]!;
        final buildStepId = config.buildStepId;
        final stepResult = assetGraph.buildStepResultFor(buildStepId);
        if (stepResult != null && stepResult.result == false) {
          failedSteps.add(buildStepId);
        }
      }
      if (failedSteps.isNotEmpty) {
        for (final buildStepId in failedSteps) {
          if (errorsShownSteps.contains(buildStepId)) continue;
          final phase = buildPhases.inBuildPhases[buildStepId.phaseNumber];
          final logger = buildLog.loggerFor(
            phase: phase,
            primaryInput: buildStepId.primaryInput,
            lazy: phase.isOptional,
          );
          final stepResult = assetGraph.buildStepResultFor(buildStepId)!;
          for (final error in stepResult.errors) {
            logger.severe(error);
          }
        }
      }

      final failedPostProcessSteps = <PostProcessBuildStepId>[];
      for (final packageResults
          in assetGraph.allPostProcessBuildStepResults.values) {
        for (final entry in packageResults.entries) {
          if (entry.value.errors.isNotEmpty) {
            failedPostProcessSteps.add(entry.key);
          }
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
          final stepResult = assetGraph.postProcessBuildStepResultFor(id)!;
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

  Future<Set<AssetId>> _updateAssetGraph(Set<AssetId> updates) async {
    changedInputs.clear();
    deletedAssets.clear();

    // Check what actually changed for each asset in `updates`.
    readerWriter.cache.invalidate(updates);
    final resolvedUpdates = <AssetId, ChangeType>{};
    final previousSourceNodes = <AssetId>{};
    final newDigests = <AssetId, Digest>{};
    for (final id in updates) {
      final oldNode = assetGraph.get(id);
      if (oldNode?.type == NodeType.source) {
        previousSourceNodes.add(id);
      }
      final oldExisted =
          oldNode != null && oldNode.type != NodeType.missingSource;
      final oldDigest = oldNode?.digest;
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

    final deleted = await assetGraph.updateAndInvalidate(
      buildPhases,
      resolvedUpdates,
    );
    for (final id in deleted) {
      await readerWriter.delete(id);
    }
    deletedAssets.addAll(deleted);
    for (final entry in newDigests.entries) {
      assetGraph.updateNode(entry.key, (nodeBuilder) {
        nodeBuilder.digest = entry.value;
      });
    }

    final invalidatedSources = <AssetId>{};
    for (final entry in resolvedUpdates.entries) {
      final id = entry.key;
      final changeType = entry.value;
      if (changeType != ChangeType.ADD && previousSourceNodes.contains(id)) {
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
            buildPlan.cleanBuild ? null : await _updateAssetGraph(idsToCheck);
        if (invalidatedSources != null) {
          buildPlan = buildPlan.copyWith(
            buildStepPlan: BuildStepPlan.create(
              buildPhases: buildPlan.buildPhases,
              sources: assetGraph.sources.toSet(),
              buildPackages: buildPlan.buildPackages,
            ),
          );
        }
        for (final id in assetGraph.sources) {
          final node = assetGraph.get(id)!;
          if (node.digest == null && node.primaryOutputs.isNotEmpty) {
            final digest = await readerWriter.digest(id);
            assetGraph.updateNode(id, (nodeBuilder) {
              nodeBuilder.digest = digest;
            });
          }
        }
        await resolversImpl?.takeLockAndStartBuild(
          assetGraph,
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
          AssetId(buildPackages.outputRoot, assetGraphPath),
          AssetGraphJson.serialize(
            buildPlanDigest: buildPlan.buildPlanDigest,
            assetGraph: assetGraph,
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
    final outputs = <AssetId>{};
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
        final future = lazyPhases.putIfAbsent(
          '${buildStepId.phaseNumber}|${buildStepId.primaryInput}',
          () => _buildForPrimaryInput(
            buildStepId: buildStepId,
            phase: phase,
            lazy: false,
          ),
        );
        outputs.addAll(await future);
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
    // Assume success, `_assetGraph.failedOutputs` will be checked later.
    return BuildResult(
      status: BuildStatus.success,
      outputs: outputs.toBuiltList(),
      buildOutputReader: buildOutputReader,
    );
  }

  /// Returns primary inputs for [package] in [phaseNumber].
  Future<List<AssetId>> _matchingPrimaryInputs(
    String package,
    int phaseNumber,
  ) async {
    final ids = <AssetId>{};
    final phase = buildPhases[phaseNumber] as InBuildPhase;
    final packageNode = buildPackages[package]!;

    for (final buildStepId in buildPlan.buildStepPlan.scheduledBuildSteps) {
      if (buildStepId.phaseNumber != phaseNumber) continue;
      if (buildStepId.primaryInput.package != package) continue;

      // Check if any expected output for this build step is visible and should be built!
      final expectedOutputs =
          buildPlan.buildStepPlan.primaryOutputsByStep[buildStepId] ??
          BuiltSet<AssetId>();
      bool hasVisibleOutput = false;
      for (final outputId in expectedOutputs) {
        if (shouldBuildForDirs(
          outputId,
          buildDirs: buildPlan.buildOptions.buildDirs,
          buildFilters: buildPlan.buildOptions.buildFilters,
          phase: phase,
          buildConfigs: buildConfigs,
        ) && buildConfigs.isVisibleInBuild(outputId, packageNode)) {
          hasVisibleOutput = true;
          break;
        }
      }

      if (hasVisibleOutput) {
        ids.add(buildStepId.primaryInput);
      }
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
    final config = buildPlan.buildStepPlan.expectedOutputs[id];
    if (config != null && !processedOutputs.contains(id)) {
      final buildStepId = config.buildStepId;
      await lazyPhases.putIfAbsent(
        '${buildStepId.phaseNumber}|${buildStepId.primaryInput}',
        () async {
          final phase = buildPhases.inBuildPhases[buildStepId.phaseNumber];
          return _buildForPrimaryInput(
            buildStepId: buildStepId,
            phase: phase,
            lazy: true,
          );
        },
      );
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
        buildPlan: buildPlan,
        buildPackages: buildPackages,
        buildConfigs: buildConfigs,
        assetGraph: assetGraph,
        nodeBuilder: _buildOutput,
        assetIsProcessedOutput: processedOutputs.contains,
        globEvaluator: _evaluateGlob,
      ),
      runningBuildStep: RunningBuildStep(
        buildStepId: buildStepId,
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

    final builderOutputs =
        buildPlan.buildStepPlan.primaryOutputsByStep[buildStepId] ??
        BuiltSet<AssetId>();
    if (!await _buildShouldRun(
      buildStepId,
      builderOutputs,
      singleStepReaderWriter,
    )) {
      buildLog.skipStep(phase: phase, lazy: lazy);
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

    // Update the state for all the `builderOutputs` nodes based on what was
    // read and written.
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
    for (final buildStepId in assetGraph.postProcessBuildStepIds(
      package: action.package,
    )) {
      if (buildStepId.actionNumber != actionNum) continue;
      final inputNode = assetGraph.get(buildStepId.input)!;
      if (inputNode.type == NodeType.source ||
          inputNode.type == NodeType.generated && inputNode.wasOutput) {
        outputs.addAll(
          await _runPostProcessBuildStep(
            phaseNum,
            action.builder,
            buildStepId,
            hideOutput: action.hideOutput,
          ),
        );
      }
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
    final inputNode = assetGraph.get(input)!;
    final stepReaderWriter = SingleStepReaderWriter(
      runningBuild: RunningBuild(
        buildPlan: buildPlan,
        buildPackages: buildPackages,
        buildConfigs: buildConfigs,
        assetGraph: assetGraph,
        nodeBuilder: _buildOutput,
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
        assetGraph
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
    for (final output in existingOutputs) {
      assetGraph.removePostProcessOutput(output);
    }
    assetGraph.updatePostProcessBuildStepResult(
      postProcessBuildStepId,
      PostProcessBuildStepResult(hidden: hideOutput),
    );

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
        if (assetGraph.contains(assetId)) {
          throw InvalidOutputException(assetId, 'Asset already exists');
        }
        final node = AssetNode.postGenerated(assetId);
        assetGraph.add(node);
        outputs.add(assetId);
      },
      deleteAsset: (assetId) {
        if (!assetGraph.contains(assetId)) {
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

    // Reset the state for all the output nodes based on what was read and
    // written.
    assetGraph.updateNode(inputNode.id, (nodeBuilder) {
      nodeBuilder.primaryOutputs.addAll(assetsWritten);
    });

    final stepResult = PostProcessBuildStepResult(
      hidden: hideOutput,
      outputs: assetsWritten,
      errors: logger.errors,
      deletedPrimaryInput: deletedPrimaryInput,
    );
    assetGraph.updatePostProcessBuildStepResult(
      postProcessBuildStepId,
      stepResult,
    );

    return assetsWritten;
  }

  /// Marks the build step as skipped and clears output digests.
  void _markBuildStepSkipped(
    BuildStepId buildStepId,
    Iterable<AssetId> outputs,
  ) {
    assetGraph.updateBuildStepResult(buildStepId, BuildStepResult());
    for (final output in outputs) {
      assetGraph.updateNodeIfPresent(output, (nodeBuilder) {
        nodeBuilder.digest = null;
      });
      processedOutputs.add(output);
    }
  }

  /// Marks the build step as failed and clears output digests.
  Future<void> _markBuildStepFailed(
    BuildStepId buildStepId,
    Iterable<AssetId> outputs,
  ) async {
    assetGraph.updateBuildStepResult(
      buildStepId,
      BuildStepResult((b) => b..result = false),
    );
    for (final output in outputs) {
      assetGraph.updateNodeIfPresent(output, (nodeBuilder) {
        nodeBuilder.digest = null;
      });
      processedOutputs.add(output);
    }
  }

  /// Checks and returns whether any [outputs] need to be updated by
  /// the build step [buildStepId].
  ///
  /// As part of checking, builds any inputs that need building.
  Future<bool> _buildShouldRun(
    BuildStepId buildStepId,
    Iterable<AssetId> outputs,
    SingleStepReaderWriter readerWriter,
  ) async {
    return await TimedActivity.track.runAsync(() async {
      // Update state for primary input if needed.
      var primaryInputNode = assetGraph.get(buildStepId.primaryInput);
      if (primaryInputNode?.type == NodeType.generated) {
        if (!processedOutputs.contains(buildStepId.primaryInput)) {
          await _buildOutput(buildStepId.primaryInput);
          primaryInputNode = assetGraph.get(buildStepId.primaryInput);
        }
      }

      // If the primary input has been deleted, the build is skipped.
      if (deletedAssets.contains(buildStepId.primaryInput)) {
        if (primaryInputNode?.type == NodeType.missingSource) {
          await _cleanUpStaleOutputs(outputs);
          _markBuildStepSkipped(buildStepId, outputs);
          return false;
        }
      }

      // Propagate results for generated node inputs.
      if (primaryInputNode?.type == NodeType.generated) {
        final inputConfiguration =
            buildPlan.buildStepPlan.expectedOutputs[primaryInputNode!.id]!;
        final inputStepResult = assetGraph.buildStepResultFor(
          inputConfiguration.buildStepId,
        );

        // If the primary input's generating step failed, this build is also
        // failed.
        if (inputStepResult != null && inputStepResult.result == false) {
          await _markBuildStepFailed(buildStepId, outputs);
          return false;
        }

        // If the primary input succeeded but was not output, this build is
        // skipped.
        if (!primaryInputNode.wasOutput) {
          await _cleanUpStaleOutputs(outputs);
          _markBuildStepSkipped(buildStepId, outputs);
          return false;
        }
      }

      if (buildPlan.cleanBuild) return true;

      if (buildPlan.triggersChanged) return true;

      if (buildPlan.phaseOptionsChanged(buildStepId.phaseNumber)) {
        return true;
      }

      if (newPrimaryInputs.contains(buildStepId.primaryInput)) return true;

      for (final output in outputs) {
        if (deletedAssets.contains(output)) return true;
      }

      final stepResult = assetGraph.buildStepResultFor(buildStepId);

      if (stepResult == null || stepResult.result == null) return true;

      // Check for changes to any secondary inputs.
      for (final input in stepResult.inputs) {
        final changed = await _hasInputChanged(
          phaseNumber: buildStepId.phaseNumber,
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
          phaseNumber: buildStepId.phaseNumber,
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

      // If there are multiple paths to a node, it might have been calculated
      // for another path.
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
    var inputNode = assetGraph.get(input);
    if (inputNode == null) {
      final config = buildPlan.buildStepPlan.expectedOutputs[input];
      if (config != null) {
        if (config.phaseNumber >= phaseNumber) {
          return false;
        }
        if (!processedOutputs.contains(input)) {
          await _buildOutput(input);
        }
        if (changedOutputs.contains(input)) {
          return true;
        }
        return false;
      }
    }

    if (inputNode == null) return false;

    if (inputNode.type == NodeType.generated) {
      if (buildPlan.buildStepPlan.expectedOutputs[input]!.phaseNumber >= phaseNumber) {
        // It's not readable in this phase.
        return false;
      }
      // Ensure that the input was built, so [changedOutputs] is updated.
      if (!processedOutputs.contains(input)) {
        await _buildOutput(inputNode.id);
      }
      if (changedOutputs.contains(input)) {
        return true;
      }
    } else if (inputNode.type == NodeType.source) {
      if (changedInputs.contains(input)) {
        return true;
      }
    } else if (inputNode.type == NodeType.missingSource) {
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
    final node = assetGraph.get(input)!;

    if (buildPlan.cleanBuild) {
      return true;
    }

    if (buildPlan.postBuildOptionsChanged(buildStepId.actionNumber)) {
      return true;
    }

    if (node.type == NodeType.generated) {
      // Check that the input was built, so [changedOutputs] is updated.
      if (!processedOutputs.contains(node.id)) {
        await _buildOutput(node.id);
      }
      if (changedOutputs.contains(input)) {
        return true;
      }
    } else if (node.type == NodeType.source) {
      if (changedInputs.contains(input)) {
        return true;
      }
    } else {
      throw StateError('Expected generated or source node: $node');
    }

    return false;
  }

  /// Deletes any of [outputs] which previously were output.
  ///
  /// This should be called after deciding that an asset really needs to be
  /// regenerated based on its inputs hash changing. All assets in [outputs]
  /// must correspond to a [AssetNode.generated].
  Future<void> _cleanUpStaleOutputs(Iterable<AssetId> outputs) async {
    for (final output in outputs) {
      final node = assetGraph.get(output);
      if (node != null && node.isGenerated && node.wasOutput) {
        await _delete(output);
      }
    }
  }

  /// Builds the glob node with [globId].
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
  /// not useful to something that wants to read the file. On the glob node, it
  /// ends up in `inputs` but not in `results`.
  ///
  ///
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

      final allPackageIds = {
        ...assetGraph.packageFileIds(globId.package, glob: glob),
        for (final id in buildPlan.buildStepPlan.expectedOutputs.keys)
          if (id.package == globId.package && glob.matches(id.path)) id,
      };

      for (final id in allPackageIds) {
        final node = assetGraph.get(id);
        final config = buildPlan.buildStepPlan.expectedOutputs[id];
        // Generated nodes are only considered at all if they are output in
        // an earlier phase.
        if (config != null) {
          if (config.phaseNumber < globId.phaseNumber) {
            generatedFileInputs.add(id);
          }
        } else if (node != null) {
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
        final node = assetGraph.get(id);
        if (node != null && node.type == NodeType.generated) {
          final nodeConfig = buildPlan.buildStepPlan.expectedOutputs[id]!;
          final stepResult = assetGraph.buildStepResultFor(
            nodeConfig.buildStepId,
          );
          if (node.wasOutput &&
              stepResult != null &&
              stepResult.result == true) {
            generatedFileResults.add(id);
          }
        }
      }

      final results = [...otherInputs, ...generatedFileResults];
      final digest = md5.convert(utf8.encode(results.join(' ')));

      final previousGlobResult = assetGraph.globResultFor(globId);
      if (previousGlobResult == null || previousGlobResult.digest != digest) {
        changedGlobs.add(globId);
      }
      processedGlobs.add(globId);

      final globResult = GlobResult((b) {
        b.results.addAll(results);
        b.inputs.addAll(generatedFileInputs.followedBy(otherInputs));
        b.digest = digest;
      });
      assetGraph.updateGlobResult(globId, globResult);

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

    final outputDigests = <AssetId, Digest>{};
    for (final output in outputs) {
      final wasOutput = stepReaderWriter.assetsWritten.contains(output);
      final digest = wasOutput ? await readerWriter.digest(output) : null;
      if (digest != null) {
        outputDigests[output] = digest;
      }
    }

    final phaseNum = stepReaderWriter.phase;
    final buildStepId = BuildStepId(primaryInput: input, phaseNumber: phaseNum);
    final stepResult = BuildStepResult((b) {
      b.result = result;
      b.isHidden = buildPhases.inBuildPhases[phaseNum].hideOutput;
      b.inputs.replace(usedInputs);
      b.outputDigests.replace(outputDigests);
      b.globsEvaluated.replace(inputTracker.globsEvaluated);
      b.resolverEntrypoints.replace(inputTracker.resolverEntrypoints);
      b.errors.replace(errors);
    });

    final previousResult = assetGraph.buildStepResultFor(buildStepId)?.result;
    assetGraph.updateBuildStepResult(buildStepId, stepResult);

    if (result == false) {
      errorsShownSteps.add(buildStepId);
    }

    for (final output in outputs) {
      final wasOutput = stepReaderWriter.assetsWritten.contains(output);
      final digest = wasOutput ? await readerWriter.digest(output) : null;
      var outputNode = assetGraph.get(output);

      // Shadow verification assertion!
      if (stepResult.outputDigests[output] != digest) {
        throw StateError(
          'Shadow verification mismatch: BuildStepResult digest '
          '${stepResult.outputDigests[output]} != AssetGraph digest $digest',
        );
      }

      // A transition from (missing or failed) to (written and not failed) is
      // a new primary input that triggers generation even if no content
      // changed.
      if ((outputNode?.digest == null || previousResult == false) &&
          (digest != null && result)) {
        newPrimaryInputs.add(output);
      }
      // Only a change to content matters for non-primary inputs.
      if (outputNode?.digest != digest) {
        changedOutputs.add(output);
      }

      if (outputNode == null) {
        final newNode = AssetNode.generated(
          output,
          digest: digest,
        );
        assetGraph.add(newNode);
      } else {
        assetGraph.updateNode(output, (nodeBuilder) {
          nodeBuilder.digest = digest;
        });
      }

      processedOutputs.add(output);
    }
  }

  Future _delete(AssetId id) => readerWriter.delete(id);
}
