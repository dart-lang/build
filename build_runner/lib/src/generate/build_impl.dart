// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:watcher/watcher.dart';

import '../asset/cache.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../environment/build_environment.dart';
import '../environment/io_environment.dart';
import '../environment/overridable_environment.dart';
import '../logging/error_recording_logger.dart';
import '../logging/human_readable_duration.dart';
import '../logging/logging.dart';
import '../package_graph/apply_builders.dart';
import '../package_graph/build_config_overrides.dart';
import '../package_graph/package_graph.dart';
import '../package_graph/target_graph.dart';
import '../performance_tracking/performance_tracking_resolvers.dart';
import '../util/constants.dart';
import 'build_definition.dart';
import 'build_result.dart';
import 'create_merged_dir.dart';
import 'exceptions.dart';
import 'fold_frames.dart';
import 'heartbeat.dart';
import 'options.dart';
import 'performance_tracker.dart';
import 'phase.dart';
import 'terminator.dart';

final _logger = new Logger('Build');

Future<BuildResult> build(
  List<BuilderApplication> builders, {
  bool deleteFilesByDefault,
  bool failOnSevere,
  bool assumeTty,
  String configKey,
  PackageGraph packageGraph,
  RunnerAssetReader reader,
  RunnerAssetWriter writer,
  Level logLevel,
  onLog(LogRecord record),
  Stream terminateEventStream,
  bool skipBuildScriptCheck,
  bool enableLowResourcesMode,
  Map<String, BuildConfig> overrideBuildConfig,
  String outputDir,
  bool trackPerformance,
  bool verbose,
  Map<String, Map<String, dynamic>> builderConfigOverrides,
}) async {
  builderConfigOverrides ??= const {};
  packageGraph ??= new PackageGraph.forThisPackage();
  overrideBuildConfig ??=
      await findBuildConfigOverrides(packageGraph, configKey);
  final targetGraph = await TargetGraph.forPackageGraph(packageGraph,
      overrideBuildConfig: overrideBuildConfig);
  var environment = new OverrideableEnvironment(
      new IOEnvironment(packageGraph, assumeTty, verbose: verbose),
      reader: reader,
      writer: writer,
      onLog: onLog);
  var options = new BuildOptions(environment,
      configKey: configKey,
      deleteFilesByDefault: deleteFilesByDefault,
      failOnSevere: failOnSevere,
      packageGraph: packageGraph,
      rootPackageConfig: targetGraph.rootPackageConfig,
      logLevel: logLevel,
      skipBuildScriptCheck: skipBuildScriptCheck,
      enableLowResourcesMode: enableLowResourcesMode,
      outputDir: outputDir,
      trackPerformance: trackPerformance,
      verbose: verbose);
  var terminator = new Terminator(terminateEventStream);

  final buildActions =
      await createBuildActions(targetGraph, builders, builderConfigOverrides);

  var result = await singleBuild(environment, options, buildActions);

  await terminator.cancel();
  await options.logListener.cancel();
  return result;
}

Future<BuildResult> singleBuild(BuildEnvironment environment,
    BuildOptions options, List<BuildAction> buildActions) async {
  var buildDefinition = await BuildDefinition.prepareWorkspace(
      environment, options, buildActions);
  var result = (await BuildImpl.create(buildDefinition, options, buildActions))
      .firstBuild;
  await buildDefinition.resourceManager.beforeExit();
  return result;
}

class BuildImpl {
  BuildResult _firstBuild;
  BuildResult get firstBuild => _firstBuild;

  final AssetGraph _assetGraph;
  final List<BuildAction> _buildActions;
  final bool _failOnSevere;
  final OnDelete _onDelete;
  final PackageGraph _packageGraph;
  final AssetReader _reader;
  final _resolvers = new AnalyzerResolvers();
  final ResourceManager _resourceManager;
  final RunnerAssetWriter _writer;
  final String _outputDir;
  final bool _trackPerformance;
  final bool _verbose;
  final BuildEnvironment _environment;

  BuildImpl._(
      BuildDefinition buildDefinition, BuildOptions options, this._buildActions)
      : _packageGraph = buildDefinition.packageGraph,
        _reader = options.enableLowResourcesMode
            ? buildDefinition.reader
            : new CachingAssetReader(buildDefinition.reader),
        _writer = buildDefinition.writer,
        _assetGraph = buildDefinition.assetGraph,
        _resourceManager = buildDefinition.resourceManager,
        _onDelete = buildDefinition.onDelete,
        _outputDir = options.outputDir,
        _verbose = options.verbose,
        _failOnSevere = options.failOnSevere,
        _environment = buildDefinition.environment,
        _trackPerformance = options.trackPerformance;

