// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

// ignore: implementation_imports
import 'package:build_runner/src/internal.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../asset/exceptions.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../asset_graph/optional_output_tracker.dart';
import '../asset_graph/post_process_build_step_id.dart';
import '../builder/post_process_builder.dart';
import '../environment/build_environment.dart';
import '../library_cycle_graph/asset_deps_loader.dart';
import '../library_cycle_graph/library_cycle_graph.dart';
import '../library_cycle_graph/library_cycle_graph_loader.dart';
import '../logging/build_log.dart';
import '../logging/timed_activities.dart';
import '../performance_tracking/performance_tracking_resolvers.dart';
import '../resolvers/analysis_driver_model.dart';
import '../resource/resource.dart';
import '../state/reader_state.dart';
import '../state/reader_writer.dart';
import '../util/build_dirs.dart';
import '../util/constants.dart';
import 'build_directory.dart';
import 'build_phases.dart';
import 'build_result.dart';
import 'expected_outputs.dart';
import 'finalized_assets_view.dart';
import 'input_tracker.dart';
import 'options.dart';
import 'performance_tracker.dart';
import 'phase.dart';
import 'run_builder.dart';
import 'run_post_process_builder.dart';
import 'single_step_reader_writer.dart';

/// A single build.
class Build {
  // Configuration.
  final BuildEnvironment environment;
  final BuildOptions options;
  final BuildPhases buildPhases;
  final Set<BuildDirectory> buildDirs;
  final Set<BuildFilter> buildFilters;

  // Collaborators.
  final ResourceManager resourceManager;
  final AssetReaderWriter readerWriter;
  final RunnerAssetWriter deleteWriter;
  final LibraryCycleGraphLoader previousLibraryCycleGraphLoader =
      LibraryCycleGraphLoader();
  final AssetDepsLoader? previousDepsLoader;

  // Logging.
  final BuildPerformanceTracker performanceTracker;

  // State.
  final AssetGraph assetGraph;
  final lazyPhases = <String, Future<Iterable<AssetId>>>{};
  final lazyGlobs = <AssetId, Future<void>>{};

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
  final Set<AssetId> processedGlobs = {};

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

  /// Outputs for which errors have been shown.
  final Set<AssetId> errorsShownOutputs = {};

  /// Whether a graph from [previousLibraryCycleGraphLoader] has any changed
  /// transitive source.
  final Map<LibraryCycleGraph, bool> changedGraphs = Map.identity();

  Build({
    required this.environment,
    required this.options,
    required this.buildPhases,
    required this.buildDirs,
    required this.buildFilters,
    required this.readerWriter,
    required this.deleteWriter,
    required this.resourceManager,
    required this.assetGraph,
  }) : performanceTracker =
           options.trackPerformance
               ? BuildPerformanceTracker()
               : BuildPerformanceTracker.noOp(),
       previousDepsLoader =
           assetGraph.previousPhasedAssetDeps == null
               ? null
               : AssetDepsLoader.fromDeps(assetGraph.previousPhasedAssetDeps!);

  Future<BuildResult> run(Map<AssetId, ChangeType> updates) async {
    if (!assetGraph.cleanBuild) {
      buildLog.fullBuildBecause(FullBuildReason.none);
    }
    buildLog.configuration = buildLog.configuration.rebuild(
      (b) => b..rootPackageName = options.packageGraph.root.name,
    );
    var result = await _safeBuild(updates);
    var optionalOutputTracker = OptionalOutputTracker(
      assetGraph,
      options.targetGraph,
      BuildDirectory.buildPaths(buildDirs),
      buildFilters,
      buildPhases,
    );
    if (result.status == BuildStatus.success) {
      final failures = <AssetNode>[];
      for (final output in processedOutputs) {
        final node = assetGraph.get(output)!;
        if (node.type != NodeType.generated) continue;
        if (node.generatedNodeState!.result != false) continue;
        failures.add(node);
      }
      if (failures.isNotEmpty) {
        for (final failure in failures) {
          if (errorsShownOutputs.contains(failure.id)) continue;
          final phase =
              buildPhases.inBuildPhases[failure
                  .generatedNodeConfiguration!
                  .phaseNumber];
          final logger = buildLog.loggerFor(
            phase: phase,
            primaryInput: failure.generatedNodeConfiguration!.primaryInput,
            lazy: phase.isOptional,
          );
          for (final error in failure.generatedNodeState!.errors) {
            logger.severe(error);
          }
        }
        result = BuildResult(
          BuildStatus.failure,
          result.outputs,
          performance: result.performance,
        );
      }
    }
    readerWriter.cache.flush();
    await resourceManager.disposeAll();
    result = await environment.finalizeBuild(
      result,
      FinalizedAssetsView(
        assetGraph,
        options.packageGraph,
        optionalOutputTracker,
      ),
      readerWriter,
      buildDirs,
    );
    buildLog.finishBuild(
      result: result.status == BuildStatus.success,
      outputs: result.outputs.length,
    );
    return result;
  }

