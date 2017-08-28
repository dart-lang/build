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
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';
import '../util/constants.dart';
import 'build_definition.dart';
import 'build_result.dart';
import 'exceptions.dart';
import 'input_set.dart';
import 'options.dart';
import 'phase.dart';

/// Class which manages running builds.
class BuildImpl {
  final AssetId _assetGraphId;
  final List<BuildAction> _buildActions;
  final bool _deleteFilesByDefault;
  final _logger = new Logger('Build');
  final PackageGraph _packageGraph;
  final RunnerAssetReader _reader;
  final RunnerAssetWriter _writer;
  final Resolvers _resolvers = const BarbackResolvers();
  final BuildDefinitionLoader _buildDefinitionLoader;

  AssetGraph _assetGraph;
  AssetGraph get assetGraph => _assetGraph;
  bool _buildRunning = false;

  BuildImpl(BuildOptions options, List<BuildAction> buildActions)
      : _assetGraphId =
            new AssetId(options.packageGraph.root.name, assetGraphPath),
        _deleteFilesByDefault = options.deleteFilesByDefault,
        _packageGraph = options.packageGraph,
        _reader = options.reader,
        _writer = options.writer,
        _buildActions = buildActions,
        _buildDefinitionLoader = new BuildDefinitionLoader(
            options.reader, options.packageGraph, buildActions);

  /// Runs a build
  ///
  /// The returned [Future] is guaranteed to complete with a [BuildResult]. If
  /// an exception is thrown by any phase, [BuildResult#status] will be set to
  /// [BuildStatus.failure]. The exception and stack trace that caused the failure
  /// will be available as [BuildResult#exception] and [BuildResult#stackTrace]
  /// respectively.
  Future<BuildResult> runBuild({Map<AssetId, ChangeType> updates}) async {
    updates ??= <AssetId, ChangeType>{};
    var watch = new Stopwatch()..start();
    var result = await _safeBuild(updates);
    _buildRunning = false;
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

  /// Runs a build inside a zone with an error handler and stack chain
  /// capturing.
  Future<BuildResult> _safeBuild(Map<AssetId, ChangeType> updates) {
    var done = new Completer<BuildResult>();
    // Assume incremental, change if necessary.
    var buildType = BuildType.incremental;
    var buildStartTime = new DateTime.now();
    Chain.capture(() async {
      if (_buildRunning) throw const ConcurrentBuildException();
      _buildRunning = true;

      if (_buildActions.any(
          (action) => action.inputSet.package != _packageGraph.root.name)) {
        throw const InvalidBuildActionException.nonRootPackage();
      }

      // Initialize the [assetGraph] if its not yet set up.
      var buildDefinition = (_assetGraph == null)
          ? await _buildDefinitionLoader.load()
          : await _buildDefinitionLoader.fromGraph(_assetGraph, updates);
      _assetGraph = buildDefinition.assetGraph;
      buildType = buildDefinition.buildType;

      await logWithTime(_logger, 'Deleting previous outputs', () async {
        await Future.wait(buildDefinition.safeDeletes.map(_writer.delete));
        await _promptDelete(buildDefinition.conflictingAssets);
      });

      // Run a fresh build.
      var result = await logWithTime(_logger, 'Running build', _runPhases);

      // Write out the dependency graph file.
      await logWithTime(_logger, 'Caching finalized dependency graph',
          () async {
        _assetGraph.validAsOf = buildStartTime;
        await _writer.writeAsString(
            _assetGraphId, JSON.encode(_assetGraph.serialize()));
      });

      done.complete(result);
    }, onError: (e, Chain chain) {
      done.complete(new BuildResult(BuildStatus.failure, buildType, [],
          exception: e, stackTrace: chain.toTrace()));
    });
    return done.future;
  }

  Future<Null> _promptDelete(Set<AssetId> conflictingOutputs) async {
    if (conflictingOutputs.isEmpty) return;

    // Skip the prompt if using this option.
    if (_deleteFilesByDefault) {
      _logger.info('Deleting ${conflictingOutputs.length} declared outputs '
          'which already existed on disk.');
      await Future.wait(conflictingOutputs.map(_writer.delete));
      return;
    }

    // Prompt the user to delete files that are declared as outputs.
    _logger.warning('Found ${conflictingOutputs.length} declared outputs '
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
          await Future.wait(conflictingOutputs.map(_writer.delete));
          break;
        case 'n':
          throw new UnexpectedExistingOutputsException();
          break;
        case 'l':
          for (var output in conflictingOutputs) {
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
  Future<BuildResult> _runPhases() async {
    final outputs = <AssetId>[];
    var phaseNumber = 0;
    for (var action in _buildActions) {
      phaseNumber++;
      var inputs = _matchingInputs(action.inputSet, phaseNumber);
      await for (var output
          in _runBuilder(phaseNumber, action.builder, inputs)) {
        outputs.add(output);
      }
    }
    return new BuildResult(BuildStatus.success, BuildType.full, outputs);
  }

  Set<AssetId> _inputsForPhase(int phaseNumber) => _assetGraph.allNodes
      .where((n) =>
          n is! GeneratedAssetNode ||
          (n as GeneratedAssetNode).phaseNumber < phaseNumber)
      .map((n) => n.id)
      .toSet();

  /// Gets a list of all inputs matching [inputSet].
  Set<AssetId> _matchingInputs(InputSet inputSet, int phaseNumber) =>
      _inputsForPhase(phaseNumber)
          .where((input) =>
              input.package == inputSet.package &&
              inputSet.globs.any((g) => g.matches(input.path)))
          .toSet();

  /// Runs [builder] with [primaryInputs] as inputs.
  Stream<AssetId> _runBuilder(int phaseNumber, Builder builder,
      Iterable<AssetId> primaryInputs) async* {
    for (var input in primaryInputs) {
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
      if (skipBuild) continue;

      var reader = new SinglePhaseReader(
          _reader, _assetGraph, phaseNumber, _packageGraph.root.name);
      var writer = new AssetWriterSpy(_writer);
      await runBuilder(builder, [input], reader, writer, _resolvers);

      // Mark all outputs as no longer needing an update, and mark `wasOutput`
      // as `false` for now (this will get reset to true later one).
      for (var output in builderOutputs) {
        (_assetGraph.get(output) as GeneratedAssetNode)
          ..needsUpdate = false
          ..wasOutput = false;
      }

      // Update the asset graph based on the dependencies discovered.
      for (var dependency in reader.assetsRead) {
        var dependencyNode = _assetGraph.get(dependency);
        assert(dependencyNode != null, 'Asset Graph is missing $dependency');
        // We care about all builderOutputs, not just real outputs. Updates
        // to dependencies may cause a file to be output which wasn't before.
        dependencyNode.outputs.addAll(builderOutputs);
      }

      // Yield the outputs.
      for (var output in writer.assetsWritten) {
        (_assetGraph.get(output) as GeneratedAssetNode).wasOutput = true;
        yield output;
      }
    }
  }
}
