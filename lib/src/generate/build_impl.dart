// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:watcher/watcher.dart';

import '../asset/asset.dart';
import '../asset/cache.dart';
import '../asset/exceptions.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/exceptions.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../builder/build_step_impl.dart';
import '../builder/builder.dart';
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';
import 'build_result.dart';
import 'exceptions.dart';
import 'input_set.dart';
import 'options.dart';
import 'phase.dart';

/// Class which manages running builds.
class BuildImpl {
  AssetGraph _assetGraph;
  AssetGraph get assetGraph => _assetGraph;

  final AssetReader _reader;
  final AssetWriter _writer;
  final PackageGraph _packageGraph;
  final List<List<BuildAction>> _buildActions;
  final _inputsByPackage = <String, Set<AssetId>>{};
  bool _buildRunning = false;
  final _logger = new Logger('Build');

  bool _isFirstBuild = true;

  BuildImpl(BuildOptions options, PhaseGroup phaseGroup)
      : _reader = options.reader,
        _writer = options.writer,
        _packageGraph = options.packageGraph,
        _buildActions = phaseGroup.buildActions;

  /// Runs a build
  ///
  /// The returned [Future] is guaranteed to complete with a [BuildResult]. If
  /// an exception is thrown by any phase, [BuildResult#status] will be set to
  /// [BuildStatus.Failure]. The exception and stack trace that caused the failure
  /// will be available as [BuildResult#exception] and [BuildResult#stackTrace]
  /// respectively.
  ///
  /// The [validAsOf] date is assigned to [AssetGraph#validAsOf] and marks
  /// a point in time after which any updates to files should invalidate the
  /// graph for future builds.
  Future<BuildResult> runBuild(
      {DateTime validAsOf, Map<AssetId, ChangeType> updates}) async {
    validAsOf ??= new DateTime.now();
    updates ??= <AssetId, ChangeType>{};
    var watch = new Stopwatch()..start();

    /// Assume incremental, change if necessary.
    var buildType = BuildType.Incremental;
    var done = new Completer();
    Chain.capture(() async {
      if (_buildRunning) throw const ConcurrentBuildException();
      _buildRunning = true;

      /// Initialize the [assetGraph] if its not yet set up.
      if (_assetGraph == null) {
        await logWithTime(_logger, 'Reading cached dependency graph', () async {
          _assetGraph = await _readAssetGraph();

          /// Collect updates since the asset graph was last created. This only
          /// handles updates and deletes, not adds. We list the file system for
          /// all inputs later on (in [_initializeInputsByPackage]).
          updates.addAll(await _getUpdates());
        });
      }

      /// If the build script gets updated, we need to either fully invalidate
      /// the graph (if the script current running is up to date), or we need to
      /// terminate and ask the user to restart the script (if the currently
      /// running script is out of date).
      ///
      /// The [_isFirstBuild] flag is used as a proxy for "has this script
      /// been updated since it started running".
      ///
      /// TODO(jakemac): Come up with a better way of telling if the script
      /// has been updated since it started running.
      await logWithTime(_logger, 'Checking build script for updates', () async {
        if (await _buildScriptUpdated()) {
          buildType = BuildType.Full;
          if (_isFirstBuild) {
            _logger
                .warning('Invalidating asset graph due to build script update');
            _assetGraph.allNodes
                .where((node) => node is GeneratedAssetNode)
                .forEach(
                    (node) => (node as GeneratedAssetNode).needsUpdate = true);
          } else {
            done.complete(new BuildResult(BuildStatus.Failure, buildType, [],
                exception: new BuildScriptUpdatedException()));
          }
        }
      });
      // Bail if the previous step completed the build.
      if (done.isCompleted) return;

      await logWithTime(_logger, 'Finalizing build setup', () async {
        /// Applies all [updates] to the [_assetGraph] as well as doing other
        /// necessary cleanup.
        _logger
            .info('Updating dependency graph with changes since last build.');
        await _updateWithChanges(updates);

        /// Wait while all inputs are collected.
        _logger.info('Initializing inputs');
        await _initializeInputsByPackage();

        /// Delete all previous outputs!
        _logger.info('Deleting previous outputs');
        await _deletePreviousOutputs();
      });

      /// Run a fresh build.
      var result = await logWithTime(_logger, 'Running build', _runPhases);

      /// Write out the dependency graph file.
      await logWithTime(_logger, 'Caching finalized dependency graph',
          () async {
        _assetGraph.validAsOf = validAsOf;
        var assetGraphAsset =
            new Asset(_assetGraphId, JSON.encode(_assetGraph.serialize()));
        await _writer.writeAsString(assetGraphAsset);
      });

      done.complete(result);
    }, onError: (e, Chain chain) {
      done.complete(new BuildResult(BuildStatus.Failure, buildType, [],
          exception: e, stackTrace: chain.toTrace()));
    });
    var result = await done.future;
    _buildRunning = false;
    _isFirstBuild = false;
    if (result.status == BuildStatus.Success) {
      _logger.info('Succeeded after ${watch.elapsedMilliseconds}ms with '
          '${result.outputs.length} outputs\n\n');
    } else {
      var exceptionString =
          result.exception != null ? '\n${result.exception}' : '';
      var stackTraceString =
          result.stackTrace != null ? '\n${result.stackTrace}' : '';
      _logger.severe('Failed after ${watch.elapsedMilliseconds}ms'
          '$exceptionString$stackTraceString\n');
    }
    return result;
  }

