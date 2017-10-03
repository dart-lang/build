// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_barback/build_barback.dart' show BarbackResolvers;
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:watcher/watcher.dart';

import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../builder/optional_builder.dart';
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';
import '../util/constants.dart';
import 'build_definition.dart';
import 'build_result.dart';
import 'exceptions.dart';
import 'fold_frames.dart';
import 'input_set.dart';
import 'options.dart';
import 'performance_tracker.dart';
import 'phase.dart';

final _logger = new Logger('Build');

Future<BuildResult> singleBuild(
    BuildOptions options, List<BuildAction> buildActions) async {
  var buildDefinition = await BuildDefinition.load(options, buildActions);
  return (await BuildImpl.create(buildDefinition, buildActions)).firstBuild;
}

typedef void _OnDelete(AssetId id);

class BuildImpl {
  BuildResult _firstBuild;
  BuildResult get firstBuild => _firstBuild;

  final List<BuildAction> _buildActions;
  final PackageGraph _packageGraph;
  final AssetReader _reader;
  final RunnerAssetWriter _writer;
  final _resolvers = const BarbackResolvers();
  final AssetGraph _assetGraph;

  final _OnDelete _onDelete;

  BuildImpl._(BuildDefinition buildDefinition, List<BuildAction> buildActions,
      this._onDelete)
      : _packageGraph = buildDefinition.packageGraph,
        _reader = buildDefinition.reader,
        _writer = buildDefinition.writer,
        _assetGraph = buildDefinition.assetGraph,
        _buildActions = buildActions;

  static Future<BuildImpl> create(
      BuildDefinition buildDefinition, List<BuildAction> buildActions,
      {void onDelete(AssetId id)}) async {
    var build = new BuildImpl._(buildDefinition, buildActions, onDelete);

    await logTimedAsync(
        _logger,
        'Checking for stale files',
        () => build._firstBuildCleanup(buildDefinition.conflictingAssets,
            buildDefinition.deleteFilesByDefault));

    build._firstBuild = await build.run(buildDefinition.updates);
    return build;
  }

  Future<BuildResult> run(Map<AssetId, ChangeType> updates) async {
    var watch = new Stopwatch()..start();
    _lazyPhases.clear();
    if (updates.isNotEmpty) {
      await logTimedAsync(
          _logger, 'Updating asset graph', () => _updateAssetGraph(updates));
    }
    var resourceManager = new ResourceManager();
    var result = await _safeBuild(resourceManager);
    await resourceManager.disposeAll();
    if (result.status == BuildStatus.success) {
      _logger.info('Succeeded after ${watch.elapsedMilliseconds}ms with '
          '${result.outputs.length} outputs\n\n');
    } else {
      if (result.exception is FatalBuildException) {
        // TODO(???) Really bad idea. Should not set exit codes in libraries!
        exitCode = 1;
      }
      _logger.severe('Failed after ${watch.elapsedMilliseconds}ms',
          result.exception, result.stackTrace);
    }
    return result;
  }

  Future<Null> _updateAssetGraph(Map<AssetId, ChangeType> updates) async {
    var deletes = _assetGraph.updateAndInvalidate(_buildActions, updates);
    await Future.wait(deletes.map(_delete));
  }

  /// Runs a build inside a zone with an error handler and stack chain
  /// capturing.
  Future<BuildResult> _safeBuild(ResourceManager resourceManager) {
    var done = new Completer<BuildResult>();
    var buildStartTime = new DateTime.now();
    Chain.capture(() async {
      // Run a fresh build.
      var result = await logTimedAsync(
          _logger, 'Running build', () => _runPhases(resourceManager));

      // Write out the dependency graph file.
      await logTimedAsync(_logger, 'Caching finalized dependency graph',
          () async {
        _assetGraph.validAsOf = buildStartTime;
        await _writer.writeAsString(
            new AssetId(_packageGraph.root.name, assetGraphPath),
            JSON.encode(_assetGraph.serialize()));
      });

      done.complete(result);
    }, onError: (e, Chain chain) {
      final trace = foldInternalFrames(chain.toTrace()).terse;
      done.complete(new BuildResult(BuildStatus.failure, [],
          exception: e, stackTrace: trace));
    });
    return done.future;
  }

  Future<Null> _firstBuildCleanup(
      Set<AssetId> conflictingAssets, bool deleteFilesByDefault) async {
    if (conflictingAssets.isEmpty) return;

    // Skip the prompt if using this option.
    if (deleteFilesByDefault) {
      _logger.info('Deleting ${conflictingAssets.length} declared outputs '
          'which already existed on disk.');
      await Future.wait(conflictingAssets.map(_delete));
      return;
    }

    // Prompt the user to delete files that are declared as outputs.
    _logger.info('Found ${conflictingAssets.length} declared outputs '
        'which already exist on disk. This is likely because the'
        '`$cacheDir` folder was deleted, or you are submitting generated '
        'files to your source repository.');

    // If not in a standard terminal then we just exit, since there is no way
    // for the user to provide a yes/no answer.
    if (stdioType(stdin) != StdioType.TERMINAL) {
      throw new UnexpectedExistingOutputsException();
    }

    // Give a little extra space after the last message, need to make it clear
    // this is a prompt.
    stdout.writeln();
    var done = false;
    while (!done) {
      stdout.write('\nDelete these files (y/n) (or list them (l))?: ');
      var input = stdin.readLineSync();
      switch (input.toLowerCase()) {
        case 'y':
          stdout.writeln('Deleting files...');
          done = true;
          await Future.wait(conflictingAssets.map(_delete));
          break;
        case 'n':
          throw new UnexpectedExistingOutputsException();
          break;
        case 'l':
          for (var output in conflictingAssets) {
            stdout.writeln(output);
          }
          break;
        default:
          stdout.writeln('Unrecognized option $input, (y/n/l) expected.');
      }
    }
  }

