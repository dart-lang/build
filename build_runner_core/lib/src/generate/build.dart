// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
// ignore: implementation_imports
import 'package:build_resolvers/src/internal.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../asset_graph/optional_output_tracker.dart';
import '../asset_graph/post_process_build_step_id.dart';
import '../changes/asset_updates.dart';
import '../environment/build_environment.dart';
import '../logging/build_for_input_logger.dart';
import '../logging/failure_reporter.dart';
import '../logging/human_readable_duration.dart';
import '../logging/log_renderer.dart';
import '../logging/logging.dart';
import '../performance_tracking/performance_tracking_resolvers.dart';
import '../util/build_dirs.dart';
import '../util/constants.dart';
import 'build_directory.dart';
import 'build_phases.dart';
import 'build_result.dart';
import 'finalized_assets_view.dart';
import 'heartbeat.dart';
import 'input_tracker.dart';
import 'options.dart';
import 'performance_tracker.dart';
import 'phase.dart';
import 'single_step_reader_writer.dart';

final _logger = Logger('Build');

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
  final LogRenderer renderer;
  final BuildPerformanceTracker performanceTracker;
  late final HungActionsHeartbeat hungActionsHeartbeat;
  final bool logFine;

  // State.
  final AssetGraph assetGraph;
  final lazyPhases = <String, Future<Iterable<AssetId>>>{};
  final lazyGlobs = <AssetId, Future<void>>{};
  final failureReporter = FailureReporter();
  int actionsCompletedCount = 0;
  int actionsStartedCount = 0;
  final pendingActions = SplayTreeMap<int, Set<String>>();

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
  }) : renderer = LogRenderer(rootPackageName: options.packageGraph.root.name),
       performanceTracker =
           options.trackPerformance
               ? BuildPerformanceTracker()
               : BuildPerformanceTracker.noOp(),
       logFine = _logger.level <= Level.FINE,
       previousDepsLoader =
           assetGraph.previousPhasedAssetDeps == null
               ? null
               : AssetDepsLoader.fromDeps(assetGraph.previousPhasedAssetDeps!) {
    hungActionsHeartbeat = HungActionsHeartbeat(() {
      final message = StringBuffer();
      const actionsToLogMax = 5;
      final descriptions = pendingActions.values
          .expand((actions) => actions)
          .take(actionsToLogMax);
      for (final description in descriptions) {
        message.writeln('  - $description');
      }
      var additionalActionsCount =
          actionsStartedCount - actionsCompletedCount - actionsToLogMax;
      if (additionalActionsCount > 0) {
        message.writeln('  .. and $additionalActionsCount more');
      }
      return '$message';
    });
  }

  Future<BuildResult> run(Map<AssetId, ChangeType> updates) async {
    if (logFine) {
      _logger.fine(AssetUpdates.from(updates).render(renderer));
    }
    var watch = Stopwatch()..start();
    var result = await _safeBuild(updates);
    var optionalOutputTracker = OptionalOutputTracker(
      assetGraph,
      options.targetGraph,
      BuildDirectory.buildPaths(buildDirs),
      buildFilters,
      buildPhases,
    );
    if (result.status == BuildStatus.success) {
      final failures = processedOutputs
          .map((id) => assetGraph.get(id)!)
          .where((node) => node.type == NodeType.generated)
          .where((node) => node.generatedNodeState!.result == false);
      if (failures.isNotEmpty) {
        await failureReporter.reportErrors(failures);
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
    if (result.status == BuildStatus.success) {
      _logger.info(
        'Succeeded after ${humanReadable(watch.elapsed)} with '
        '${result.outputs.length} outputs '
        '($actionsCompletedCount actions)\n',
      );
    } else {
      _logger.severe('Failed after ${humanReadable(watch.elapsed)}');
    }
    return result;
  }

  Future<void> _updateAssetGraph(Map<AssetId, ChangeType> updates) async {
    await logTimedAsync(_logger, 'Updating asset graph', () async {
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
    });
  }

  /// Runs a build inside a zone with an error handler and stack chain
  /// capturing.
  Future<BuildResult> _safeBuild(Map<AssetId, ChangeType> updates) {
    var done = Completer<BuildResult>();
    var heartbeat = HeartbeatLogger(
      transformLog: (original) => '$original, ${_buildProgress()}',
      waitDuration: const Duration(seconds: 1),
    )..start();
    hungActionsHeartbeat.start();
    done.future.whenComplete(() {
      heartbeat.stop();
      hungActionsHeartbeat.stop();
    });

    runZonedGuarded(
      () async {
        if (!assetGraph.cleanBuild) {
          await _updateAssetGraph(updates);
        }

        // Run a fresh build.
        var result = await logTimedAsync(_logger, 'Running build', _runPhases);

        // Write out the dependency graph file.
        await logTimedAsync(
          _logger,
          'Caching finalized dependency graph',
          () async {
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
          },
        );

        // Log performance information if requested
        if (options.logPerformanceDir != null) {
          assert(result.performance != null);
          var now = DateTime.now();
          var logPath = p.join(
            options.logPerformanceDir!,
            '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}'
            '_${_twoDigits(now.hour)}-${_twoDigits(now.minute)}-'
            '${_twoDigits(now.second)}',
          );
          await logTimedAsync(
            _logger,
            'Writing performance log to $logPath',
            () {
              var performanceLogId = AssetId(
                options.packageGraph.root.name,
                logPath,
              );
              var serialized = jsonEncode(result.performance);
              return readerWriter.writeAsString(performanceLogId, serialized);
            },
          );
        }

        if (!done.isCompleted) done.complete(result);
      },
      (e, st) {
        if (!done.isCompleted) {
          _logger.severe('Unhandled build failure!', e, st);
          done.complete(BuildResult(BuildStatus.failure, []));
        }
      },
    );
    return done.future;
  }

  /// Returns a message describing the progress of the current build.
  String _buildProgress() =>
      '$actionsCompletedCount/$actionsStartedCount actions completed.';

  /// Runs the actions in [buildPhases] and returns a future which completes
  /// to the [BuildResult] once all [BuildPhase]s are done.
  Future<BuildResult> _runPhases() {
    return performanceTracker.track(() async {
      final outputs = <AssetId>[];

      // Main build phases.
      for (
        var phaseNum = 0;
        phaseNum < buildPhases.inBuildPhases.length;
        phaseNum++
      ) {
        var phase = buildPhases.inBuildPhases[phaseNum];
        if (phase.isOptional) continue;
        outputs.addAll(
          await performanceTracker.trackBuildPhase(phase, () async {
            var primaryInputs = await _matchingPrimaryInputs(
              phase.package,
              phaseNum,
            );
            final outputs = <AssetId>[];
            for (final primaryInput in primaryInputs) {
              outputs.addAll(
                await _buildForPrimaryInput(
                  phaseNumber: phaseNum,
                  phase: phase,
                  primaryInput: primaryInput,
                ),
              );
            }
            return outputs;
          }),
        );
      }

      // Post build phase.
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
  Future<Set<AssetId>> _matchingPrimaryInputs(
    String package,
    int phaseNumber,
  ) async {
    var ids = <AssetId>{};
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
        return _buildForPrimaryInput(
          primaryInput: primaryInput,
          phaseNumber: phaseNumber,
          phase: buildPhases.inBuildPhases[nodeConfiguration.phaseNumber],
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
  }) async {
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
        return <AssetId>[];
      }

      await _cleanUpStaleOutputs(builderOutputs);
      await FailureReporter.clean(phaseNumber, primaryInput);

      // Clear input tracking accumulated during `_buildShouldRun`.
      readerWriter.inputTracker.clear();

      final actionDescription = _actionLoggerName(
        phase,
        primaryInput,
        options.packageGraph.root.name,
      );
      final logger = BuildForInputLogger(Logger(actionDescription));

      actionsStartedCount++;
      pendingActions
          .putIfAbsent(phaseNumber, () => <String>{})
          .add(actionDescription);

      final unusedAssets = <AssetId>{};
      void reportUnusedAssetsForInput(AssetId input, Iterable<AssetId> assets) {
        options.reportUnusedAssetsForInput?.call(input, assets);
        unusedAssets.addAll(assets);
      }

      await tracker.trackStage(
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
      );
      actionsCompletedCount++;
      hungActionsHeartbeat.ping();
      pendingActions[phaseNumber]!.remove(actionDescription);

      // Update the state for all the `builderOutputs` nodes based on what was
      // read and written.
      await tracker.trackStage(
        'Finalize',
        () => _setOutputsState(
          primaryInput,
          builderOutputs,
          readerWriter,
          readerWriter.inputTracker,
          actionDescription,
          logger.errorsSeen,
          unusedAssets: unusedAssets,
        ),
      );

      return readerWriter.assetsWritten;
    });
  }

  Future<Iterable<AssetId>> _runPostBuildPhase(
    int phaseNum,
    PostBuildPhase phase,
  ) async {
    var actionNum = 0;
    var outputLists = await Future.wait(
      phase.builderActions.map(
        (action) => _runPostBuildAction(phaseNum, actionNum++, action),
      ),
    );
    return outputLists.fold<List<AssetId>>(
      <AssetId>[],
      (combined, next) => combined..addAll(next),
    );
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
    await FailureReporter.clean(phaseNumber, input);
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

    var actionDescription = '$builder on $input';
    var logger = BuildForInputLogger(Logger(actionDescription));

    actionsStartedCount++;
    pendingActions
        .putIfAbsent(phaseNumber, () => <String>{})
        .add(actionDescription);

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

    actionsCompletedCount++;
    hungActionsHeartbeat.ping();
    pendingActions[phaseNumber]!.remove(actionDescription);

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
      actionDescription,
      logger.errorsSeen,
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
      });
      processedOutputs.add(output);
    }
    await failureReporter.markSkipped(outputs.map((id) => assetGraph.get(id)!));
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
        if (logFine) {
          _logger.fine(
            'Skip ${renderer.build(primaryInput, outputs)} because '
            '$primaryInput was deleted.',
          );
        }
        _markOutputsSkipped(outputs);
        return false;
      }
    }

    // Propagate results for generated node inputs.
    if (primaryInputNode.type == NodeType.generated) {
      // If the primary input is failed, this build is also failed.
      if (primaryInputNode.generatedNodeState!.result == false) {
        if (logFine) {
          _logger.fine(
            'Skip ${renderer.build(primaryInput, outputs)} because '
            '$primaryInput is a generated file that failed.',
          );
        }
        await _markOutputsTransitivelyFailed(outputs);
        return false;
      }

      // If the primary input succeeded but was not output, this build is
      // skipped.
      if (!primaryInputNode.wasOutput) {
        if (logFine) {
          _logger.fine(
            'Skip ${renderer.build(primaryInput, outputs)} because '
            '$primaryInput is a generated file that was not output.',
          );
        }
        _markOutputsSkipped(outputs);
        return false;
      }
    }

    if (assetGraph.cleanBuild) {
      if (logFine) {
        _logger.fine(
          'Build ${renderer.build(primaryInput, outputs)} because this is a '
          'clean build.',
        );
      }
      return true;
    }

    if (assetGraph.previousInBuildPhasesOptionsDigests![phaseNumber] !=
        assetGraph.inBuildPhasesOptionsDigests[phaseNumber]) {
      if (logFine) {
        _logger.fine(
          'Build ${renderer.build(primaryInput, outputs)} because builder '
          'options changed.',
        );
      }
      return true;
    }

    if (newPrimaryInputs.contains(primaryInput)) {
      if (logFine) {
        _logger.fine(
          'Build ${renderer.build(primaryInput, outputs)} because '
          '$primaryInput was created.',
        );
      }
      return true;
    }

    for (var output in outputs) {
      if (deletedAssets.contains(output)) {
        if (logFine) {
          _logger.fine(
            'Build ${renderer.build(primaryInput, outputs)} because '
            '${renderer.id(output)} was deleted.',
          );
        }
        return true;
      }
    }

    // Build results are the same across outputs, so just check the first
    // output.
    var firstOutput = assetGraph.get(outputs.first)!;
    final firstOutputState = firstOutput.generatedNodeState!;

    if (firstOutputState.result == null) {
      if (logFine) {
        _logger.fine(
          'Build ${renderer.build(primaryInput, outputs)} because it was '
          'skipped as optional but is now needed.',
        );
      }
      return true;
    }

    // Check for changes to any inputs.
    final inputs = firstOutputState.inputs;
    for (final input in inputs) {
      final changed = await _hasInputChanged(
        phaseNumber: phaseNumber,
        input: input,
      );

      if (changed) {
        if (logFine) {
          final inputNode = assetGraph.get(input)!;
          switch (inputNode.type) {
            case NodeType.generated:
              _logger.fine(
                'Build ${renderer.build(primaryInput, outputs)} because '
                '${renderer.id(input)} was built and changed.',
              );

            case NodeType.glob:
              _logger.fine(
                'Build ${renderer.build(primaryInput, outputs)} because '
                '${inputNode.globNodeConfiguration!.glob} matches changed.',
              );

            case NodeType.source:
              _logger.fine(
                'Build ${renderer.build(primaryInput, outputs)} because '
                '${renderer.id(input)} changed.',
              );

            case NodeType.missingSource:
              _logger.fine(
                'Build ${renderer.build(primaryInput, outputs)} because '
                '${renderer.id(input)} was deleted.',
              );

            default:
              throw StateError(inputNode.type.toString());
          }
        }
        return true;
      }
    }

    for (final graphId in firstOutputState.resolverEntrypoints) {
      if (await _hasInputGraphChanged(
        phaseNumber: phaseNumber,
        entrypointId: graphId,
      )) {
        if (logFine) {
          _logger.fine(
            'Build ${renderer.build(primaryInput, outputs)} because '
            'resolved source changed.',
          );
        }
        return true;
      }
    }

    // No input changes: build is not needed, and outputs state is up to date.
    for (final output in outputs) {
      processedOutputs.add(output);
    }

    return false;
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
      if (!processedOutputs.contains(input)) {
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
  /// - Storing the error message with the [failureReporter].
  /// - Updating `newPrimaryInputs` and `changedOutputs` as needed.
  Future<void> _setOutputsState(
    AssetId input,
    Iterable<AssetId> outputs,
    SingleStepReaderWriter readerWriter,
    InputTracker inputTracker,
    String actionDescription,
    Iterable<ErrorReport> errors, {
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
          ..result = result;
        nodeBuilder.digest = digest;
      });

      if (!result) {
        // Mark this output as failed. Transitive outputs will be marked as
        // failed when they are processed and notice their primary inputs
        // have failed.
        await failureReporter.markReported(
          actionDescription,
          outputNode,
          errors,
        );
      }

      processedOutputs.add(output);
    }
  }

  Future _delete(AssetId id) => deleteWriter.delete(id);
}

String _actionLoggerName(
  InBuildPhase phase,
  AssetId primaryInput,
  String rootPackageName,
) {
  var asset =
      primaryInput.package == rootPackageName
          ? primaryInput.path
          : primaryInput.uri.toString();

  // In the rare case that the assets ends with a dot, remove it to ensure that
  // the logger name is valid.
  while (asset.endsWith('.')) {
    asset = asset.substring(0, asset.length - 1);
  }

  return '${phase.builderLabel} on $asset';
}

String _twoDigits(int n) => '$n'.padLeft(2, '0');