  Future<BuildResult> run(Map<AssetId, ChangeType> updates) =>
      new _SingleBuild(this).run(updates);

  static Future<BuildImpl> create(BuildDefinition buildDefinition,
      BuildOptions options, List<BuildAction> buildActions,
      {void onDelete(AssetId id)}) async {
    var build = new BuildImpl._(buildDefinition, options, buildActions);

    build._firstBuild = await build.run({});
    return build;
  }
}

/// Performs a single build and manages state that only lives for a single
/// build.
class _SingleBuild {
  final AssetGraph _assetGraph;
  final List<BuildAction> _buildActions;
  final BuildEnvironment _environment;
  final bool _failOnSevere;
  final _lazyPhases = <String, Future<Iterable<AssetId>>>{};
  final OnDelete _onDelete;
  final String _outputDir;
  final PackageGraph _packageGraph;
  final BuildPerformanceTracker _performanceTracker;
  final AssetReader _reader;
  final Resolvers _resolvers;
  final ResourceManager _resourceManager;
  final bool _verbose;
  final RunnerAssetWriter _writer;

  int numActionsCompleted = 0;
  int numActionsStarted = 0;

  _SingleBuild(BuildImpl buildImpl)
      : _assetGraph = buildImpl._assetGraph,
        _buildActions = buildImpl._buildActions,
        _environment = buildImpl._environment,
        _failOnSevere = buildImpl._failOnSevere,
        _onDelete = buildImpl._onDelete,
        _outputDir = buildImpl._outputDir,
        _packageGraph = buildImpl._packageGraph,
        _performanceTracker = buildImpl._trackPerformance
            ? new BuildPerformanceTracker()
            : new BuildPerformanceTracker.noOp(),
        _reader = buildImpl._reader,
        _resolvers = buildImpl._resolvers,
        _resourceManager = buildImpl._resourceManager,
        _verbose = buildImpl._verbose,
        _writer = buildImpl._writer;

  Future<BuildResult> run(Map<AssetId, ChangeType> updates) async {
    var watch = new Stopwatch()..start();
    if (updates.isNotEmpty) {
      await _updateAssetGraph(updates);
    }
    var result = await _safeBuild(_resourceManager);
    await _resourceManager.disposeAll();
    if (_failOnSevere &&
        _assetGraph.failedActions.isNotEmpty &&
        result.status == BuildStatus.success) {
      int numFailing = _assetGraph.failedActions.values
          .fold(0, (total, ids) => total + ids.length);
      result = _convertToFailure(
          result,
          'There were $numFailing actions with SEVERE logs and '
          '--fail-on-severe was passed.');
    }
    if (_outputDir != null && result.status == BuildStatus.success) {
      if (!await createMergedOutputDir(
          _outputDir, _assetGraph, _packageGraph, _reader, _environment)) {
        result = _convertToFailure(
            result, 'Failed to create merged output directory.');
      }
    }
    if (result.status == BuildStatus.success) {
      _logger.info('Succeeded after ${humanReadable(watch.elapsed)} with '
          '${result.outputs.length} outputs\n');
    } else {
      if (result.exception is FatalBuildException) {
        // TODO(???) Really bad idea. Should not set exit codes in libraries!
        exitCode = 1;
      }
      _logger.severe('Failed after ${humanReadable(watch.elapsed)}',
          result.exception, result.stackTrace);
    }
    return result;
  }

  BuildResult _convertToFailure(BuildResult previous, String errorMessge) =>
      new BuildResult(
        BuildStatus.failure,
        previous.outputs,
        exception: errorMessge,
        performance: previous.performance,
      );

  Future<Null> _updateAssetGraph(Map<AssetId, ChangeType> updates) async {
    await logTimedAsync(_logger, 'Updating asset graph', () async {
      var invalidated = await _assetGraph.updateAndInvalidate(
          _buildActions, updates, _packageGraph.root.name, _delete, _reader);
      if (_reader is CachingAssetReader) {
        (_reader as CachingAssetReader).invalidate(invalidated);
      }
    });
  }

