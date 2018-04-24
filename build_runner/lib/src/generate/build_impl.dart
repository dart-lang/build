// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:watcher/watcher.dart';

import '../asset/cache.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../environment/build_environment.dart';
import '../environment/io_environment.dart';
import '../environment/overridable_environment.dart';
import '../logging/build_for_input_logger.dart';
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
  Map<String, String> outputMap,
  bool trackPerformance,
  bool verbose,
  Map<String, Map<String, dynamic>> builderConfigOverrides,
  bool isReleaseBuild,
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
      outputMap: outputMap,
      trackPerformance: trackPerformance,
      verbose: verbose);
  var terminator = new Terminator(terminateEventStream);

  final buildPhases = await createBuildPhases(
      targetGraph, builders, builderConfigOverrides, isReleaseBuild ?? false);

  var result = await singleBuild(environment, options, buildPhases);

  await terminator.cancel();
  await options.logListener.cancel();
  return result;
}

Future<BuildResult> singleBuild(BuildEnvironment environment,
    BuildOptions options, List<BuildPhase> buildPhases) async {
  var buildDefinition =
      await BuildDefinition.prepareWorkspace(environment, options, buildPhases);
  var result = (await BuildImpl.create(buildDefinition, options, buildPhases))
      .firstBuild;
  await buildDefinition.resourceManager.beforeExit();
  return result;
}

class BuildImpl {
  BuildResult _firstBuild;
  BuildResult get firstBuild => _firstBuild;

  final AssetGraph _assetGraph;
  final List<BuildPhase> _buildPhases;
  final bool _failOnSevere;
  final OnDelete _onDelete;
  final PackageGraph _packageGraph;
  final AssetReader _reader;
  final _resolvers = new AnalyzerResolvers();
  final ResourceManager _resourceManager;
  final RunnerAssetWriter _writer;
  final Map<String, String> _outputMap;
  final bool _trackPerformance;
  final bool _verbose;
  final BuildEnvironment _environment;

  BuildImpl._(
      BuildDefinition buildDefinition, BuildOptions options, this._buildPhases)
      : _packageGraph = buildDefinition.packageGraph,
        _reader = options.enableLowResourcesMode
            ? buildDefinition.reader
            : new CachingAssetReader(buildDefinition.reader),
        _writer = buildDefinition.writer,
        _assetGraph = buildDefinition.assetGraph,
        _resourceManager = buildDefinition.resourceManager,
        _onDelete = buildDefinition.onDelete,
        _outputMap = options.outputMap,
        _verbose = options.verbose,
        _failOnSevere = options.failOnSevere,
        _environment = buildDefinition.environment,
        _trackPerformance = options.trackPerformance;

  Future<BuildResult> run(Map<AssetId, ChangeType> updates) =>
      new _SingleBuild(this).run(updates)..whenComplete(_resolvers.reset);

  static Future<BuildImpl> create(BuildDefinition buildDefinition,
      BuildOptions options, List<BuildPhase> buildPhases,
      {void onDelete(AssetId id)}) async {
    var build = new BuildImpl._(buildDefinition, options, buildPhases);

    build._firstBuild = await build.run({});
    return build;
  }
}

