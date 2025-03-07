// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../asset/finalized_reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../asset_graph/optional_output_tracker.dart';
import '../changes/build_script_updates.dart';
import '../environment/build_environment.dart';
import '../logging/build_for_input_logger.dart';
import '../logging/failure_reporter.dart';
import '../logging/human_readable_duration.dart';
import '../logging/logging.dart';
import '../package_graph/apply_builders.dart';
import '../package_graph/package_graph.dart';
import '../package_graph/target_graph.dart';
import '../performance_tracking/performance_tracking_resolvers.dart';
import '../util/build_dirs.dart';
import '../util/constants.dart';
import 'build_definition.dart';
import 'build_directory.dart';
import 'build_result.dart';
import 'finalized_assets_view.dart';
import 'heartbeat.dart';
import 'input_tracker.dart';
import 'options.dart';
import 'performance_tracker.dart';
import 'phase.dart';
import 'single_step_reader_writer.dart';

final _logger = Logger('Build');

Set<String> _buildPaths(Set<BuildDirectory> buildDirs) =>
    // The empty string means build everything.
    buildDirs.any((b) => b.directory == '')
        ? <String>{}
        : buildDirs.map((b) => b.directory).toSet();

class BuildImpl {
  final FinalizedReader finalizedReader;

  final AssetGraph assetGraph;

  final BuildScriptUpdates? buildScriptUpdates;

  final List<BuildPhase> _buildPhases;
  final PackageGraph _packageGraph;
  final TargetGraph _targetGraph;
  final AssetReaderWriter _reader;
  final Resolvers _resolvers;
  final ResourceManager _resourceManager;
  final RunnerAssetWriter _writer;
  final bool _trackPerformance;
  final BuildEnvironment _environment;
  final String? _logPerformanceDir;

  Future<void> beforeExit() => _resourceManager.beforeExit();

  BuildImpl._(
    BuildDefinition buildDefinition,
    BuildOptions options,
    this._buildPhases,
    this.finalizedReader,
  ) : buildScriptUpdates = buildDefinition.buildScriptUpdates,
      _packageGraph = buildDefinition.packageGraph,
      _targetGraph = buildDefinition.targetGraph,
      _reader =
          options.enableLowResourcesMode
              ? buildDefinition.reader.copyWith(
                cache: const PassthroughFilesystemCache(),
              )
              : buildDefinition.reader.copyWith(
                cache: InMemoryFilesystemCache(),
              ),
      _resolvers = options.resolvers,
      _writer = buildDefinition.writer,
      assetGraph = buildDefinition.assetGraph,
      _resourceManager = buildDefinition.resourceManager,
      _environment = buildDefinition.environment,
      _trackPerformance = options.trackPerformance,
      _logPerformanceDir = options.logPerformanceDir;

  Future<BuildResult> run(
    Map<AssetId, ChangeType> updates, {
    Set<BuildDirectory> buildDirs = const <BuildDirectory>{},
    Set<BuildFilter> buildFilters = const {},
  }) {
    finalizedReader.reset(_buildPaths(buildDirs), buildFilters);
    return _SingleBuild(this, buildDirs, buildFilters).run(updates)
      ..whenComplete(_resolvers.reset);
  }

  static Future<BuildImpl> create(
    BuildOptions options,
    BuildEnvironment environment,
    List<BuilderApplication> builders,
    Map<String, Map<String, dynamic>> builderConfigOverrides, {
    bool isReleaseBuild = false,
  }) async {
    // Don't allow any changes to the generated asset directory after this
    // point.
    lockGeneratedOutputDirectory();

    var buildPhases = await createBuildPhases(
      options.targetGraph,
      builders,
      builderConfigOverrides,
      isReleaseBuild,
    );
    if (buildPhases.isEmpty) {
      _logger.severe('Nothing can be built, yet a build was requested.');
    }
    var buildDefinition = await BuildDefinition.prepareWorkspace(
      environment,
      options,
      buildPhases,
    );
    var finalizedReader = FinalizedReader(
      buildDefinition.reader,
      buildDefinition.assetGraph,
      buildDefinition.targetGraph,
      buildPhases,
      options.packageGraph.root.name,
    );
    var build = BuildImpl._(
      buildDefinition,
      options,
      buildPhases,
      finalizedReader,
    );
    return build;
  }
}