  /// Runs a build inside a zone with an error handler and stack chain
  /// capturing.
  Future<BuildResult> _safeBuild(ResourceManager resourceManager) {
    var done = new Completer<BuildResult>();

    var heartbeat = new HeartbeatLogger(
        transformLog: (original) => '$original, ${_buildProgress()}',
        waitDuration: new Duration(seconds: 1))
      ..start();
    done.future.then((_) {
      heartbeat.stop();
    });
    Chain.capture(() async {
      // Run a fresh build.
      var result = await logTimedAsync(
          _logger, 'Running build', () => _runPhases(resourceManager));

      // Write out the dependency graph file.
      await logTimedAsync(_logger, 'Caching finalized dependency graph',
          () async {
        await _writer.writeAsBytes(
            new AssetId(_packageGraph.root.name, assetGraphPath),
            _assetGraph.serialize());
      });

      done.complete(result);
    }, onError: (e, Chain chain) {
      final trace = _verbose
          ? chain.toTrace()
          : foldInternalFrames(chain.toTrace()).terse;
      done.complete(new BuildResult(BuildStatus.failure, [],
          exception: e, stackTrace: trace));
    });
    return done.future;
  }

  /// Returns a message describing the progress of the current build.
  String _buildProgress() =>
      '$numActionsCompleted/$numActionsStarted actions completed.';

  /// Runs the actions in [_buildActions] and returns a [Future<BuildResult>]
  /// which completes once all [BuildAction]s are done.
  Future<BuildResult> _runPhases(ResourceManager resourceManager) async {
    _performanceTracker.start();
    final outputs = <AssetId>[];
    for (var phase = 0; phase < _buildActions.length; phase++) {
      var action = _buildActions[phase];
      if (action.isOptional) continue;
      await _performanceTracker.trackBuildPhase(action, () async {
        var primaryInputs =
            await _matchingPrimaryInputs(action, phase, resourceManager);
        outputs.addAll(await _runBuilder(phase, action.hideOutput,
            action.builder, primaryInputs, resourceManager));
      });
    }
    await Future.forEach(
        _lazyPhases.values,
        (Future<Iterable<AssetId>> lazyOuts) async =>
            outputs.addAll(await lazyOuts));
    return new BuildResult(BuildStatus.success, outputs,
        performance: _performanceTracker..stop());
  }

  /// Gets a list of all inputs matching the [action], as well as
  /// its [Builder]s primary inputs.
  ///
  /// Lazily builds any optional build actions that might potentially produce
  /// a primary input to [action].
  Future<Set<AssetId>> _matchingPrimaryInputs(BuildAction action,
      int phaseNumber, ResourceManager resourceManager) async {
    var ids = new Set<AssetId>();
    var builder = action.builder;
    await Future
        .wait(_assetGraph.packageNodes(action.package).map((node) async {
      if (!node.isValidInput) return;
      if (!action.matches(node.id)) return;
      if (!builder.buildExtensions.keys
          .any((inputExtension) => node.id.path.endsWith(inputExtension))) {
        return;
      }
      if (node is GeneratedAssetNode) {
        if (node.phaseNumber >= phaseNumber) return;
        if (node.isHidden && !action.hideOutput) return;
        if (node.needsUpdate) {
          await _runLazyPhaseForInput(node.phaseNumber, node.isHidden,
              node.primaryInput, resourceManager);
        }
        if (!node.wasOutput) return;
      }
      ids.add(node.id);
    }));
    return ids;
  }

  /// Runs a normal [builder] with [primaryInputs] as inputs and returns only
  /// the outputs that were newly created.
  ///
  /// Does not return outputs that didn't need to be re-ran or were declared
  /// but not output.
  Future<Iterable<AssetId>> _runBuilder(
      int phaseNumber,
      bool outputsHidden,
      Builder builder,
      Iterable<AssetId> primaryInputs,
      ResourceManager resourceManager) async {
    var outputLists = await Future.wait(primaryInputs.map((input) =>
        _runForInput(
            phaseNumber, outputsHidden, builder, input, resourceManager)));
    return outputLists.fold<List<AssetId>>(
        <AssetId>[], (combined, next) => combined..addAll(next));
  }