/// Performs a single build and manages state that only lives for a single
/// build.
class _SingleBuild {
  final AssetGraph _assetGraph;
  final List<BuildPhase> _buildPhases;
  final BuildEnvironment _environment;
  final bool _failOnSevere;
  final _lazyPhases = <String, Future<Iterable<AssetId>>>{};
  final OnDelete _onDelete;
  final Map<String, String> _outputMap;
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
        _buildPhases = buildImpl._buildPhases,
        _environment = buildImpl._environment,
        _failOnSevere = buildImpl._failOnSevere,
        _onDelete = buildImpl._onDelete,
        _outputMap = buildImpl._outputMap,
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
    var result = await _safeBuild();
    await _resourceManager.disposeAll();
    if (_outputMap != null && result.status == BuildStatus.success) {
      if (!await createMergedOutputDirectories(_outputMap, _assetGraph,
          _packageGraph, _reader, _environment, _buildPhases)) {
        result = _convertToFailure(
            result, 'Failed to create merged output directories.',
            failureType: FailureType.cantCreate);
      }
    }
    if (result.status == BuildStatus.success) {
      _logger.info('Succeeded after ${humanReadable(watch.elapsed)} with '
          '${result.outputs.length} outputs ($numActionsCompleted actions)\n');
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

  BuildResult _convertToFailure(BuildResult previous, String errorMessge,
          {FailureType failureType}) =>
      new BuildResult(
        BuildStatus.failure,
        previous.outputs,
        exception: errorMessge,
        performance: previous.performance,
        failureType: failureType,
      );

  Future<Null> _updateAssetGraph(Map<AssetId, ChangeType> updates) async {
    await logTimedAsync(_logger, 'Updating asset graph', () async {
      var invalidated = await _assetGraph.updateAndInvalidate(
          _buildPhases, updates, _packageGraph.root.name, _delete, _reader);
      if (_reader is CachingAssetReader) {
        (_reader as CachingAssetReader).invalidate(invalidated);
      }
    });
  }

  /// Runs a build inside a zone with an error handler and stack chain
  /// capturing.
  Future<BuildResult> _safeBuild() {
    var done = new Completer<BuildResult>();

    var heartbeat = new HeartbeatLogger(
        transformLog: (original) => '$original, ${_buildProgress()}',
        waitDuration: new Duration(seconds: 1))
      ..start();
    done.future.then((_) {
      heartbeat.stop();
    });
    runZoned(() async {
      // Run a fresh build.
      var result = await logTimedAsync(_logger, 'Running build', _runPhases);

      // Write out the dependency graph file.
      await logTimedAsync(_logger, 'Caching finalized dependency graph',
          () async {
        await _writer.writeAsBytes(
            new AssetId(_packageGraph.root.name, assetGraphPath),
            _assetGraph.serialize());
      });

      if (!done.isCompleted) done.complete(result);
    }, onError: (e, StackTrace st) {
      if (!done.isCompleted) {
        done.complete(new BuildResult(BuildStatus.failure, [],
            exception: e, stackTrace: st));
      }
    });
    return done.future;
  }

  /// Returns a message describing the progress of the current build.
  String _buildProgress() =>
      '$numActionsCompleted/$numActionsStarted actions completed.';

  /// Runs the actions in [_buildPhases] and returns a [Future<BuildResult>]
  /// which completes once all [BuildPhase]s are done.
  Future<BuildResult> _runPhases() async {
    _performanceTracker.start();
    final outputs = <AssetId>[];
    for (var phaseNum = 0; phaseNum < _buildPhases.length; phaseNum++) {
      var phase = _buildPhases[phaseNum];
      if (phase.isOptional) continue;
      await _performanceTracker.trackBuildPhase(phase, () async {
        if (phase is InBuildPhase) {
          var primaryInputs =
              await _matchingPrimaryInputs(phase.package, phaseNum);
          outputs.addAll(await _runBuilder(phaseNum, phase, primaryInputs));
        } else if (phase is PostBuildPhase) {
          outputs.addAll(await _runPostProcessPhase(phaseNum, phase));
        } else {
          throw new StateError('Unrecognized BuildPhase type $phase');
        }
      });
    }
    await Future.forEach(
        _lazyPhases.values,
        (Future<Iterable<AssetId>> lazyOuts) async =>
            outputs.addAll(await lazyOuts));
    final status = _assetGraph.failedOutputs.isEmpty
        ? BuildStatus.success
        : BuildStatus.failure;
    return new BuildResult(status, outputs,
        performance: _performanceTracker..stop());
  }

  /// Gets a list of all inputs matching the [phaseNumber], as well as
  /// its [Builder]s primary inputs.
  ///
  /// Lazily builds any optional build actions that might potentially produce
  /// a primary input to this phase.
  Future<Set<AssetId>> _matchingPrimaryInputs(
      String package, int phaseNumber) async {
    var ids = new Set<AssetId>();
    await Future.wait(
        _assetGraph.outputsForPhase(package, phaseNumber).map((node) async {
      var input = _assetGraph.get(node.primaryInput);
      if (input is GeneratedAssetNode) {
        if (input.state != GeneratedNodeState.upToDate) {
          await _runLazyPhaseForInput(input.phaseNumber, input.primaryInput);
        }
        if (!input.wasOutput) return;
        if (input.isFailure) return;
      }
      ids.add(input.id);
    }));
    return ids;
  }

  /// Runs a normal builder with [primaryInputs] as inputs and returns only the
  /// outputs that were newly created.
  ///
  /// Does not return outputs that didn't need to be re-ran or were declared
  /// but not output.
  Future<Iterable<AssetId>> _runBuilder(int phaseNumber, InBuildPhase action,
      Iterable<AssetId> primaryInputs) async {
    var outputLists = await Future.wait(
        primaryInputs.map((input) => _runForInput(phaseNumber, action, input)));
    return outputLists.fold<List<AssetId>>(
        <AssetId>[], (combined, next) => combined..addAll(next));
  }

  /// Lazily runs [phaseNumber] with [input]..
  Future<Iterable<AssetId>> _runLazyPhaseForInput(
      int phaseNumber, AssetId input) {
    return _lazyPhases.putIfAbsent('$phaseNumber|$input', () async {
      // First check if `input` is generated, and whether or not it was
      // actually output. If it wasn't then we just return an empty list here.
      var inputNode = _assetGraph.get(input);
      if (inputNode is GeneratedAssetNode) {
        // Make sure the `inputNode` is up to date, and rebuild it if not.
        if (inputNode.state != GeneratedNodeState.upToDate) {
          await _runLazyPhaseForInput(
              inputNode.phaseNumber, inputNode.primaryInput);
        }
        if (!inputNode.wasOutput || inputNode.isFailure) return <AssetId>[];
      }

      // We can never lazily build `PostProcessBuildAction`s.
      var action = _buildPhases[phaseNumber] as InBuildPhase;

      return _runForInput(phaseNumber, action, input);
    });
  }

  Future<Iterable<AssetId>> _runForInput(
      int phaseNumber, InBuildPhase phase, AssetId input) async {
    final builder = phase.builder;
    final outputsHidden = phase.hideOutput;
    var tracker = _performanceTracker.startBuilderAction(input, builder);

    var builderOutputs = expectedOutputs(builder, input);

    // Add `builderOutputs` to the primary outputs of the input.
    var inputNode = _assetGraph.get(input);
    assert(inputNode != null,
        'Inputs should be known in the static graph. Missing $input');
    assert(
        inputNode.primaryOutputs.containsAll(builderOutputs),
        'input $input with builder $builder missing primary outputs: \n'
            'Got ${inputNode.primaryOutputs.join(', ')} which was missing:\n' +
            builderOutputs
                .where((id) => !inputNode.primaryOutputs.contains(id))
                .join(', '));

    var wrappedReader = new SingleStepReader(_reader, _assetGraph, phaseNumber,
        outputsHidden, input.package, _runLazyPhaseForInput);

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
    var logger = new BuildForInputLogger(
        new Logger(_actionLoggerName(phase, input, _packageGraph.root.name)));
    numActionsStarted++;
    var errorThrown = false;
    await tracker.track(
        () => runBuilder(builder, [input], wrappedReader, wrappedWriter,
                new PerformanceTrackingResolvers(_resolvers, tracker),
                logger: logger, resourceManager: _resourceManager)
            .catchError((_) => errorThrown = true),
        'Build');
    numActionsCompleted++;

    // Reset the state for all the `builderOutputs` nodes based on what was
    // read and written.
    await tracker.track(
        () => _setOutputsState(builderOutputs, wrappedReader, wrappedWriter,
            (logger.errorWasSeen && _failOnSevere) || errorThrown),
        'Finalize');

    tracker.stop();
    return wrappedWriter.assetsWritten;
  }

  Future<Iterable<AssetId>> _runPostProcessPhase(
      int phaseNum, PostBuildPhase phase) async {
    var actionNum = 0;
    var outputLists = await Future.wait(phase.builderActions
        .map((action) => _runPostProcessAction(phaseNum, actionNum++, action)));
    return outputLists.fold<List<AssetId>>(
        <AssetId>[], (combined, next) => combined..addAll(next));
  }

  Future<Iterable<AssetId>> _runPostProcessAction(
      int phaseNum, int actionNum, PostBuildAction action) async {
    var anchorNodes = _assetGraph.packageNodes(action.package).where((node) {
      if (node is PostProcessAnchorNode && node.actionNumber == actionNum) {
        var inputNode = _assetGraph.get(node.primaryInput);
        if (inputNode is SourceAssetNode) {
          return true;
        } else if (inputNode is GeneratedAssetNode) {
          return inputNode.wasOutput &&
              !inputNode.isFailure &&
              inputNode.state == GeneratedNodeState.upToDate;
        }
      }
      return false;
    }).cast<PostProcessAnchorNode>();
    var outputLists = await Future.wait(anchorNodes.map((anchorNode) =>
        _runPostProcessBuilderForAnchor(
            phaseNum, actionNum, action.builder, anchorNode)));
    return outputLists.fold<List<AssetId>>(
        <AssetId>[], (combined, next) => combined..addAll(next));
  }

  Future<Iterable<AssetId>> _runPostProcessBuilderForAnchor(
      int phaseNum,
      int actionNum,
      PostProcessBuilder builder,
      PostProcessAnchorNode anchorNode) async {
    var input = anchorNode.primaryInput;
    var inputNode = _assetGraph.get(input);
    assert(inputNode != null,
        'Inputs should be known in the static graph. Missing $input');

    var wrappedReader = new SingleStepReader(
        _reader, _assetGraph, phaseNum, true, input.package, null);

    if (!await _postProcessBuildShouldRun(anchorNode, wrappedReader)) {
      return <AssetId>[];
    }
    // We may have read some inputs in the call to `_buildShouldRun`, we want
    // to remove those.
    wrappedReader.assetsRead.clear();

    // Delete old assets from disk.
    await _cleanUpStaleOutputs(anchorNode.outputs);

    // Remove old nodes from the graph and clear `outputs`.
    anchorNode.outputs.toList().forEach(_assetGraph.remove);
    anchorNode.outputs.clear();

    var wrappedWriter = new AssetWriterSpy(_writer);
    var logger = new BuildForInputLogger(new Logger('$builder on $input'));

    numActionsStarted++;
    var errorThrown = false;
    await runPostProcessBuilder(
        builder, input, wrappedReader, wrappedWriter, logger,
        addAsset: (assetId) {
      if (_assetGraph.contains(assetId)) {
        throw new InvalidOutputException(assetId, 'Asset already exists');
      }
      var node = new GeneratedAssetNode(assetId,
          primaryInput: input,
          builderOptionsId: anchorNode.builderOptionsId,
          isHidden: true,
          phaseNumber: phaseNum,
          wasOutput: true,
          isFailure: false,
          state: GeneratedNodeState.upToDate);
      _assetGraph.add(node);
      anchorNode.outputs.add(assetId);
    }, deleteAsset: (assetId) {
      if (!_assetGraph.contains(assetId)) {
        throw new AssetNotFoundException(assetId);
      }
      _assetGraph.get(assetId).isDeleted = true;
    }).catchError((_) => errorThrown = true);
    numActionsCompleted++;

    var assetsWritten = wrappedWriter.assetsWritten.toSet();

    // Reset the state for all the output nodes based on what was read and
    // written.
    inputNode.primaryOutputs.addAll(assetsWritten);
    await _setOutputsState(assetsWritten, wrappedReader, wrappedWriter,
        (logger.errorWasSeen && _failOnSevere) || errorThrown);

    return assetsWritten;
  }

  /// Checks and returns whether any [outputs] need to be updated.
  Future<bool> _buildShouldRun(
      Iterable<AssetId> outputs, AssetReader reader) async {
    assert(
        outputs.every(_assetGraph.contains),
        'Outputs should be known statically. Missing '
        '${outputs.where((o) => !_assetGraph.contains(o)).toList()}');
    assert(outputs.isNotEmpty, 'Can\'t run a build with no outputs');

    // We only check the first output, because all outputs share the same inputs
    // and invalidation state.
    var firstOutput = outputs.first;
    var node = _assetGraph.get(firstOutput) as GeneratedAssetNode;
    assert(
        outputs.skip(1).every((output) =>
            (_assetGraph.get(output) as GeneratedAssetNode)
                .inputs
                .difference(node.inputs)
                .isEmpty),
        'All outputs of a build action should share the same inputs.');

    // No need to build an up to date output
    if (node.state == GeneratedNodeState.upToDate) return false;
    // Early bail out condition, this is a forced update.
    if (node.state == GeneratedNodeState.definitelyNeedsUpdate) return true;
    // This is a fresh build or the first time we've seen this output.
    if (node.previousInputsDigest == null) return true;

    var digest = await _computeCombinedDigest(
        node.inputs, node.builderOptionsId, reader);
    if (digest != node.previousInputsDigest) {
      return true;
    } else {
      // Make sure to update the `state` field for all outputs.
      for (var id in outputs) {
        (_assetGraph.get(id) as GeneratedAssetNode).state =
            GeneratedNodeState.upToDate;
      }
      return false;
    }
  }

  /// Checks if a post process build should run based on [anchorNode].
  Future<bool> _postProcessBuildShouldRun(
      PostProcessAnchorNode anchorNode, AssetReader reader) async {
    var inputsDigest = await _computeCombinedDigest(
        [anchorNode.primaryInput], anchorNode.builderOptionsId, reader);

    if (inputsDigest != anchorNode.previousInputsDigest) {
      anchorNode.previousInputsDigest = inputsDigest;
      return true;
    }

    return false;
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

  /// Sets the state for all [outputs] of a build step, by:
  ///
  /// - Setting `needsUpdate` to `false` for each output
  /// - Setting `wasOutput` based on `writer.assetsWritten`.
  /// - Setting `isFailed` based on action success.
  /// - Setting `globs` on each output based on `reader.globsRan`
  /// - Adding `outputs` as outputs to all `reader.assetsRead`.
  /// - Setting the `lastKnownDigest` on each output based on the new contents.
  /// - Setting the `previousInputsDigest` on each output based on the inputs.
  Future<Null> _setOutputsState(Iterable<AssetId> outputs,
      SingleStepReader reader, AssetWriterSpy writer, bool isFailure) async {
    if (outputs.isEmpty) return;

    final inputsDigest = await _computeCombinedDigest(
        reader.assetsRead,
        (_assetGraph.get(outputs.first) as GeneratedAssetNode).builderOptionsId,
        reader);
    final globsRan = reader.globsRan.toSet();

    for (var output in outputs) {
      var wasOutput = writer.assetsWritten.contains(output);
      var digest = wasOutput ? await _reader.digest(output) : null;
      var node = _assetGraph.get(output) as GeneratedAssetNode;

      // **IMPORTANT**: All updates to `node` must be synchronous. With lazy
      // builders we can run arbitrary code between updates otherwise, at which
      // time a node might not be in a valid state.
      _removeOldInputs(node, reader.assetsRead);
      _addNewInputs(node, reader.assetsRead);
      node
        ..state = GeneratedNodeState.upToDate
        ..wasOutput = wasOutput
        ..isFailure = isFailure
        ..lastKnownDigest = digest
        ..globs = globsRan
        ..previousInputsDigest = inputsDigest;

      if (isFailure) {
        var needsMarkAsFailure = new Queue.of(node.primaryOutputs);
        while (needsMarkAsFailure.isNotEmpty) {
          var output = needsMarkAsFailure.removeLast();
          var outputNode = _assetGraph.get(output) as GeneratedAssetNode;
          outputNode
            ..state = GeneratedNodeState.upToDate
            ..wasOutput = false
            ..isFailure = true
            ..lastKnownDigest = null
            ..globs = new Set()
            ..previousInputsDigest = null;
          needsMarkAsFailure.addAll(outputNode.primaryOutputs);
        }
      }
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

String _actionLoggerName(
    InBuildPhase phase, AssetId primaryInput, String rootPackageName) {
  var asset = primaryInput.package == rootPackageName
      ? primaryInput.path
      : primaryInput.uri;
  return '${phase.builderLabel} on $asset';
}