  Future<void> _updateAssetGraph(Map<AssetId, ChangeType> updates) async {
    changedInputs.clear();
    deletedAssets.clear();
    for (final update in updates.entries) {
      if (update.value == ChangeType.REMOVE) {
        deletedAssets.add(update.key);
      } else {
        changedInputs.add(update.key);
        if (update.value == ChangeType.ADD) {
          newPrimaryInputs.add(update.key);
        }
      }
    }
    readerWriter.cache.invalidate(changedInputs);
    final deleted = await assetGraph.updateAndInvalidate(
      buildPhases,
      updates,
      options.packageGraph.root.name,
      _delete,
      readerWriter,
    );
    deletedAssets.addAll(deleted);
  }

  /// Runs a build inside a zone with an error handler and stack chain
  /// capturing.
  Future<BuildResult> _safeBuild(Map<AssetId, ChangeType> updates) {
    final done = Completer<BuildResult>();
    runZonedGuarded(
      () async {
        buildLog.doing('Updating the asset graph.');
        if (!assetGraph.cleanBuild) {
          await _updateAssetGraph(updates);
        }

        buildLog.startBuild();
        var result = await _runPhases();
        buildLog.doing('Writing the asset graph.');

        // Combine previous phased asset deps, if any, with the newly loaded
        // deps. Because of skipped builds, the newly loaded deps might just
        // say "not generated yet", in which case the old value is retained.
        final updatedPhasedAssetDeps =
            assetGraph.previousPhasedAssetDeps == null
                ? AnalysisDriverModel.sharedInstance.phasedAssetDeps()
                : assetGraph.previousPhasedAssetDeps!.update(
                  AnalysisDriverModel.sharedInstance.phasedAssetDeps(),
                );
        assetGraph.previousPhasedAssetDeps = updatedPhasedAssetDeps;
        await readerWriter.writeAsBytes(
          AssetId(options.packageGraph.root.name, assetGraphPath),
          assetGraph.serialize(),
        );
        // Phases options don't change during a build series, so for all
        // subsequent builds "previous" and current build options digests
        // match.
        assetGraph.previousInBuildPhasesOptionsDigests =
            assetGraph.inBuildPhasesOptionsDigests;
        assetGraph.previousPostBuildActionsOptionsDigests =
            assetGraph.postBuildActionsOptionsDigests;

        // Log performance information if requested
        if (options.logPerformanceDir != null) {
          buildLog.doing('Writing the performance log.');
          assert(result.performance != null);
          var now = DateTime.now();
          var logPath = p.join(
            options.logPerformanceDir!,
            '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}'
            '_${_twoDigits(now.hour)}-${_twoDigits(now.minute)}-'
            '${_twoDigits(now.second)}',
          );
          buildLog.info('Writing performance log to $logPath');
          var performanceLogId = AssetId(
            options.packageGraph.root.name,
            logPath,
          );
          var serialized = jsonEncode(result.performance);
          await readerWriter.writeAsString(performanceLogId, serialized);
        }

        if (!done.isCompleted) done.complete(result);
      },
      (e, st) {
        if (!done.isCompleted) {
          buildLog.error(
            buildLog.renderThrowable('Unhandled build failure!', e, st),
          );
          done.complete(BuildResult(BuildStatus.failure, []));
        }
      },
    );

    return done.future;
  }