  /// Lazily runs [phaseNumber] with [input] and [resourceManager].
  Future<Iterable<AssetId>> _runLazyPhaseForInput(int phaseNumber,
      bool outputsHidden, AssetId input, ResourceManager resourceManager) {
    return _lazyPhases.putIfAbsent('$phaseNumber|$input', () async {
      // First check if `input` is generated, and whether or not it was
      // actually output. If it wasn't then we just return an empty list here.
      var inputNode = _assetGraph.get(input);
      if (inputNode is GeneratedAssetNode) {
        // Make sure the `inputNode` is up to date, and rebuild it if not.
        if (inputNode.needsUpdate) {
          await _runLazyPhaseForInput(inputNode.phaseNumber, inputNode.isHidden,
              inputNode.primaryInput, resourceManager);
        }
        if (!inputNode.wasOutput) return <AssetId>[];
      }

      var action = _buildActions[phaseNumber];

      return _runForInput(
          phaseNumber, outputsHidden, action.builder, input, resourceManager);
    });
  }

  Future<Iterable<AssetId>> _runForInput(int phaseNumber, bool outputsHidden,
      Builder builder, AssetId input, ResourceManager resourceManager) async {
    var tracker = _performanceTracker.startBuilderAction(input, builder);

    var builderOutputs = expectedOutputs(builder, input);

    // Add `builderOutputs` to the primary outputs of the input.
    var inputNode = _assetGraph.get(input);
    assert(inputNode != null,
        'Inputs should be known in the static graph. Missing $input');
    assert(
        inputNode.primaryOutputs.containsAll(builderOutputs),
        'input $input with builder $builder missing primary outputs: \n' +
            'Got ${inputNode.primaryOutputs.join(', ')} which was missing:\n' +
            builderOutputs
                .where((id) => !inputNode.primaryOutputs.contains(id))
                .join(', '));

    var wrappedReader = new SingleStepReader(
        _reader,
        _assetGraph,
        phaseNumber,
        outputsHidden,
        input.package,
        (phase, input) => _runLazyPhaseForInput(
            phase, outputsHidden, input, resourceManager));

    if (!await tracker.track(
        () => _buildShouldRun(builderOutputs, wrappedReader), 'Setup')) {
      tracker.stop();
      return <AssetId>[];
    }

    await _cleanUpStaleOutputs(builderOutputs);

    // We may have read some inputs in the call to `_buildShouldRun`, we want
    // to remove those.
    wrappedReader.assetsRead.clear();

    var wrappedWriter = new AssetWriterSpy(_writer);
    var logger = new ErrorRecordingLogger(new Logger('$builder on $input'));
    numActionsStarted++;
    await tracker.track(
        () => runBuilder(builder, [input], wrappedReader, wrappedWriter,
            new PerformanceTrackingResolvers(_resolvers, tracker),
            logger: logger, resourceManager: resourceManager),
        'Build');
    numActionsCompleted++;
    if (logger.errorWasSeen) {
      _assetGraph.markActionFailed(phaseNumber, input);
    } else {
      _assetGraph.markActionSucceeded(phaseNumber, input);
    }

    // Reset the state for all the `builderOutputs` nodes based on what was
    // read and written.
    await tracker.track(
        () => _setOutputsState(builderOutputs, wrappedReader, wrappedWriter),
        'Finalize');

    tracker.stop();
    return wrappedWriter.assetsWritten;
  }

  /// Checks and returns whether any [outputs] need to be updated.
  Future<bool> _buildShouldRun(
      Iterable<AssetId> outputs, AssetReader reader) async {
    assert(
        outputs.every(_assetGraph.contains),
        'Outputs should be known statically. Missing '
        '${outputs.where((o) => !_assetGraph.contains(o)).toList()}');
    assert(outputs.isNotEmpty, 'Can\'t run a build with no outputs');
    var firstOutput = outputs.first;
    var node = _assetGraph.get(firstOutput) as GeneratedAssetNode;
    assert(
        outputs.skip(1).every((output) =>
            (_assetGraph.get(output) as GeneratedAssetNode)
                .inputs
                .difference(node.inputs)
                .isEmpty),
        'All outputs of a build action should share the same inputs.');

    // We only check the first output, because all outputs share the same inputs
    // and invalidation state.
    if (!node.needsUpdate) return false;
    // TODO: Don't assume the worst for globs
    // https://github.com/dart-lang/build/issues/624
    if (node.previousInputsDigest == null || node.globs.isNotEmpty) {
      return true;
    }
    var digest = await _computeCombinedDigest(
        node.inputs, node.builderOptionsId, reader);
    if (digest != node.previousInputsDigest) {
      return true;
    } else {
      // Make sure to update the `needsUpdate` field for all outputs.
      for (var id in outputs) {
        (_assetGraph.get(id) as GeneratedAssetNode).needsUpdate = false;
      }
      return false;
    }
  }