  /// Runs the actions in [_buildActions] and returns a [Future<BuildResult>]
  /// which completes once all [BuildAction]s are done.
  Future<BuildResult> _runPhases(ResourceManager resourceManager) async {
    var performanceTracker = new BuildPerformanceTracker()..start();
    final outputs = <AssetId>[];
    var phaseNumber = 0;
    for (var action in _buildActions) {
      phaseNumber++;
      if (action.builder is OptionalBuilder) continue;
      await performanceTracker.trackAction(action, () async {
        var inputs = await _matchingInputs(
            action.inputSet, phaseNumber, resourceManager);
        for (var output in await _runBuilder(
            phaseNumber, action.builder, inputs, resourceManager)) {
          outputs.add(output);
        }
      });
    }
    await Future.forEach(
        _lazyPhases.values,
        (Future<Iterable<AssetId>> lazyOuts) async =>
            outputs.addAll(await lazyOuts));
    return new BuildResult(BuildStatus.success, outputs,
        performance: performanceTracker..stop());
  }

  /// Gets a list of all inputs matching [inputSet].
  ///
  /// Lazily builds any [OptionalBuilder]s matching [inputSet].
  Future<Set<AssetId>> _matchingInputs(InputSet inputSet, int phaseNumber,
      ResourceManager resourceManager) async {
    var ids = new Set<AssetId>();
    for (var node in _assetGraph.allNodes) {
      if (!inputSet.matches(node.id)) continue;
      if (node is GeneratedAssetNode) {
        if (node.phaseNumber >= phaseNumber) continue;
        if (node.needsUpdate) {
          await runPhaseForInput(
              node.phaseNumber, node.primaryInput, resourceManager);
        }
        if (!node.wasOutput) continue;
      }
      ids.add(node.id);
    }
    return ids;
  }

  /// Runs [builder] with [primaryInputs] as inputs.
  Future<Iterable<AssetId>> _runBuilder(int phaseNumber, Builder builder,
      Iterable<AssetId> primaryInputs, ResourceManager resourceManager) async {
    var outputLists = await Future.wait(primaryInputs.map(
        (input) => _runForInput(phaseNumber, builder, input, resourceManager)));
    return outputLists.fold<List<AssetId>>(
        <AssetId>[], (combined, next) => combined..addAll(next));
  }

  final _lazyPhases = <String, Future<Iterable<AssetId>>>{};

  Future<Iterable<AssetId>> runPhaseForInput(
      int phaseNumber, AssetId input, ResourceManager resourceManager) async {
    return _lazyPhases.putIfAbsent('$phaseNumber|$input', () {
      // phase numbers start at 1 because..... they do
      var action = _buildActions[phaseNumber - 1];
      return _runForInput(phaseNumber, action.builder, input, resourceManager);
    });
  }

  Future<Iterable<AssetId>> _runForInput(int phaseNumber, Builder builder,
      AssetId input, ResourceManager resourceManager) async {
    var builderOutputs = expectedOutputs(builder, input);

    // Add nodes to the AssetGraph for builderOutputs and input.
    var inputNode = _assetGraph.get(input);
    assert(inputNode != null,
        'Inputs should be known in the static graph. Missing $input');
    for (var output in builderOutputs) {
      inputNode.outputs.add(output);
      assert(inputNode.primaryOutputs.contains(output),
          '$input missing primary output $output');
    }
    assert(
        builderOutputs.every((o) => _assetGraph.contains(o)),
        'Outputs should be known statically. Missing '
        '${builderOutputs.where((o) => !_assetGraph.contains(o)).toList()}');
    // Skip the build step if none of the outputs need updating.
    var skipBuild = !builderOutputs.any((output) =>
        (_assetGraph.get(output) as GeneratedAssetNode).needsUpdate);
    if (skipBuild) return <AssetId>[];
    var wrappedReader = new SinglePhaseReader(_reader, _assetGraph, phaseNumber,
        input.package, this, resourceManager);
    var wrappedWriter = new AssetWriterSpy(_writer);
    await runBuilder(builder, [input], wrappedReader, wrappedWriter, _resolvers,
        resourceManager: resourceManager);

    // Mark all outputs as no longer needing an update, and mark `wasOutput`
    // as `false` for now (this will get reset to true later one).
    //
    // Also tracks all the globs that were used during this build.
    for (var output in builderOutputs) {
      (_assetGraph.get(output) as GeneratedAssetNode)
        ..needsUpdate = false
        ..wasOutput = false
        ..globs = wrappedReader.globsRan.toSet();
    }

    // Update the asset graph based on the dependencies discovered.
    for (var dependency in wrappedReader.assetsRead) {
      var dependencyNode = _assetGraph.get(dependency);
      assert(dependencyNode != null, 'Asset Graph is missing $dependency');
      // We care about all builderOutputs, not just real outputs. Updates
      // to dependencies may cause a file to be output which wasn't before.
      dependencyNode.outputs.addAll(builderOutputs);
    }

    // Collect the outputs and mark them as output.
    var outputs = <AssetId>[];
    for (var output in wrappedWriter.assetsWritten) {
      (_assetGraph.get(output) as GeneratedAssetNode).wasOutput = true;
      outputs.add(output);
    }
    return outputs;
  }

  Future _delete(AssetId id) {
    _onDelete?.call(id);
    return _writer.delete(id);
  }
}