  /// Runs the actions in [buildPhases] and returns a future which completes
  /// to the [BuildResult] once all [BuildPhase]s are done.
  Future<BuildResult> _runPhases() {
    return performanceTracker.track(() async {
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
          primaryInputs.sort();
          primaryInputsByPhase[phase] = primaryInputs;
          primaryInputCountsByPhase[phase] = primaryInputs.length;
        }
      }

      buildLog.startPhases(primaryInputCountsByPhase);

      // Main build phases.
      for (
        var phaseNum = 0;
        phaseNum < buildPhases.inBuildPhases.length;
        phaseNum++
      ) {
        var phase = buildPhases.inBuildPhases[phaseNum];
        final primaryInputs = primaryInputsByPhase[phase];
        if (primaryInputs == null || primaryInputs.isEmpty) continue;

        outputs.addAll(
          await performanceTracker.trackBuildPhase(phase, () async {
            final outputs = <AssetId>[];
            for (var i = 0; i != primaryInputs.length; ++i) {
              final primaryInput = primaryInputs[i];
              outputs.addAll(
                await _buildForPrimaryInput(
                  phaseNumber: phaseNum,
                  phase: phase,
                  primaryInput: primaryInput,
                  lazy: false,
                ),
              );
            }
            return outputs;
          }),
        );
      }

      // Post build phase.
      buildLog.doing('Running the post build.');
      if (buildPhases.postBuildPhase.builderActions.isNotEmpty) {
        outputs.addAll(
          await performanceTracker.trackBuildPhase(
            buildPhases.postBuildPhase,
            () async {
              return _runPostBuildPhase(
                buildPhases.inBuildPhases.length,
                buildPhases.postBuildPhase,
              );
            },
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
        BuildStatus.success,
        outputs,
        performance: performanceTracker,
      );
    });
  }

  /// Returns primary inputs for [package] in [phaseNumber].
  Future<List<AssetId>> _matchingPrimaryInputs(
    String package,
    int phaseNumber,
  ) async {
    var ids = <AssetId>[];
    var phase = buildPhases[phaseNumber];
    var packageNode = options.packageGraph[package]!;

    for (final node in assetGraph
        .outputsForPhase(package, phaseNumber)
        .toList(growable: false)) {
      if (!shouldBuildForDirs(
        node.id,
        buildDirs: BuildDirectory.buildPaths(buildDirs),
        buildFilters: buildFilters,
        phase: phase,
        targetGraph: options.targetGraph,
      )) {
        continue;
      }

      // Don't build for inputs that aren't visible. This can happen for
      // placeholder nodes like `test/$test$` that are added to each package,
      // since the test dir is not part of the build for non-root packages.
      if (!options.targetGraph.isVisibleInBuild(node.id, packageNode)) continue;

      ids.add(node.generatedNodeConfiguration!.primaryInput);
    }
    return ids;
  }

  /// If [id] is a generated asset, ensures that it has been built.
  ///
  /// If has already been built according to [processedOutputs], returns
  /// immediately.
  ///
  /// If it is currently being built according to [lazyPhases], waits for it to
  /// be built.
  Future<void> _buildOutput(AssetId id) async {
    final node = assetGraph.get(id)!;
    if (node.type == NodeType.generated && !processedOutputs.contains(id)) {
      final nodeConfiguration = node.generatedNodeConfiguration!;
      final phaseNumber = nodeConfiguration.phaseNumber;
      final primaryInput = node.generatedNodeConfiguration!.primaryInput;
      await lazyPhases.putIfAbsent('$phaseNumber|$primaryInput', () async {
        final phase = buildPhases.inBuildPhases[nodeConfiguration.phaseNumber];
        return _buildForPrimaryInput(
          primaryInput: primaryInput,
          phaseNumber: phaseNumber,
          phase: phase,
          lazy: true,
        );
      });
    }
  }