  /// Asset containing previous asset dependency graph.
  AssetId get _assetGraphId =>
      new AssetId(_packageGraph.root.name, '.dart_tool/build/asset_graph.json');

  /// Reads in the [assetGraph] from disk.
  Future<AssetGraph> _readAssetGraph() async {
    if (!await _reader.hasInput(_assetGraphId)) return new AssetGraph();
    try {
      return new AssetGraph.deserialize(
          JSON.decode(await _reader.readAsString(_assetGraphId)));
    } on AssetGraphVersionException catch (_) {
      /// Start fresh if the cached asset_graph version doesn't match up with
      /// the current version. We don't currently support old graph versions.
      _logger.info('Throwing away cached asset graph due to version mismatch.');
      return new AssetGraph();
    }
  }

  /// Checks if the current running program has been updated since the asset
  /// graph was last built.
  Future<bool> _buildScriptUpdated() async {
    var completer = new Completer<bool>();
    Future
        .wait(currentMirrorSystem().libraries.keys.map((Uri uri) async {
      /// Short-circuit
      if (completer.isCompleted) return;
      var lastModified;
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

          /// TODO(jakemac): Probably shouldn't use dart:io directly, but its
          /// definitely the easiest solution and should be fine.
          var file = new File.fromUri(uri);
          lastModified = await file.lastModified();
          break;
        case 'data':

          /// Test runner uses a `data` scheme, don't invalidate for those.
          if (uri.path.contains('package:test')) return;
          continue unknownUri;
        unknownUri: default:
          _logger.info('Unrecognized uri scheme `${uri.scheme}` found for '
              'library in build script, falling back on full rebuild.');
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
    /// Collect updates to the graph based on any changed assets.
    var updates = <AssetId, ChangeType>{};
    await Future.wait(_assetGraph.allNodes
        .where((node) =>
            node is! GeneratedAssetNode ||
            (node as GeneratedAssetNode).wasOutput)
        .map((node) async {
      var exists = await _reader.hasInput(node.id);
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
  /// necessary cleanup such as clearing caches for [CachedAssetReader]s and
  /// deleting outputs as necessary.
  Future _updateWithChanges(Map<AssetId, ChangeType> updates) async {
    var seen = new Set<AssetId>();
    Future clearNodeAndDeps(AssetId id, ChangeType rootChangeType,
        {AssetId parent}) async {
      if (seen.contains(id)) return;
      seen.add(id);
      var node = _assetGraph.get(id);
      if (node == null) return;

      if (_reader is CachedAssetReader) {
        (_reader as CachedAssetReader).evictFromCache(id);
      }

      /// Update all ouputs of this asset as well.
      await Future.wait(node.outputs.map((output) =>
          clearNodeAndDeps(output, rootChangeType, parent: node.id)));

      /// For deletes, prune the graph.
      if (parent == null && rootChangeType == ChangeType.REMOVE) {
        _assetGraph.remove(id);
      }
      if (node is GeneratedAssetNode) {
        node.needsUpdate = true;
        if (rootChangeType == ChangeType.REMOVE &&
            node.primaryInput == parent) {
          _assetGraph.remove(id);
          await _writer.delete(id);
        }
      }
    }

    await Future.wait(
        updates.keys.map((input) => clearNodeAndDeps(input, updates[input])));
  }

  /// Deletes all previous output files that are in need of an update.
  Future _deletePreviousOutputs() async {
    /// TODO(jakemac): need a cleaner way of telling if the current graph was
    /// generated from cache or if its just a brand new graph.
    if (await _reader.hasInput(_assetGraphId)) {
      await _writer.delete(_assetGraphId);
      _inputsByPackage[_assetGraphId.package]?.remove(_assetGraphId);

      /// Remove all output nodes from [_inputsByPackage], and delete all assets
      /// that need updates.
      await Future.wait(_assetGraph.allNodes
          .where((node) => node is GeneratedAssetNode)
          .map((node) async {
        _inputsByPackage[node.id.package]?.remove(node.id);
        if ((node as GeneratedAssetNode).needsUpdate) {
          await _writer.delete(node.id);
        }
      }));
      return;
    }

    // Deep copy _inputsByPackage, we don't want to actually modify the real one
    // as this is just a dry run to determine potential conflicts.
    final tempInputsByPackage = {};
    _inputsByPackage.forEach((package, inputs) {
      tempInputsByPackage[package] = new Set<AssetId>.from(inputs);
    });

    // No cache file exists, run `declareOutputs` on all phases and collect all
    // outputs which conflict with existing assets.
    final conflictingOutputs = new Set<AssetId>();
    for (var phase in _buildActions) {
      final groupOutputIds = <AssetId>[];
      for (var action in phase) {
        var inputs = _matchingInputs(action.inputSet);
        for (var input in inputs) {
          var outputs = action.builder.declareOutputs(input);

          groupOutputIds.addAll(outputs);
          for (var output in outputs) {
            if (tempInputsByPackage[output.package]?.contains(output) == true) {
              conflictingOutputs.add(output);
            }
          }
        }
      }

      /// Once the group is done, add all outputs so they can be used in the next
      /// phase.
      for (var outputId in groupOutputIds) {
        tempInputsByPackage.putIfAbsent(
            outputId.package, () => new Set<AssetId>());
        tempInputsByPackage[outputId.package].add(outputId);
      }
    }

    // Check conflictingOuputs, prompt user to delete files.
    if (conflictingOutputs.isEmpty) return;

    stdout.writeln('\n\nFound ${conflictingOutputs.length} declared outputs '
        'which already exist on disk. This is likely because the'
        '`.dart_tool/build` folder was deleted, or you are submitting generated '
        'files to your source repository.');
    var done = false;
    while (!done) {
      stdout.write('\nDelete these files (y/n) (or list them (l))?: ');
      var input = stdin.readLineSync();
      switch (input.toLowerCase()) {
        case 'y':
          stdout.writeln('Deleting files...');
          await Future.wait(conflictingOutputs.map/*<Future>*/((output) {
            _inputsByPackage[output.package]?.remove(output);
            return _writer.delete(output);
          }));
          done = true;
          break;
        case 'n':
          stdout.writeln('Exiting...');
          exit(1);
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

  /// Runs the [Phase]s in [_buildActions] and returns a [Future<BuildResult>]
  /// which completes once all [BuildAction]s are done.
  Future<BuildResult> _runPhases() async {
    final outputs = <Asset>[];
    for (var phase in _buildActions) {
      /// Collects all the ids for files which are output by this stage. This
      /// also includes files which didn't get regenerated because they weren't,
      /// dirty unlike [outputs] which only gets files which were explicitly
      /// generated in this build.
      final phaseOutputIds = new Set<AssetId>();

      await Future.wait(phase.map((action) async {
        var inputs = _matchingInputs(action.inputSet);
        await for (var output
            in _runBuilder(action.builder, inputs, phaseOutputIds)) {
          outputs.add(output);
        }
      }));

      /// Once the group is done, add all outputs so they can be used in the next
      /// phase.
      for (var outputId in phaseOutputIds) {
        _inputsByPackage.putIfAbsent(
            outputId.package, () => new Set<AssetId>());
        _inputsByPackage[outputId.package].add(outputId);
      }
    }
    return new BuildResult(BuildStatus.Success, BuildType.Full, outputs);
  }

  /// Initializes the map of all the available inputs by package.
  Future _initializeInputsByPackage() async {
    final packages = new Set<String>();
    for (var phase in _buildActions) {
      for (var action in phase) {
        packages.add(action.inputSet.package);
      }
    }

    var inputSets = packages.map((package) => new InputSet(
        package, [package == _packageGraph.root.name ? '**/*' : 'lib/**']));
    var allInputs = await _reader.listAssetIds(inputSets).toList();
    _inputsByPackage.clear();
    for (var input in allInputs) {
      _inputsByPackage.putIfAbsent(input.package, () => new Set<AssetId>());

      if (_isValidInput(input)) {
        _inputsByPackage[input.package].add(input);
      }
    }
  }

  /// Gets a list of all inputs matching [inputSets].
  Set<AssetId> _matchingInputs(InputSet inputSet) {
    var inputs = new Set<AssetId>();
    assert(_inputsByPackage.containsKey(inputSet.package));
    for (var input in _inputsByPackage[inputSet.package]) {
      if (inputSet.globs.any((g) => g.matches(input.path))) {
        inputs.add(input);
      }
    }
    return inputs;
  }

  /// Checks if an [input] is valid.
  bool _isValidInput(AssetId input) {
    var parts = path.split(input.path);
    // Files must be in a top level directory.
    if (parts.length == 1) return false;
    if (input.package != _packageGraph.root.name) return parts[0] == 'lib';
    return true;
  }

  /// Runs [builder] with [inputs] as inputs.
  Stream<Asset> _runBuilder(Builder builder, Iterable<AssetId> primaryInputs,
      Set<AssetId> groupOutputs) async* {
    for (var input in primaryInputs) {
      var expectedOutputs = builder.declareOutputs(input);

      /// Validate [expectedOutputs].
      for (var output in expectedOutputs) {
        if (output.package != _packageGraph.root.name) {
          throw new InvalidOutputException(new Asset(output, ''));
        }
        if (_inputsByPackage[output.package]?.contains(output) == true) {
          throw new InvalidOutputException(new Asset(output, ''));
        }
      }

      /// Add nodes to the [AssetGraph] for [expectedOutputs] and [input].
      var inputNode =
          _assetGraph.addIfAbsent(input, () => new AssetNode(input));
      for (var output in expectedOutputs) {
        inputNode.outputs.add(output);
        _assetGraph.addIfAbsent(
            output, () => new GeneratedAssetNode(input, true, false, output));
      }

      /// Skip the build step if none of the outputs need updating.
      var skipBuild = !expectedOutputs.any((output) =>
          (_assetGraph.get(output) as GeneratedAssetNode).needsUpdate);
      if (skipBuild) {
        /// If we skip the build, we still need to add the ids as outputs for
        /// any files which were output last time, so they can be used by
        /// subsequent phases.
        for (var output in expectedOutputs) {
          if ((_assetGraph.get(output) as GeneratedAssetNode).wasOutput) {
            groupOutputs.add(output);
          }
        }
        continue;
      }

      var inputAsset = new Asset(input, await _reader.readAsString(input));
      var buildStep = new BuildStepImpl(inputAsset, expectedOutputs, _reader,
          _writer, _packageGraph.root.name);
      await builder.build(buildStep);
      await buildStep.complete();

      /// Mark all outputs as no longer needing an update, and mark `wasOutput`
      /// as `false` for now (this will get reset to true later one).
      for (var output in expectedOutputs) {
        (_assetGraph.get(output) as GeneratedAssetNode)
          ..needsUpdate = false
          ..wasOutput = false;
      }

      /// Update the asset graph based on the dependencies discovered.
      for (var dependency in buildStep.dependencies) {
        var dependencyNode = _assetGraph.addIfAbsent(
            dependency, () => new AssetNode(dependency));

        /// We care about all [expectedOutputs], not just real outputs. Updates
        /// to dependencies may cause a file to be output which wasn't before.
        dependencyNode.outputs.addAll(expectedOutputs);
      }

      /// Yield the outputs.
      for (var output in buildStep.outputs) {
        (_assetGraph.get(output.id) as GeneratedAssetNode).wasOutput = true;
        groupOutputs.add(output.id);
        yield output;
      }
    }
  }
}