/// Performs a single build and manages state that only lives for a single
/// build.
class _SingleBuild {
  final AssetGraph _assetGraph;
  final Set<BuildFilter> _buildFilters;
  final List<BuildPhase> _buildPhases;
  final BuildEnvironment _environment;
  final _lazyPhases = <String, Future<Iterable<AssetId>>>{};
  final _lazyGlobs = <AssetId, Future<void>>{};
  final PackageGraph _packageGraph;
  final TargetGraph _targetGraph;
  final BuildPerformanceTracker _performanceTracker;
  final AssetReaderWriter _readerWriter;
  final Resolvers _resolvers;
  final ResourceManager _resourceManager;
  final RunnerAssetWriter _writer;
  final Set<BuildDirectory> _buildDirs;
  final String? _logPerformanceDir;
  final _failureReporter = FailureReporter();

  int actionsCompletedCount = 0;
  int actionsStartedCount = 0;

  final pendingActions = SplayTreeMap<int, Set<String>>();

  late final HungActionsHeartbeat hungActionsHeartbeat;

  _SingleBuild(
    BuildImpl buildImpl,
    Set<BuildDirectory> buildDirs,
    Set<BuildFilter> buildFilters,
  ) : _assetGraph = buildImpl.assetGraph,
      _buildFilters = buildFilters,
      _buildPhases = buildImpl._buildPhases,
      _environment = buildImpl._environment,
      _packageGraph = buildImpl._packageGraph,
      _targetGraph = buildImpl._targetGraph,
      _performanceTracker =
          buildImpl._trackPerformance
              ? BuildPerformanceTracker()
              : BuildPerformanceTracker.noOp(),
      _readerWriter = buildImpl._reader,
      _resolvers = buildImpl._resolvers,
      _resourceManager = buildImpl._resourceManager,
      _writer = buildImpl._writer,
      _buildDirs = buildDirs,
      _logPerformanceDir = buildImpl._logPerformanceDir {
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
    var watch = Stopwatch()..start();
    var result = await _safeBuild(updates);
    var optionalOutputTracker = OptionalOutputTracker(
      _assetGraph,
      _targetGraph,
      _buildPaths(_buildDirs),
      _buildFilters,
      _buildPhases,
    );
    if (result.status == BuildStatus.success) {
      final failures = _assetGraph.failedOutputs.where(
        (n) => optionalOutputTracker.isRequired(n.id),
      );
      if (failures.isNotEmpty) {
        await _failureReporter.reportErrors(failures);
        result = BuildResult(
          BuildStatus.failure,
          result.outputs,
          performance: result.performance,
        );
      }
    }
    await _environment.writer.completeBuild();
    await _resourceManager.disposeAll();
    result = await _environment.finalizeBuild(
      result,
      FinalizedAssetsView(_assetGraph, _packageGraph, optionalOutputTracker),
      _readerWriter,
      _buildDirs,
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
      var invalidated = await _assetGraph.updateAndInvalidate(
        _buildPhases,
        updates,
        _packageGraph.root.name,
        _delete,
        _readerWriter,
      );
      await _readerWriter.cache.invalidate(invalidated);
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
        if (updates.isNotEmpty) {
          await _updateAssetGraph(updates);
        }
        // Run a fresh build.
        var result = await logTimedAsync(_logger, 'Running build', _runPhases);

        // Write out the dependency graph file.
        await logTimedAsync(
          _logger,
          'Caching finalized dependency graph',
          () async {
            await _writer.writeAsBytes(
              AssetId(_packageGraph.root.name, assetGraphPath),
              _assetGraph.serialize(),
            );
          },
        );

        // Log performance information if requested
        if (_logPerformanceDir != null) {
          assert(result.performance != null);
          var now = DateTime.now();
          var logPath = p.join(
            _logPerformanceDir,
            '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}'
            '_${_twoDigits(now.hour)}-${_twoDigits(now.minute)}-'
            '${_twoDigits(now.second)}',
          );
          await logTimedAsync(
            _logger,
            'Writing performance log to $logPath',
            () {
              var performanceLogId = AssetId(_packageGraph.root.name, logPath);
              var serialized = jsonEncode(result.performance);
              return _writer.writeAsString(performanceLogId, serialized);
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

  /// Runs the actions in [_buildPhases] and returns a future which completes
  /// to the [BuildResult] once all [BuildPhase]s are done.
  Future<BuildResult> _runPhases() {
    return _performanceTracker.track(() async {
      final outputs = <AssetId>[];
      for (var phaseNum = 0; phaseNum < _buildPhases.length; phaseNum++) {
        var phase = _buildPhases[phaseNum];
        if (phase.isOptional) continue;
        outputs.addAll(
          await _performanceTracker.trackBuildPhase(phase, () async {
            if (phase is InBuildPhase) {
              var primaryInputs = await _matchingPrimaryInputs(
                phase.package,
                phaseNum,
              );
              return _runBuilder(phaseNum, phase, primaryInputs);
            } else if (phase is PostBuildPhase) {
              return _runPostProcessPhase(phaseNum, phase);
            } else {
              throw StateError('Unrecognized BuildPhase type $phase');
            }
          }),
        );
      }
      await Future.forEach(
        _lazyPhases.values,
        (Future<Iterable<AssetId>> lazyOuts) async =>
            outputs.addAll(await lazyOuts),
      );
      // Assume success, `_assetGraph.failedOutputs` will be checked later.
      return BuildResult(
        BuildStatus.success,
        outputs,
        performance: _performanceTracker,
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
    var phase = _buildPhases[phaseNumber];
    var packageNode = _packageGraph[package]!;

    for (final node in _assetGraph
        .outputsForPhase(package, phaseNumber)
        .toList(growable: false)) {
      if (!shouldBuildForDirs(
        node.id,
        buildDirs: _buildPaths(_buildDirs),
        buildFilters: _buildFilters,
        phase: phase,
        targetGraph: _targetGraph,
      )) {
        continue;
      }

      // Don't build for inputs that aren't visible. This can happen for
      // placeholder nodes like `test/$test$` that are added to each package,
      // since the test dir is not part of the build for non-root packages.
      if (!_targetGraph.isVisibleInBuild(node.id, packageNode)) continue;

      var input = _assetGraph.get(node.primaryInput)!;
      if (input is GeneratedAssetNode) {
        if (input.state != NodeState.upToDate) {
          await _runLazyPhaseForInput(input.phaseNumber, input.primaryInput);
        }
        if (!input.wasOutput) continue;
        if (input.isFailure) continue;
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
    return _lazyPhases.putIfAbsent('$phaseNumber|$input', () async {
      // First check if `input` is generated, and whether or not it was
      // actually output. If it wasn't then we just return an empty list here.
      var inputNode = _assetGraph.get(input);
      if (inputNode is GeneratedAssetNode) {
        // Make sure the `inputNode` is up to date, and rebuild it if not.
        if (inputNode.state != NodeState.upToDate) {
          await _runLazyPhaseForInput(
            inputNode.phaseNumber,
            inputNode.primaryInput,
          );
        }
        if (!inputNode.wasOutput || inputNode.isFailure) return <AssetId>[];
      }

      // We can never lazily build `PostProcessBuildAction`s.
      var action = _buildPhases[phaseNumber] as InBuildPhase;

      return _runForInput(phaseNumber, action, input);
    });
  }

  Future<void> _buildAsset(AssetNode node) async {
    if (node is GeneratedAssetNode && node.state != NodeState.upToDate) {
      await _runLazyPhaseForInput(node.phaseNumber, node.primaryInput);
    }
  }

  Future<Iterable<AssetId>> _runForInput(
    int phaseNumber,
    InBuildPhase phase,
    AssetId input,
  ) async {
    final builder = phase.builder;
    var tracker = _performanceTracker.addBuilderAction(
      input,
      phase.builderLabel,
    );
    return tracker.track(() async {
      var builderOutputs = expectedOutputs(builder, input);

      // Add `builderOutputs` to the primary outputs of the input.
      var inputNode = _assetGraph.get(input)!;
      assert(
        inputNode.inspect.primaryOutputs.containsAll(builderOutputs),
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
          packageGraph: _packageGraph,
          targetGraph: _targetGraph,
          assetGraph: _assetGraph,
          nodeBuilder: _buildAsset,
          globNodeBuilder: _buildGlobNode,
        ),
        runningBuildStep: RunningBuildStep(
          phaseNumber: phaseNumber,

          buildPhase: phase,
          primaryPackage: input.package,
        ),
        readerWriter: _readerWriter,
        inputTracker: InputTracker(_readerWriter.filesystem),
        assetsWritten: {},
      );

      if (!await tracker.trackStage(
        'Setup',
        () => _buildShouldRun(builderOutputs, readerWriter),
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
        _packageGraph.root.name,
      );
      var logger = BuildForInputLogger(Logger(actionDescription));

      actionsStartedCount++;
      pendingActions
          .putIfAbsent(phaseNumber, () => <String>{})
          .add(actionDescription);

      var unusedAssets = <AssetId>{};
      await tracker.trackStage(
        'Build',
        () => runBuilder(
          builder,
          [input],
          readerWriter,
          readerWriter,
          PerformanceTrackingResolvers(_resolvers, tracker),
          logger: logger,
          resourceManager: _resourceManager,
          stageTracker: tracker,
          reportUnusedAssetsForInput:
              (_, assets) => unusedAssets.addAll(assets),
          packageConfig: _packageGraph.asPackageConfig,
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

  Future<Iterable<AssetId>> _runPostProcessPhase(
    int phaseNum,
    PostBuildPhase phase,
  ) async {
    var actionNum = 0;
    var outputLists = await Future.wait(
      phase.builderActions.map(
        (action) => _runPostProcessAction(phaseNum, actionNum++, action),
      ),
    );
    return outputLists.fold<List<AssetId>>(
      <AssetId>[],
      (combined, next) => combined..addAll(next),
    );
  }

  Future<Iterable<AssetId>> _runPostProcessAction(
    int phaseNum,
    int actionNum,
    PostBuildAction action,
  ) async {
    final outputs = <AssetId>[];
    for (final node in _assetGraph
        .packageNodes(action.package)
        .toList(growable: false)) {
      if (node is! PostProcessAnchorNode) continue;
      if (node.actionNumber != actionNum) continue;
      final inputNode = _assetGraph.get(node.primaryInput)!;
      if (inputNode.type == NodeType.source ||
          inputNode is GeneratedAssetNode &&
              inputNode.wasOutput &&
              !inputNode.isFailure &&
              inputNode.state == NodeState.upToDate) {
        outputs.addAll(
          await _runPostProcessBuilderForAnchor(
            phaseNum,
            actionNum,
            action.builder,
            node,
          ),
        );
      }
    }
    return outputs;
  }

  Future<Iterable<AssetId>> _runPostProcessBuilderForAnchor(
    int phaseNumber,
    int actionNum,
    PostProcessBuilder builder,
    PostProcessAnchorNode anchorNode,
  ) async {
    var input = anchorNode.primaryInput;
    var inputNode = _assetGraph.get(input)!;
    var readerWriter = SingleStepReaderWriter(
      runningBuild: RunningBuild(
        packageGraph: _packageGraph,
        targetGraph: _targetGraph,
        assetGraph: _assetGraph,
        nodeBuilder: _buildAsset,
        globNodeBuilder: _buildGlobNode,
      ),
      runningBuildStep: RunningBuildStep(
        phaseNumber: phaseNumber,
        buildPhase: _buildPhases[phaseNumber],
        primaryPackage: input.package,
      ),
      readerWriter: _readerWriter,
      inputTracker: InputTracker(_readerWriter.filesystem),
      assetsWritten: {},
    );

    if (!await _postProcessBuildShouldRun(anchorNode, readerWriter)) {
      return <AssetId>[];
    }
    // Clear input tracking accumulated during `_buildShouldRun`.
    readerWriter.inputTracker.clear();

    // Clean out the impacts of the previous run.
    await FailureReporter.clean(phaseNumber, input);
    await _cleanUpStaleOutputs(anchorNode.outputs);
    for (final output in anchorNode.outputs.toList(growable: false)) {
      _assetGraph.remove(output);
    }
    anchorNode.mutate.outputs.clear();
    inputNode.mutate.deletedBy.remove(anchorNode.id);

    var actionDescription = '$builder on $input';
    var logger = BuildForInputLogger(Logger(actionDescription));

    actionsStartedCount++;
    pendingActions
        .putIfAbsent(phaseNumber, () => <String>{})
        .add(actionDescription);

    await runPostProcessBuilder(
      builder,
      input,
      readerWriter,
      readerWriter,
      logger,
      addAsset: (assetId) {
        if (_assetGraph.contains(assetId)) {
          throw InvalidOutputException(assetId, 'Asset already exists');
        }
        var node = GeneratedAssetNode(
          assetId,
          primaryInput: input,
          builderOptionsId: anchorNode.builderOptionsId,
          isHidden: true,
          phaseNumber: phaseNumber,
          wasOutput: true,
          isFailure: false,
          state: NodeState.upToDate,
        );
        _assetGraph.add(node);
        anchorNode.mutate.outputs.add(assetId);
      },
      deleteAsset: (assetId) {
        if (!_assetGraph.contains(assetId)) {
          throw AssetNotFoundException(assetId);
        }
        if (assetId != input) {
          throw InvalidOutputException(
            assetId,
            'Can only delete primary input',
          );
        }
        _assetGraph.get(assetId)!.mutate.deletedBy.add(anchorNode.id);
      },
    ).catchError((void _) {
      // Errors tracked through the logger
    });
    actionsCompletedCount++;
    hungActionsHeartbeat.ping();
    pendingActions[phaseNumber]!.remove(actionDescription);

    var assetsWritten = readerWriter.assetsWritten.toSet();

    // Reset the state for all the output nodes based on what was read and
    // written.
    inputNode.mutate.primaryOutputs.addAll(assetsWritten);
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
    Iterable<AssetId> outputs,
    AssetReader reader,
  ) async {
    assert(
      outputs.every(_assetGraph.contains),
      'Outputs should be known statically. Missing '
      '${outputs.where((o) => !_assetGraph.contains(o)).toList()}',
    );
    assert(outputs.isNotEmpty, 'Can\'t run a build with no outputs');

    // We check if any output definitely needs an update - its possible during
    // manual deletions that only one of the outputs would be marked.
    for (var output in outputs.skip(1)) {
      if ((_assetGraph.get(output) as GeneratedAssetNode).state ==
          NodeState.definitelyNeedsUpdate) {
        return true;
      }
    }

    // Otherwise, we only check the first output, because all outputs share the
    // same inputs and invalidation state.
    var firstNode = _assetGraph.get(outputs.first) as GeneratedAssetNode;
    assert(
      outputs
          .skip(1)
          .every(
            (output) =>
                (_assetGraph.get(output) as GeneratedAssetNode).inputs
                    .difference(firstNode.inputs)
                    .isEmpty,
          ),
      'All outputs of a build action should share the same inputs.',
    );

    // No need to build an up to date output
    if (firstNode.state == NodeState.upToDate) return false;
    // Early bail out condition, this is a forced update.
    if (firstNode.state == NodeState.definitelyNeedsUpdate) return true;
    // This is a fresh build or the first time we've seen this output.
    if (firstNode.previousInputsDigest == null) return true;

    var digest = await _computeCombinedDigest(
      firstNode.inputs,
      firstNode.builderOptionsId,
      reader,
    );
    if (digest != firstNode.previousInputsDigest) {
      return true;
    } else {
      // Make sure to update the `state` field for all outputs.
      for (var id in outputs) {
        (_assetGraph.get(id) as NodeWithInputs).state = NodeState.upToDate;
      }
      return false;
    }
  }

  /// Checks if a post process build should run based on [anchorNode].
  Future<bool> _postProcessBuildShouldRun(
    PostProcessAnchorNode anchorNode,
    AssetReader reader,
  ) async {
    var inputsDigest = await _computeCombinedDigest(
      [anchorNode.primaryInput],
      anchorNode.builderOptionsId,
      reader,
    );

    if (inputsDigest != anchorNode.previousInputsDigest) {
      anchorNode.previousInputsDigest = inputsDigest;
      return true;
    }

    return false;
  }

  /// Deletes any of [outputs] which previously were output.
  ///
  /// This should be called after deciding that an asset really needs to be
  /// regenerated based on its inputs hash changing. All assets in [outputs]
  /// must correspond to a [GeneratedAssetNode].
  Future<void> _cleanUpStaleOutputs(Iterable<AssetId> outputs) async {
    for (final output in outputs) {
      final node = _assetGraph.get(output)!;
      if (node is GeneratedAssetNode && node.wasOutput) {
        await _delete(output);
      }
    }
  }

  Future<void> _buildGlobNode(GlobAssetNode globNode) async {
    if (globNode.state == NodeState.upToDate) return;

    return _lazyGlobs.putIfAbsent(globNode.id, () async {
      var potentialNodes =
          _assetGraph
              .packageNodes(globNode.id.package)
              .where((n) => n.isFile && n.isTrackedInput)
              .where(
                (n) =>
                    n is! GeneratedAssetNode ||
                    n.phaseNumber < globNode.phaseNumber,
              )
              .where((n) => globNode.glob.matches(n.id.path))
              .toList();

      for (final node in potentialNodes) {
        if (node is GeneratedAssetNode) {
          await _buildAsset(node);
        }
      }

      var actualMatches = <AssetId>[];
      for (var node in potentialNodes) {
        node.mutate.outputs.add(globNode.id);
        if (node is GeneratedAssetNode && (!node.wasOutput || node.isFailure)) {
          continue;
        }
        actualMatches.add(node.id);
      }

      globNode
        ..results = actualMatches
        ..inputs = HashSet.of(potentialNodes.map((n) => n.id))
        ..state = NodeState.upToDate;
      globNode.mutate.lastKnownDigest = md5.convert(
        utf8.encode(actualMatches.join(' ')),
      );

      // TODO: remove ?? fallback after 2.15 sdk.
      unawaited(_lazyGlobs.remove(globNode.id) ?? Future.value());
    });
  }

  /// Computes a single [Digest] based on the combined [Digest]s of [ids] and
  /// [builderOptionsId].
  Future<Digest> _computeCombinedDigest(
    Iterable<AssetId> ids,
    AssetId builderOptionsId,
    AssetReader reader,
  ) async {
    var combinedBytes = Uint8List.fromList(List.filled(16, 0));
    void combine(Uint8List other) {
      assert(other.length == 16);
      for (var i = 0; i < 16; i++) {
        combinedBytes[i] ^= other[i];
      }
    }

    var builderOptionsNode = _assetGraph.get(builderOptionsId)!;
    combine(builderOptionsNode.lastKnownDigest!.bytes as Uint8List);

    for (final id in ids) {
      var node = _assetGraph.get(id)!;
      if (node is GlobAssetNode) {
        await _buildGlobNode(node);
      } else if (!await reader.canRead(id)) {
        // We want to add something here, a missing/unreadable input should be
        // different from no input at all.
        //
        // This needs to be unique per input so we use the md5 hash of the id.
        combine(md5.convert(id.toString().codeUnits).bytes as Uint8List);
        continue;
      } else {
        if (node.lastKnownDigest == null) {
          await reader.cache.invalidate([id]);
          node.mutate.lastKnownDigest = await reader.digest(id);
        }
      }
      combine(node.lastKnownDigest!.bytes as Uint8List);
    }

    return Digest(combinedBytes);
  }

  /// Sets the state for all [outputs] of a build step, by:
  ///
  /// - Setting `needsUpdate` to `false` for each output
  /// - Setting `wasOutput` based on `writer.assetsWritten`.
  /// - Setting `isFailed` based on action success.
  /// - Adding `outputs` as outputs to all `reader.assetsRead`.
  /// - Setting the `lastKnownDigest` on each output based on the new contents.
  /// - Setting the `previousInputsDigest` on each output based on the inputs.
  /// - Storing the error message with the [_failureReporter].
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

    final inputsDigest = await _computeCombinedDigest(
      usedInputs,
      (_assetGraph.get(outputs.first) as GeneratedAssetNode).builderOptionsId,
      readerWriter,
    );

    final isFailure = errors.isNotEmpty;

    for (var output in outputs) {
      var wasOutput = readerWriter.assetsWritten.contains(output);
      var digest = wasOutput ? await _readerWriter.digest(output) : null;
      var node = _assetGraph.get(output) as GeneratedAssetNode;

      // **IMPORTANT**: All updates to `node` must be synchronous. With lazy
      // builders we can run arbitrary code between updates otherwise, at which
      // time a node might not be in a valid state.
      _removeOldInputs(node, usedInputs);
      _addNewInputs(node, usedInputs);
      node
        ..state = NodeState.upToDate
        ..wasOutput = wasOutput
        ..isFailure = isFailure
        ..previousInputsDigest = inputsDigest;
      node.mutate.lastKnownDigest = digest;

      if (isFailure) {
        await _failureReporter.markReported(actionDescription, node, errors);
        var needsMarkAsFailure = Queue.of(node.primaryOutputs);
        var allSkippedFailures = <GeneratedAssetNode>[];
        while (needsMarkAsFailure.isNotEmpty) {
          var output = needsMarkAsFailure.removeLast();
          var outputNode =
              _assetGraph.get(output) as GeneratedAssetNode
                ..state = NodeState.upToDate
                ..wasOutput = false
                ..isFailure = true
                ..previousInputsDigest = null;
          outputNode.mutate.lastKnownDigest = null;
          allSkippedFailures.add(outputNode);
          needsMarkAsFailure.addAll(outputNode.primaryOutputs);

          // Make sure output invalidation follows primary outputs for builds
          // that won't run.
          node.mutate.outputs.add(output);
          outputNode.inputs.add(node.id);
        }
        await _failureReporter.markSkipped(allSkippedFailures);
      }
    }
  }

  /// Removes old inputs from [node] based on [updatedInputs], and cleans up all
  /// the old edges.
  void _removeOldInputs(GeneratedAssetNode node, Set<AssetId> updatedInputs) {
    var removedInputs = node.inputs.difference(updatedInputs);
    node.inputs.removeAll(removedInputs);
    for (var input in removedInputs) {
      var inputNode = _assetGraph.get(input)!;
      inputNode.mutate.outputs.remove(node.id);
    }
  }

  /// Adds new inputs to [node] based on [updatedInputs], and adds the
  /// appropriate edges.
  void _addNewInputs(GeneratedAssetNode node, Set<AssetId> updatedInputs) {
    var newInputs = updatedInputs.difference(node.inputs);
    node.inputs.addAll(newInputs);
    for (var input in newInputs) {
      var inputNode = _assetGraph.get(input)!;
      inputNode.mutate.outputs.add(node.id);
    }
  }

  Future _delete(AssetId id) => _writer.delete(id);
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