  /// Runs the builder for [primaryInput] at [phase].
  ///
  /// If outputs are already valid or are optional and not used, does nothing.
  ///
  /// Returns the files written.
  Future<Iterable<AssetId>> _buildForPrimaryInput({
    required AssetId primaryInput,
    required int phaseNumber,
    required InBuildPhase phase,
    required bool lazy,
  }) async {
    buildLog.startStep(phase: phase, primaryInput: primaryInput, lazy: lazy);
    final builder = phase.builder;
    var tracker = performanceTracker.addBuilderAction(
      primaryInput,
      phase.builderLabel,
    );
    return tracker.track(() async {
      final readerWriter = SingleStepReaderWriter(
        runningBuild: RunningBuild(
          packageGraph: options.packageGraph,
          targetGraph: options.targetGraph,
          assetGraph: assetGraph,
          nodeBuilder: _buildOutput,
          assetIsProcessedOutput: processedOutputs.contains,
          globNodeBuilder: _buildGlobNode,
        ),
        runningBuildStep: RunningBuildStep(
          phaseNumber: phaseNumber,

          buildPhase: phase,
          primaryPackage: primaryInput.package,
        ),
        readerWriter: this.readerWriter,
        inputTracker: InputTracker(this.readerWriter.filesystem),
        assetsWritten: {},
      );

      final builderOutputs = expectedOutputs(builder, primaryInput);
      if (!await tracker.trackStage(
        'Setup',
        () => _buildShouldRun(
          phaseNumber,
          primaryInput,
          builderOutputs,
          readerWriter,
        ),
      )) {
        buildLog.skipStep(phase: phase, lazy: lazy);
        return <AssetId>[];
      }

      await _cleanUpStaleOutputs(builderOutputs);

      // Clear input tracking accumulated during `_buildShouldRun`.
      readerWriter.inputTracker.clear();

      final unusedAssets = <AssetId>{};
      void reportUnusedAssetsForInput(AssetId input, Iterable<AssetId> assets) {
        options.reportUnusedAssetsForInput?.call(input, assets);
        unusedAssets.addAll(assets);
      }

      final logger = buildLog.loggerFor(
        phase: phase,
        primaryInput: primaryInput,
        lazy: lazy,
      );
      await TimedActivity.build.runAsync(
        () => tracker.trackStage(
          'Build',
          () => runBuilder(
            builder,
            [primaryInput],
            readerWriter,
            readerWriter,
            PerformanceTrackingResolvers(options.resolvers, tracker),
            logger: logger,
            resourceManager: resourceManager,
            stageTracker: tracker,
            reportUnusedAssetsForInput: reportUnusedAssetsForInput,
            packageConfig: options.packageGraph.asPackageConfig,
          ).catchError((void _) {
            // Errors tracked through the logger.
          }),
        ),
      );

      // Update the state for all the `builderOutputs` nodes based on what was
      // read and written.
      await TimedActivity.track.runAsync(
        () => tracker.trackStage(
          'Finalize',
          () => _setOutputsState(
            primaryInput,
            builderOutputs,
            readerWriter,
            readerWriter.inputTracker,
            logger.errors,
            unusedAssets: unusedAssets,
          ),
        ),
      );

      buildLog.finishStep(
        phase: phase,
        anyOutputs: readerWriter.assetsWritten.isNotEmpty,
        anyChangedOutputs: readerWriter.assetsWritten.any(
          changedOutputs.contains,
        ),
        lazy: lazy,
      );

      return readerWriter.assetsWritten;
    });
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
          await _runPostProcessBuildStep(phaseNum, action.builder, buildStepId),
        );
      }
    }
    return outputs;
  }

  Future<Iterable<AssetId>> _runPostProcessBuildStep(
    int phaseNumber,
    PostProcessBuilder builder,
    PostProcessBuildStepId postProcessBuildStepId,
  ) async {
    var input = postProcessBuildStepId.input;
    var inputNode = assetGraph.get(input)!;
    var readerWriter = SingleStepReaderWriter(
      runningBuild: RunningBuild(
        packageGraph: options.packageGraph,
        targetGraph: options.targetGraph,
        assetGraph: assetGraph,
        nodeBuilder: _buildOutput,
        assetIsProcessedOutput: processedOutputs.contains,
        globNodeBuilder: _buildGlobNode,
      ),
      runningBuildStep: RunningBuildStep(
        phaseNumber: phaseNumber,
        buildPhase: buildPhases.postBuildPhase,
        primaryPackage: input.package,
      ),
      readerWriter: this.readerWriter,
      inputTracker: InputTracker(this.readerWriter.filesystem),
      assetsWritten: {},
    );

    if (!await _postProcessBuildStepShouldRun(
      postProcessBuildStepId,
      readerWriter,
    )) {
      return <AssetId>[];
    }
    // Clear input tracking accumulated during `_buildShouldRun`.
    readerWriter.inputTracker.clear();

    // Clean out the impacts of the previous run.
    final existingOutputs = assetGraph.postProcessBuildStepOutputs(
      postProcessBuildStepId,
    );
    await _cleanUpStaleOutputs(existingOutputs);
    for (final output in existingOutputs) {
      assetGraph.removePostProcessOutput(output);
    }
    assetGraph.updateNode(inputNode.id, (nodeBuilder) {
      nodeBuilder.deletedBy.remove(postProcessBuildStepId);
    });

    final logger = buildLog.loggerForOther(buildLog.renderId(input));
    final outputs = <AssetId>{};
    await runPostProcessBuilder(
      builder,
      input,
      readerWriter,
      readerWriter,
      logger,
      addAsset: (assetId) {
        if (assetGraph.contains(assetId)) {
          throw InvalidOutputException(assetId, 'Asset already exists');
        }
        var node = AssetNode.generated(
          assetId,
          primaryInput: input,
          isHidden: true,
          phaseNumber: phaseNumber,
        );
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
        assetGraph.updateNode(assetId, (nodeBuilder) {
          nodeBuilder.deletedBy.add(postProcessBuildStepId);
        });
      },
    ).catchError((void _) {
      // Errors tracked through the logger
    });

    assetGraph.updatePostProcessBuildStep(
      postProcessBuildStepId,
      outputs: outputs,
    );

    var assetsWritten = readerWriter.assetsWritten.toSet();

    // Reset the state for all the output nodes based on what was read and
    // written.
    assetGraph.updateNode(inputNode.id, (nodeBuilder) {
      nodeBuilder.primaryOutputs.addAll(assetsWritten);
    });

    await _setOutputsState(
      input,
      assetsWritten,
      readerWriter,
      readerWriter.inputTracker,
      logger.errors,
    );

    return assetsWritten;
  }

  /// Marks [outputs] as not output and not built.
  void _markOutputsSkipped(Iterable<AssetId> outputs) {
    for (final output in outputs) {
      assetGraph.updateNode(output, (nodeBuilder) {
        // TODO(davidmorgan): deleting the file here may be the fix for
        // https://github.com/dart-lang/build/issues/3875.
        nodeBuilder.digest = null;
        nodeBuilder.generatedNodeState.result = null;
      });
      processedOutputs.add(output);
    }
  }

  /// Marks [outputs] as not output and failed.
  Future<void> _markOutputsTransitivelyFailed(Iterable<AssetId> outputs) async {
    for (final output in outputs) {
      assetGraph.updateNode(output, (nodeBuilder) {
        // TODO(davidmorgan): deleting the file here may be the fix for
        // https://github.com/dart-lang/build/issues/3875.
        nodeBuilder.digest = null;
        nodeBuilder.generatedNodeState.result = false;
        nodeBuilder.generatedNodeState.errors.clear();
      });
      processedOutputs.add(output);
    }
  }

  /// Checks and returns whether any [outputs] need to be updated in
  /// [phaseNumber] for [primaryInput].
  ///
  /// As part of checking, builds any inputs that need building.
  Future<bool> _buildShouldRun(
    int phaseNumber,
    AssetId primaryInput,
    Iterable<AssetId> outputs,
    AssetReader reader,
  ) async {
    return await TimedActivity.track.runAsync(() async {
      // Update state for primary input if needed.
      var primaryInputNode = assetGraph.get(primaryInput)!;
      if (primaryInputNode.type == NodeType.generated) {
        if (!processedOutputs.contains(primaryInput)) {
          await _buildOutput(primaryInput);
          primaryInputNode = assetGraph.get(primaryInput)!;
        }
      }

      // If the primary input has been deleted, the build is skipped.
      if (deletedAssets.contains(primaryInput)) {
        if (primaryInputNode.type == NodeType.missingSource) {
          _markOutputsSkipped(outputs);
          return false;
        }
      }

      // Propagate results for generated node inputs.
      if (primaryInputNode.type == NodeType.generated) {
        // If the primary input is failed, this build is also failed.
        if (primaryInputNode.generatedNodeState!.result == false) {
          await _markOutputsTransitivelyFailed(outputs);
          return false;
        }

        // If the primary input succeeded but was not output, this build is
        // skipped.
        if (!primaryInputNode.wasOutput) {
          _markOutputsSkipped(outputs);
          return false;
        }
      }

      if (assetGraph.cleanBuild) return true;

      if (assetGraph.previousInBuildPhasesOptionsDigests![phaseNumber] !=
          assetGraph.inBuildPhasesOptionsDigests[phaseNumber]) {
        return true;
      }

      if (newPrimaryInputs.contains(primaryInput)) return true;

      for (var output in outputs) {
        if (deletedAssets.contains(output)) return true;
      }

      // Build results are the same across outputs, so just check the first
      // output.
      var firstOutput = assetGraph.get(outputs.first)!;
      final firstOutputState = firstOutput.generatedNodeState!;

      if (firstOutputState.result == null) return true;

      // Check for changes to any inputs.
      final inputs = firstOutputState.inputs;
      for (final input in inputs) {
        final changed = await _hasInputChanged(
          phaseNumber: phaseNumber,
          input: input,
        );

        if (changed) return true;
      }

      for (final graphId in firstOutputState.resolverEntrypoints) {
        if (await _hasInputGraphChanged(
          phaseNumber: phaseNumber,
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
    final inputNode = assetGraph.get(input)!;
    if (inputNode.type == NodeType.generated) {
      if (inputNode.generatedNodeConfiguration!.phaseNumber >= phaseNumber) {
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
    } else if (inputNode.type == NodeType.glob) {
      // Ensure that the glob was evaluated, so [changedOutputs] is updated.
      if (!processedGlobs.contains(input)) {
        await _buildGlobNode(input);
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
    AssetReader reader,
  ) async {
    final input = buildStepId.input;
    final node = assetGraph.get(input)!;

    if (assetGraph.cleanBuild) {
      return true;
    }

    if (assetGraph.previousPostBuildActionsOptionsDigests![buildStepId
            .actionNumber] !=
        assetGraph.postBuildActionsOptionsDigests[buildStepId.actionNumber]) {
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
      final node = assetGraph.get(output)!;
      if (node.type == NodeType.generated && node.wasOutput) {
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
  Future<void> _buildGlobNode(AssetId globId) async {
    if (processedGlobs.contains(globId)) {
      return;
    }

    return lazyGlobs.putIfAbsent(globId, () async {
      final globNodeConfiguration =
          assetGraph.get(globId)!.globNodeConfiguration!;
      final glob = Glob(globNodeConfiguration.glob);

      // Generated files that match the glob.
      final generatedFileInputs = <AssetId>[];
      // Other types of file that match the glob.
      final otherInputs = <AssetId>[];

      for (final node in assetGraph.packageNodes(globId.package)) {
        if (node.isFile &&
            node.isTrackedInput &&
            // Generated nodes are only considered at all if they are output in
            // an earlier phase.
            (node.type != NodeType.generated ||
                node.generatedNodeConfiguration!.phaseNumber <
                    globNodeConfiguration.phaseNumber) &&
            glob.matches(node.id.path)) {
          if (node.type == NodeType.generated) {
            generatedFileInputs.add(node.id);
          } else {
            otherInputs.add(node.id);
          }
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
        final node = assetGraph.get(id)!;
        if (node.wasOutput && node.generatedNodeState!.result == true) {
          generatedFileResults.add(id);
        }
      }

      final results = [...otherInputs, ...generatedFileResults];
      final digest = md5.convert(utf8.encode(results.join(' ')));
      assetGraph.updateNode(globId, (nodeBuilder) {
        if (nodeBuilder.digest != digest) {
          changedOutputs.add(globId);
        }
        processedGlobs.add(globId);
        nodeBuilder
          ..globNodeState.results.replace(results)
          ..globNodeState.inputs.replace(
            generatedFileInputs.followedBy(otherInputs),
          )
          ..digest = digest;
      });

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
    SingleStepReaderWriter readerWriter,
    InputTracker inputTracker,
    Iterable<String> errors, {
    Set<AssetId>? unusedAssets,
  }) async {
    if (outputs.isEmpty) return;
    var usedInputs =
        unusedAssets != null && unusedAssets.isNotEmpty
            ? inputTracker.inputs.difference(unusedAssets)
            : inputTracker.inputs;

    final result = errors.isEmpty;

    for (final output in outputs) {
      final wasOutput = readerWriter.assetsWritten.contains(output);
      final digest = wasOutput ? await this.readerWriter.digest(output) : null;
      var outputNode = assetGraph.get(output)!;

      // A transition from (missing or failed) to (written and not failed) is
      // a new primary input that triggers generation even if no content
      // changed.
      if ((outputNode.digest == null ||
              outputNode.generatedNodeState!.result == false) &&
          (digest != null && result)) {
        newPrimaryInputs.add(output);
      }
      // Only a change to content matters for non-primary inputs.
      if (outputNode.digest != digest) {
        changedOutputs.add(output);
      }

      outputNode = assetGraph.updateNode(output, (nodeBuilder) {
        nodeBuilder.generatedNodeState
          ..inputs.replace(usedInputs)
          ..resolverEntrypoints.replace(inputTracker.resolverEntrypoints)
          ..result = result
          ..errors.replace(errors);
        nodeBuilder.digest = digest;
      });

      processedOutputs.add(output);
      if (result == false) {
        errorsShownOutputs.add(output);
      }
    }
  }

  Future _delete(AssetId id) => deleteWriter.delete(id);
}

String _twoDigits(int n) => '$n'.padLeft(2, '0');
