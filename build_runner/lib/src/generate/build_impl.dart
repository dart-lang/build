// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:build/build.dart';
import 'package:build_barback/build_barback.dart' show BarbackResolvers;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:watcher/watcher.dart';

import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/exceptions.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';
import '../util/constants.dart';
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

  AssetGraph _assetGraph;
  AssetGraph get assetGraph => _assetGraph;
  bool _buildRunning = false;
  bool _isFirstBuild = true;

  BuildImpl(BuildOptions options, this._buildActions)
      : _assetGraphId =
            new AssetId(options.packageGraph.root.name, assetGraphPath),
        _deleteFilesByDefault = options.deleteFilesByDefault,
        _packageGraph = options.packageGraph,
        _reader = options.reader,
        _writer = options.writer;

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
    _isFirstBuild = false;
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
    var validAsOf = new DateTime.now();
    Chain.capture(() async {
      if (_buildRunning) throw const ConcurrentBuildException();
      _buildRunning = true;

      if (_buildActions.any(
          (action) => action.inputSet.package != _packageGraph.root.name)) {
        throw const InvalidBuildActionException.nonRootPackage();
      }

      // Initialize the [assetGraph] if its not yet set up.
      if (_assetGraph == null) {
        await logWithTime(_logger, 'Reading cached dependency graph', () async {
          _assetGraph = await _readAssetGraph();
          if (_assetGraph == null) {
            buildType = BuildType.full;
          } else {
            /// Collect updates since the asset graph was last created. This only
            /// handles updates and deletes, not adds. We list the file system for
            /// all inputs later on (in [_initializeInputsByPackage]).
            updates.addAll(await _getUpdates());
          }
        });
      }

      // If the build script gets updated, we need to either fully invalidate
      // the graph (if the script current running is up to date), or we need to
      // terminate and ask the user to restart the script (if the currently
      // running script is out of date).
      //
      // The [_isFirstBuild] flag is used as a proxy for "has this script been
      // updated since it started running".
      if (_assetGraph != null) {
        await logWithTime(_logger, 'Checking build script for updates',
            () async {
          if (await _buildScriptUpdated()) {
            buildType = BuildType.full;
            if (_isFirstBuild) {
              _logger.warning(
                  'Invalidating asset graph due to build script update');
              _assetGraph = null;
            } else {
              done.complete(new BuildResult(BuildStatus.failure, buildType, [],
                  exception: new BuildScriptUpdatedException()));
            }
          }
        });
        // Bail if the previous step completed the build.
        if (done.isCompleted) return;
      }

      await logWithTime(_logger, 'Finalizing build setup', () async {
        // Wait while all inputs are collected.
        _logger.info('Initializing inputs');
        var currentSources = await _initializeInputsByPackage();

        if (_assetGraph != null) {
          await _writer.delete(_assetGraphId);
          _logger
              .info('Updating dependency graph with changes since last build.');
          _assetGraph.updateForSources(_buildActions, currentSources);
          await _updateWithChanges(updates);
        }

        // Delete all previous outputs!
        _logger.info('Deleting previous outputs');
        await _deletePreviousOutputs(currentSources);
      });

      // Run a fresh build.
      var result = await logWithTime(_logger, 'Running build', _runPhases);

      // Write out the dependency graph file.
      await logWithTime(_logger, 'Caching finalized dependency graph',
          () async {
        _assetGraph.validAsOf = validAsOf;
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

  /// Reads in the [assetGraph] from disk.
  Future<AssetGraph> _readAssetGraph() async {
    if (!await _reader.canRead(_assetGraphId)) return null;
    try {
      return new AssetGraph.deserialize(
          JSON.decode(await _reader.readAsString(_assetGraphId)) as Map);
    } on AssetGraphVersionException catch (_) {
      // Start fresh if the cached asset_graph version doesn't match up with
      // the current version. We don't currently support old graph versions.
      _logger.info('Throwing away cached asset graph due to version mismatch.');
      return null;
    }
  }

  /// Checks if the current running program has been updated since the asset
  /// graph was last built.
  ///
  /// TODO(jakemac): Come up with a better way of telling if the script
  /// has been updated since it started running.
  Future<bool> _buildScriptUpdated() async {
    var completer = new Completer<bool>();
    // ignore: unawaited_futures
    Future
        .wait(currentMirrorSystem().libraries.keys.map((Uri uri) async {
      // Short-circuit
      if (completer.isCompleted) return;
      DateTime lastModified;
      switch (uri.scheme) {
        case 'dart':
          return;
        case 'package':
          var parts = uri.pathSegments;
          var id = new AssetId(
              parts[0],
              path.url
                  .joinAll(['lib']..addAll(parts.getRange(1, parts.length))));
          lastModified = await _reader.lastModified(id);
          break;
        case 'file':

          // TODO(jakemac): Probably shouldn't use dart:io directly, but its
          // definitely the easiest solution and should be fine.
          var file = new File.fromUri(uri);
          lastModified = await file.lastModified();
          break;
        case 'data':

          // Test runner uses a `data` scheme, don't invalidate for those.
          if (uri.path.contains('package:test')) return;
          continue unknownUri;
        unknownUri:
        default:
          _logger.info('Unsupported uri scheme `${uri.scheme}` found for '
              'library in build script, falling back on full rebuild. '
              '\nThis probably means you are running in an unsupported '
              'context, such as in an isolate or via `pub run`. Instead you '
              'should invoke this script directly like: '
              '`dart path_to_script.dart`.');
          if (!completer.isCompleted) completer.complete(true);
          return;
      }
      assert(lastModified != null);
      if (lastModified.compareTo(_assetGraph.validAsOf) > 0) {
        if (!completer.isCompleted) completer.complete(true);
      }
    }))
        .then((_) {
      if (!completer.isCompleted) completer.complete(false);
    });
    return completer.future;
  }

  /// Creates and returns a map of updates to assets based on [_assetGraph].
  Future<Map<AssetId, ChangeType>> _getUpdates() async {
    // Collect updates to the graph based on any changed assets.
    var updates = <AssetId, ChangeType>{};
    await Future.wait(_assetGraph.allNodes
        .where((node) =>
            node is! GeneratedAssetNode ||
            (node as GeneratedAssetNode).wasOutput)
        .map((node) async {
      bool exists;
      try {
        exists = await _reader.canRead(node.id);
      } on PackageNotFoundException catch (_) {
        exists = false;
      }
      if (!exists) {
        updates[node.id] = ChangeType.REMOVE;
        return;
      }
      // Only handle deletes for generated assets, their modified timestamp
      // is always newer than the asset graph.
      //
      // TODO(jakemac): https://github.com/dart-lang/build/issues/61
      if (node is GeneratedAssetNode) return;

      var lastModified = await _reader.lastModified(node.id);
      if (lastModified.compareTo(_assetGraph.validAsOf) > 0) {
        updates[node.id] = ChangeType.MODIFY;
      }
    }));
    return updates;
  }

  /// Applies all [updates] to the [_assetGraph] as well as doing other
  /// necessary cleanup such as deleting outputs as necessary.
  Future _updateWithChanges(Map<AssetId, ChangeType> updates) async {
    var deletes = _assetGraph.updateAndInvalidate(updates);
    await Future.wait(deletes.map(_writer.delete));
  }

  /// Deletes all previous output files that are in need of an update.
  Future _deletePreviousOutputs(Set<AssetId> currentSources) async {
    if (_assetGraph != null) {
      await Future.wait(_assetGraph.allNodes
          .where((n) => n is GeneratedAssetNode && n.needsUpdate)
          .map((node) => _writer.delete(node.id)));
      return;
    }
    _assetGraph = new AssetGraph.build(_buildActions, currentSources);

    final conflictingOutputs =
        _assetGraph.outputs.where(currentSources.contains).toSet();

    // Check conflictingOutputs, prompt user to delete files.
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
          await Future.wait(conflictingOutputs.map(_writer.delete));
          done = true;
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

  /// Returns the set of available inputs on disk.
  Future<Set<AssetId>> _initializeInputsByPackage() async {
    var inputSets = _packageGraph.allPackages.keys.map((package) =>
        new InputSet(
            package, [package == _packageGraph.root.name ? '**' : 'lib/**']));
    return listAssetIds(_reader, inputSets).where(_isValidInput).toSet();
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

  /// Checks if an [input] is valid.
  bool _isValidInput(AssetId input) => input.package != _packageGraph.root.name
      ? input.path.startsWith('lib/')
      : !input.path.startsWith(toolDir);

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

Iterable<AssetId> listAssetIds(
    RunnerAssetReader assetReader, Iterable<InputSet> inputSets) sync* {
  var seenAssets = new Set<AssetId>();
  for (var inputSet in inputSets) {
    for (var glob in inputSet.globs) {
      for (var id
          in assetReader.findAssets(glob, packageName: inputSet.package)) {
        if (!seenAssets.add(id)) continue;
        yield id;
      }
    }
  }
}
