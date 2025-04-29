// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
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

  /// Inputs that changed since the last build.
  ///
  /// Filled from the `updates` passed in to the build.
  final Set<AssetId> changedInputs = {};

  /// Outputs that changed since the last build.
  ///
  /// Filled during the build as each output is produced and its digest is
  /// checked against the digest from the previous build.
  final Set<AssetId> changedOutputs = {};

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
       logFine = _logger.level <= Level.FINE {
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
      final failures = assetGraph.failedOutputs.where(
        (n) => optionalOutputTracker.isRequired(n.id),
      );
      if (failures.isNotEmpty) {
        await failureReporter.reportErrors(failures);
        result = BuildResult(
          BuildStatus.failure,
          result.outputs,
          performance: result.performance,
        );
      }
    }
    await environment.writer.completeBuild();
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
      changedInputs.addAll(updates.keys.toSet());
      var invalidated = await assetGraph.updateAndInvalidate(
        buildPhases,
        updates,
        options.packageGraph.root.name,
        _delete,
        readerWriter,
      );
      await readerWriter.cache.invalidate(invalidated);
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
            return _runBuilder(phaseNum, phase, primaryInputs);
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

  /// Gets a list of all inputs matching the [phaseNumber], as well as
  /// its [Builder]s primary inputs.
  ///
  /// Lazily builds any optional build actions that might potentially produce
  /// a primary input to this phase.
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

      var input =
          assetGraph.get(node.generatedNodeConfiguration!.primaryInput)!;
      if (input.type == NodeType.generated) {
        var inputState = input.generatedNodeState!;
        if (inputState.pendingBuildAction != PendingBuildAction.none) {
          final inputConfiguration = input.generatedNodeConfiguration!;
          await _runLazyPhaseForInput(
            inputConfiguration.phaseNumber,
            inputConfiguration.primaryInput,
          );
        }
        // Read the result of the build.
        inputState = assetGraph.get(input.id)!.generatedNodeState!;
        if (!inputState.wasOutput) continue;
        if (inputState.isFailure) continue;
      }
      ids.add(input.id);
    }
    return ids;
  }

  /// Runs a normal builder with [primaryInputs] as inputs and returns only the
  /// outputs that were newly created.
  ///
  /// Does not return outputs that didn't need to be re-ran or were declared
  /// but not output.
  Future<Iterable<AssetId>> _runBuilder(
    int phaseNumber,
    InBuildPhase action,
    Iterable<AssetId> primaryInputs,
  ) async {
    final outputs = <AssetId>[];
    for (final input in primaryInputs) {
      outputs.addAll(await _runForInput(phaseNumber, action, input));
    }
    return outputs;
  }

  /// Lazily runs [phaseNumber] with [input]..
  Future<Iterable<AssetId>> _runLazyPhaseForInput(
    int phaseNumber,
    AssetId input,
  ) {
    return lazyPhases.putIfAbsent('$phaseNumber|$input', () async {
      // First check if `input` is generated, and whether or not it was
      // actually output. If it wasn't then we just return an empty list here.
      var inputNode = assetGraph.get(input)!;
      if (inputNode.type == NodeType.generated) {
        var nodeState = inputNode.generatedNodeState!;
        // Make sure the `inputNode` is up to date, and rebuild it if not.
        if (nodeState.pendingBuildAction != PendingBuildAction.none) {
          final nodeConfiguration = inputNode.generatedNodeConfiguration!;
          await _runLazyPhaseForInput(
            nodeConfiguration.phaseNumber,
            nodeConfiguration.primaryInput,
          );
        }
        // Read the result of the build.
        nodeState = assetGraph.get(inputNode.id)!.generatedNodeState!;
        if (!nodeState.wasOutput || nodeState.isFailure) return <AssetId>[];
      }

      return _runForInput(
        phaseNumber,
        buildPhases.inBuildPhases[phaseNumber],
        input,
      );
    });
  }

  Future<void> _buildAsset(AssetId id) async {
    final node = assetGraph.get(id)!;
    if (node.type == NodeType.generated &&
        node.generatedNodeState!.pendingBuildAction !=
            PendingBuildAction.none) {
      final nodeConfiguration = node.generatedNodeConfiguration!;
      await _runLazyPhaseForInput(
        nodeConfiguration.phaseNumber,
        nodeConfiguration.primaryInput,
      );
    }
  }

  Future<Iterable<AssetId>> _runForInput(
    int phaseNumber,
    InBuildPhase phase,
    AssetId input,
  ) async {
    final builder = phase.builder;
    var tracker = performanceTracker.addBuilderAction(
      input,
      phase.builderLabel,
    );
    return tracker.track(() async {
      var builderOutputs = expectedOutputs(builder, input);

      // Add `builderOutputs` to the primary outputs of the input.
      var inputNode = assetGraph.get(input)!;
      assert(
        inputNode.primaryOutputs.containsAll(builderOutputs),
        // ignore: prefer_interpolation_to_compose_strings
        'input $input with builder $builder missing primary outputs: \n'
                'Got ${inputNode.primaryOutputs.join(', ')} '
                'which was missing:\n' +
            builderOutputs
                .where((id) => !inputNode.primaryOutputs.contains(id))
                .join(', '),
      );

      var readerWriter = SingleStepReaderWriter(
        runningBuild: RunningBuild(
          packageGraph: options.packageGraph,
          targetGraph: options.targetGraph,
          assetGraph: assetGraph,
          nodeBuilder: _buildAsset,
          globNodeBuilder: _buildGlobNode,
        ),
        runningBuildStep: RunningBuildStep(
          phaseNumber: phaseNumber,

          buildPhase: phase,
          primaryPackage: input.package,
        ),
        readerWriter: this.readerWriter,
        inputTracker: InputTracker(this.readerWriter.filesystem),
        assetsWritten: {},
      );

      if (!await tracker.trackStage(
        'Setup',
        () => _buildShouldRun(phaseNumber, input, builderOutputs, readerWriter),
      )) {
        return <AssetId>[];
      }

      await _cleanUpStaleOutputs(builderOutputs);
      await FailureReporter.clean(phaseNumber, input);

      // Clear input tracking accumulated during `_buildShouldRun`.
      readerWriter.inputTracker.clear();

      var actionDescription = _actionLoggerName(
        phase,
        input,
        options.packageGraph.root.name,
      );
      var logger = BuildForInputLogger(Logger(actionDescription));

      actionsStartedCount++;
      pendingActions
          .putIfAbsent(phaseNumber, () => <String>{})
          .add(actionDescription);

      var unusedAssets = <AssetId>{};
      void reportUnusedAssetsForInput(AssetId input, Iterable<AssetId> assets) {
        options.reportUnusedAssetsForInput?.call(input, assets);
        unusedAssets.addAll(assets);
      }

      await tracker.trackStage(
        'Build',
        () => runBuilder(
          builder,
          [input],
          readerWriter,
          readerWriter,
          PerformanceTrackingResolvers(options.resolvers, tracker),
          logger: logger,
          resourceManager: resourceManager,
          stageTracker: tracker,
          reportUnusedAssetsForInput: reportUnusedAssetsForInput,
          packageConfig: options.packageGraph.asPackageConfig,
        ).catchError((void _) {
          // Errors tracked through the logger
        }),
      );
      actionsCompletedCount++;
      hungActionsHeartbeat.ping();
      pendingActions[phaseNumber]!.remove(actionDescription);

      // Reset the state for all the `builderOutputs` nodes based on what was
      // read and written.
      await tracker.trackStage(
        'Finalize',
        () => _setOutputsState(
          input,
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
          inputNode.type == NodeType.generated &&
              inputNode.generatedNodeState!.isSuccessfulFreshOutput) {
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
        nodeBuilder: _buildAsset,
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
      assetGraph.remove(output);
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
          wasOutput: true,
          isFailure: false,
          pendingBuildAction: PendingBuildAction.none,
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

  /// Checks and returns whether any [outputs] need to be updated.
  Future<bool> _buildShouldRun(
    int phaseNumber,
    AssetId forInput,
    Iterable<AssetId> outputs,
    AssetReader reader,
  ) async {
    assert(
      outputs.every(assetGraph.contains),
      'Outputs should be known statically. Missing '
      '${outputs.where((o) => !assetGraph.contains(o)).toList()}',
    );
    assert(outputs.isNotEmpty, 'Can\'t run a build with no outputs');

    if (assetGraph.previousInBuildPhasesOptionsDigests == null) {
      if (logFine) {
        _logger.fine(
          'Build ${renderer.build(forInput, outputs)} because this is a clean '
          'build.',
        );
      }
      return true;
    }

    if (assetGraph.previousInBuildPhasesOptionsDigests![phaseNumber] !=
        assetGraph.inBuildPhasesOptionsDigests[phaseNumber]) {
      if (logFine) {
        _logger.fine(
          'Build ${renderer.build(forInput, outputs)} because builder options '
          'changed.',
        );
      }
      return true;
    }

    // We check if any output definitely needs an update - its possible during
    // manual deletions that only one of the outputs would be marked.
    for (var output in outputs.skip(1)) {
      if (assetGraph.get(output)!.generatedNodeState!.pendingBuildAction ==
          PendingBuildAction.build) {
        if (logFine) {
          _logger.fine(
            'Build ${renderer.build(forInput, outputs)} because '
            '${renderer.id(output)} was marked for build.',
          );
        }
        return true;
      }
    }

    // Otherwise, we only check the first output, because all outputs share the
    // same inputs and invalidation state.
    var firstNode = assetGraph.get(outputs.first)!;
    assert(
      outputs
          .skip(1)
          .every(
            (output) =>
                assetGraph
                    .get(output)!
                    .generatedNodeState!
                    .inputs
                    .difference(firstNode.generatedNodeState!.inputs)
                    .isEmpty,
          ),
      'All outputs of a build action should share the same inputs.',
    );

    final firstNodeState = firstNode.generatedNodeState!;

    // No need to build an up to date output
    if (firstNodeState.pendingBuildAction == PendingBuildAction.none) {
      return false;
    }

    // Early bail out condition, this is a forced update.
    if (firstNodeState.pendingBuildAction == PendingBuildAction.build) {
      if (logFine) {
        _logger.fine(
          'Build ${renderer.build(forInput, outputs)} because '
          '${renderer.id(firstNode.id)} was marked for build.',
        );
      }
      return true;
    }

    final inputs = firstNodeState.inputs;
    for (final input in inputs) {
      final node = assetGraph.get(input)!;
      if (node.type == NodeType.generated) {
        if (node.generatedNodeConfiguration!.phaseNumber >= phaseNumber) {
          // It's not readable in this phase.
          continue;
        }
        // Check that the input was built, so [changedOutputs] is updated.
        if (node.generatedNodeState!.pendingBuildAction !=
            PendingBuildAction.none) {
          await _buildAsset(node.id);
        }
        if (changedOutputs.contains(input)) {
          if (logFine) {
            _logger.fine(
              'Build ${renderer.build(forInput, outputs)} because '
              '${renderer.id(input)} was built and changed.',
            );
          }
          return true;
        }
      } else if (node.type == NodeType.glob) {
        // Check that the glob was evaluated, so [changedOutputs] is updated.
        if (node.globNodeState!.pendingBuildAction != PendingBuildAction.none) {
          await _buildGlobNode(input);
        }
        if (changedOutputs.contains(input)) {
          if (logFine) {
            _logger.fine(
              'Build ${renderer.build(forInput, outputs)} because '
              '${renderer.id(input)} matches changed.',
            );
          }
          return true;
        }
      } else if (node.type == NodeType.source) {
        if (changedInputs.contains(input)) {
          if (logFine) {
            _logger.fine(
              'Build ${renderer.build(forInput, outputs)} because '
              '${renderer.id(input)} changed.',
            );
          }
          return true;
        }
      }
    }

    // Mark outputs as not needing building.
    for (var id in outputs) {
      assetGraph.updateNode(id, (nodeBuilder) {
        if (nodeBuilder.type == NodeType.generated) {
          nodeBuilder.generatedNodeState.pendingBuildAction =
              PendingBuildAction.none;
        } else if (nodeBuilder.type == NodeType.glob) {
          nodeBuilder.globNodeState.pendingBuildAction =
              PendingBuildAction.none;
        }
      });
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

    if (assetGraph.previousPostBuildActionsOptionsDigests == null) {
      // It's a clean build.
      return true;
    }

    if (assetGraph.previousPostBuildActionsOptionsDigests![buildStepId
            .actionNumber] !=
        assetGraph.postBuildActionsOptionsDigests[buildStepId.actionNumber]) {
      return true;
    }

    if (node.type == NodeType.generated) {
      // Check that the input was built, so [changedOutputs] is updated.
      if (node.generatedNodeState!.pendingBuildAction !=
          PendingBuildAction.none) {
        await _buildAsset(node.id);
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
      if (node.type == NodeType.generated &&
          node.generatedNodeState!.wasOutput) {
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
    if (assetGraph.get(globId)!.globNodeState!.pendingBuildAction ==
        PendingBuildAction.none) {
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
        await _buildAsset(id);
      }

      // The generated file matches that were output are part of the results of
      // the glob.
      final generatedFileResults = <AssetId>[];
      for (final id in generatedFileInputs) {
        final node = assetGraph.get(id)!;
        if (node.generatedNodeState!.wasOutput &&
            !node.generatedNodeState!.isFailure) {
          generatedFileResults.add(id);
        }
      }

      final results = [...otherInputs, ...generatedFileResults];
      final digest = md5.convert(utf8.encode(results.join(' ')));
      assetGraph.updateNode(globId, (nodeBuilder) {
        if (nodeBuilder.lastKnownDigest != digest) {
          changedOutputs.add(globId);
        }
        nodeBuilder
          ..globNodeState.results.replace(results)
          ..globNodeState.inputs.replace(
            generatedFileInputs.followedBy(otherInputs),
          )
          ..globNodeState.pendingBuildAction = PendingBuildAction.none
          ..lastKnownDigest = digest;
      });

      unawaited(lazyGlobs.remove(globId));
    });
  }

  /// Sets the state for all [outputs] of a build step, by:
  ///
  /// - Setting `needsUpdate` to `false` for each output
  /// - Setting `wasOutput` based on `writer.assetsWritten`.
  /// - Setting `isFailed` based on action success.
  /// - Adding `outputs` as outputs to all `reader.assetsRead`.
  /// - Storing the error message with the [failureReporter].
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
        unusedAssets != null
            ? inputTracker.inputs.difference(unusedAssets)
            : inputTracker.inputs;

    final isFailure = errors.isNotEmpty;

    for (var output in outputs) {
      var wasOutput = readerWriter.assetsWritten.contains(output);
      var digest = wasOutput ? await this.readerWriter.digest(output) : null;

      assetGraph.updateNode(output, (nodeBuilder) {
        if (nodeBuilder.lastKnownDigest != digest) {
          changedOutputs.add(output);
        }
        nodeBuilder.generatedNodeState
          ..inputs.replace(usedInputs)
          ..pendingBuildAction = PendingBuildAction.none
          ..wasOutput = wasOutput
          ..isFailure = isFailure;
        nodeBuilder.lastKnownDigest = digest;
      });

      assetGraph.updateNode(output, (nodeBuilder) {});

      if (isFailure) {
        final node = assetGraph.get(output)!;
        await failureReporter.markReported(actionDescription, node, errors);
        var needsMarkAsFailure = Queue.of(node.primaryOutputs);
        var allSkippedFailures = <AssetId>[];
        while (needsMarkAsFailure.isNotEmpty) {
          var output = needsMarkAsFailure.removeLast();
          assetGraph.updateNode(output, (nodeBuilder) {
            if (nodeBuilder.lastKnownDigest != null) {
              changedOutputs.add(output);
            }
            nodeBuilder.generatedNodeState
              ..pendingBuildAction = PendingBuildAction.none
              ..wasOutput = false
              ..isFailure = true;
            nodeBuilder.lastKnownDigest = null;
          });
          allSkippedFailures.add(output);
          needsMarkAsFailure.addAll(assetGraph.get(output)!.primaryOutputs);

          // Make sure output invalidation follows primary outputs for builds
          // that won't run.
          assetGraph.updateNode(output, (nodeBuilder) {
            nodeBuilder.generatedNodeState.inputs.add(node.id);
          });
        }
        await failureReporter.markSkipped(
          allSkippedFailures.map((id) => assetGraph.get(id)!),
        );
      }
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