  /// Deletes any of [outputs] which previously were output.
  ///
  /// This should be called after deciding that an asset really needs to be
  /// regenerated based on its inputs hash changing.
  Future<Null> _cleanUpStaleOutputs(Iterable<AssetId> outputs) async {
    await Future.wait(outputs.map((output) {
      var node = _assetGraph.get(output) as GeneratedAssetNode;
      if (node.wasOutput) return _delete(output);
      return new Future.value(null);
    }));
  }

  /// Computes a single [Digest] based on the combined [Digest]s of [ids] and
  /// [builderOptionsId].
  Future<Digest> _computeCombinedDigest(Iterable<AssetId> ids,
      AssetId builderOptionsId, AssetReader reader) async {
    var digestSink = new AccumulatorSink<Digest>();
    var bytesSink = md5.startChunkedConversion(digestSink);

    var builderOptionsNode = _assetGraph.get(builderOptionsId);
    bytesSink.add(builderOptionsNode.lastKnownDigest.bytes);

    for (var id in ids) {
      var node = _assetGraph.get(id);
      if (!await reader.canRead(id)) {
        // We want to add something here, a missing/unreadable input should be
        // different from no input at all.
        bytesSink.add([1]);
        continue;
      }
      node.lastKnownDigest ??= await reader.digest(id);
      bytesSink.add(node.lastKnownDigest.bytes);
    }

    bytesSink.close();
    assert(digestSink.events.length == 1);
    return digestSink.events.first;
  }

  /// Sets the state for all [declaredOutputs] of a build step, by:
  ///
  /// - Setting `needsUpdate` to `false` for each output
  /// - Setting `wasOutput` based on `writer.assetsWritten`.
  /// - Setting `globs` on each output based on `reader.globsRan`
  /// - Adding `declaredOutputs` as outputs to all `reader.assetsRead`.
  /// - Setting the `lastKnownDigest` on each output based on the new contents.
  /// - Setting the `previousInputsDigest` on each output based on the inputs.
  Future<Null> _setOutputsState(Iterable<AssetId> declaredOutputs,
      SingleStepReader reader, AssetWriterSpy writer) async {
    // All inputs are the same, so we only compute this once, but lazily.
    Digest inputsDigest;
    Set<Glob> globsRan = reader.globsRan.toSet();

    for (var output in declaredOutputs) {
      var wasOutput = writer.assetsWritten.contains(output);
      var digest = wasOutput ? await _reader.digest(output) : null;
      var node = _assetGraph.get(output) as GeneratedAssetNode;

      inputsDigest ??= await () {
        var allInputs = reader.assetsRead.toSet();
        if (node.primaryInput != null) allInputs.add(node.primaryInput);
        return _computeCombinedDigest(allInputs, node.builderOptionsId, reader);
      }();

      // **IMPORTANT**: All updates to `node` must be synchronous. With lazy
      // builders we can run arbitrary code between updates otherwise, at which
      // time a node might not be in a valid state.
      _removeOldInputs(node, reader.assetsRead);
      _addNewInputs(node, reader.assetsRead);
      node
        ..needsUpdate = false
        ..wasOutput = wasOutput
        ..lastKnownDigest = digest
        ..globs = globsRan
        ..previousInputsDigest = inputsDigest;
    }
  }

  /// Removes old inputs from [node] based on [updatedInputs], and cleans up all
  /// the old edges.
  void _removeOldInputs(GeneratedAssetNode node, Set<AssetId> updatedInputs) {
    var removedInputs = node.inputs.difference(updatedInputs);
    node.inputs.removeAll(removedInputs);
    for (var input in removedInputs) {
      // TODO: special type of dependency here? This means the primary input
      // was never actually read.
      if (input == node.primaryInput) continue;

      var inputNode = _assetGraph.get(input);
      assert(inputNode != null, 'Asset Graph is missing $input');
      inputNode.outputs.remove(node.id);
    }
  }

  /// Adds new inputs to [node] based on [updatedInputs], and adds the
  /// appropriate edges.
  void _addNewInputs(GeneratedAssetNode node, Set<AssetId> updatedInputs) {
    var newInputs = updatedInputs.difference(node.inputs);
    node.inputs.addAll(newInputs);
    for (var input in newInputs) {
      var inputNode = _assetGraph.get(input);
      assert(inputNode != null, 'Asset Graph is missing $input');
      inputNode.outputs.add(node.id);
    }
  }

  Future _delete(AssetId id) {
    _onDelete?.call(id);
    return _writer.delete(id);
  }
}
