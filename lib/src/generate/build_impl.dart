// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import '../asset/asset.dart';
import '../asset/cache.dart';
import '../asset/exceptions.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../builder/builder.dart';
import '../builder/build_step_impl.dart';
import '../package_graph/package_graph.dart';
import 'build_result.dart';
import 'directory_watcher_factory.dart';
import 'exceptions.dart';
import 'input_set.dart';
import 'phase.dart';

/// Class which manages running builds.
class BuildImpl {
  final AssetCache _cache;
  final AssetGraph _assetGraph;
  final AssetReader _reader;
  final AssetWriter _writer;
  final PackageGraph _packageGraph;
  final List<List<Phase>> _phaseGroups;
  final _inputsByPackage = <String, Set<AssetId>>{};
  bool _buildRunning = false;
  final _logger = new Logger('Build');

  BuildImpl(this._cache, this._assetGraph, this._reader, this._writer,
      this._packageGraph, this._phaseGroups);

  /// Runs a build
  ///
  /// The returned [Future] is guaranteed to complete with a [BuildResult]. If
  /// an exception is thrown by any phase, [BuildResult#status] will be set to
  /// [BuildStatus.Failure]. The exception and stack trace that caused the failure
  /// will be available as [BuildResult#exception] and [BuildResult#stackTrace]
  /// respectively.
  Future<BuildResult> runBuild() async {
    try {
      if (_buildRunning) throw const ConcurrentBuildException();
      _buildRunning = true;

      /// Wait while all inputs are collected.
      _logger.info('Initializing inputs');
      await _initializeInputsByPackage();

      /// Delete all previous outputs!
      _logger.info('Deleting previous outputs');
      await _deletePreviousOutputs();

      /// Run a fresh build.
      _logger.info('Running build phases');
      var result = await _runPhases();

      // Write out the new build_outputs file.
      var buildOutputsAsset = new Asset(
          _buildOutputsId,
          JSON.encode(
              result.outputs.map((output) => output.id.serialize()).toList()));
      await _writer.writeAsString(buildOutputsAsset);

      return result;
    } catch (e, s) {
      return new BuildResult(BuildStatus.Failure, BuildType.Full, [],
          exception: e, stackTrace: s);
    } finally {
      _buildRunning = false;
    }
  }

  /// Asset containing previous build outputs.
  AssetId get _buildOutputsId =>
      new AssetId(_packageGraph.root.name, '.build/build_outputs.json');

  /// Deletes all previous output files.
  Future _deletePreviousOutputs() async {
    if (await _reader.hasInput(_buildOutputsId)) {
      // Cache file exists, just delete all outputs contained in it.
      var previousOutputs =
          JSON.decode(await _reader.readAsString(_buildOutputsId));
      await _writer.delete(_buildOutputsId);
      _inputsByPackage[_buildOutputsId.package]?.remove(_buildOutputsId);
      await Future.wait(previousOutputs.map((output) {
        var outputId = new AssetId.deserialize(output);
        _inputsByPackage[outputId.package]?.remove(outputId);
        return _writer.delete(outputId);
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
    for (var group in _phaseGroups) {
      final groupOutputIds = <AssetId>[];
      for (var phase in group) {
        var inputs = _matchingInputs(phase.inputSets);
        for (var input in inputs) {
          for (var builder in phase.builders) {
            var outputs = builder.declareOutputs(input);

            groupOutputIds.addAll(outputs);
            for (var output in outputs) {
              if (tempInputsByPackage[output.package]?.contains(output) ==
                  true) {
                conflictingOutputs.add(output);
              }
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

    stdout.writeln('Found ${conflictingOutputs.length} declared outputs '
        'which already exist on disk. This is likely because the `.build` '
        'folder was deleted.');
    var done = false;
    while (!done) {
      stdout.write('Delete these files (y/n) (or list them (l))?: ');
      var input = stdin.readLineSync();
      switch (input) {
        case 'y':
          stdout.writeln('Deleting files...');
          await Future.wait(conflictingOutputs.map((output) {
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

  /// Runs the [_phaseGroups] and returns a [Future<BuildResult>] which
  /// completes once all [Phase]s are done.
  Future<BuildResult> _runPhases() async {
    final outputs = <Asset>[];
    int phaseGroupNum = 0;
    for (var group in _phaseGroups) {
      final groupOutputs = <Asset>[];
      for (var phase in group) {
        var inputs = _matchingInputs(phase.inputSets);
        for (var builder in phase.builders) {
          // TODO(jakemac): Optimize, we can run all the builders in a phase
          // at the same time instead of sequentially.
          await for (var output
              in _runBuilder(builder, inputs, phaseGroupNum)) {
            groupOutputs.add(output);
            outputs.add(output);
          }
        }
      }

      /// Once the group is done, add all outputs so they can be used in the next
      /// phase.
      for (var output in groupOutputs) {
        _inputsByPackage.putIfAbsent(
            output.id.package, () => new Set<AssetId>());
        _inputsByPackage[output.id.package].add(output.id);
      }
      phaseGroupNum++;
    }
    return new BuildResult(BuildStatus.Success, BuildType.Full, outputs);
  }

  /// Initializes the map of all the available inputs by package.
  Future _initializeInputsByPackage() async {
    final packages = new Set<String>();
    for (var group in _phaseGroups) {
      for (var phase in group) {
        for (var inputSet in phase.inputSets) {
          packages.add(inputSet.package);
        }
      }
    }

    var inputSets = packages.map((package) => new InputSet(package));
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
  Set<AssetId> _matchingInputs(Iterable<InputSet> inputSets) {
    var inputs = new Set<AssetId>();
    for (var inputSet in inputSets) {
      assert(_inputsByPackage.containsKey(inputSet.package));
      for (var input in _inputsByPackage[inputSet.package]) {
        if (inputSet.globs.any((g) => g.matches(input.path))) {
          inputs.add(input);
        }
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
      int phaseGroupNum) async* {
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
            output,
            () => new GeneratedAssetNode(
                builder, input, phaseGroupNum, true, output));
      }

      /// Skip the build step if none of the outputs need updating.
      var skipBuild = !expectedOutputs.any((output) =>
          (_assetGraph.get(output) as GeneratedAssetNode).needsUpdate);
      if (skipBuild) continue;

      var inputAsset = new Asset(input, await _reader.readAsString(input));
      var buildStep = new BuildStepImpl(inputAsset, expectedOutputs, _reader,
          _writer, _packageGraph.root.name);
      await builder.build(buildStep);
      await buildStep.complete();

      /// Update the asset graph based on the dependencies discovered.
      for (var dependency in buildStep.dependencies) {
        var dependencyNode = _assetGraph.addIfAbsent(
            dependency, () => new AssetNode(dependency));

        /// We care about all [expectedOutputs], not just real outputs.
        dependencyNode.outputs.addAll(expectedOutputs);
      }

      /// Yield the outputs.
      for (var output in buildStep.outputs) {
        yield output;
      }
    }
  }
}

/// Extends [BuildImpl] to add the [runWatch] method, which watches all
/// inputs for changes.
class WatchImpl extends BuildImpl {
  /// Injectable factory for creating directory watchers.
  final DirectoryWatcherFactory _directoryWatcherFactory;

  /// Delay to wait for more file watcher events.
  final Duration _debounceDelay;

  /// Whether or not we are currently watching and running builds.
  bool _runningWatch = false;

  /// Controller for the results stream.
  StreamController<BuildResult> _resultStreamController;

  /// All file listeners currently set up.
  final _allListeners = <StreamSubscription>[];

  /// A future that completes when the current build is done.
  Future _currentBuild;

  /// Whether or not another build is scheduled.
  bool _nextBuildScheduled;

  /// Whether we are in the process of terminating.
  bool _terminating = false;

  WatchImpl(
      this._directoryWatcherFactory,
      this._debounceDelay,
      AssetCache cache,
      AssetGraph assetGraph,
      AssetReader reader,
      AssetWriter writer,
      PackageGraph packageGraph,
      List<List<Phase>> phaseGroups)
      : super(cache, assetGraph, reader, writer, packageGraph, phaseGroups);

  /// Completes after the current build is done, and stops further builds from
  /// happening.
  Future terminate() async {
    assert(_terminating == false);
    _terminating = true;
    _logger.info('Terminating watchers, no futher builds will be scheduled.');
    _nextBuildScheduled = false;
    for (var listener in _allListeners) {
      await listener.cancel();
    }
    _allListeners.clear();
    if (_currentBuild != null) {
      _logger.info('Waiting for ongoing build to finish.');
      await _currentBuild;
    }
    await _resultStreamController.close();
    _terminating = false;
    _logger.info('Build watching terminated.');
  }

  /// Runs a build any time relevant files change.
  ///
  /// Only one build will run at a time, and changes are batched.
  Stream<BuildResult> runWatch() {
    assert(_runningWatch == false);
    _runningWatch = true;
    _resultStreamController = new StreamController<BuildResult>();
    _nextBuildScheduled = false;
    var updatedInputs = new Set<AssetId>();

    doBuild([bool force = false]) {
      // Don't schedule more builds if we are turning down.
      if (_terminating) return;

      if (_currentBuild != null) {
        if (_nextBuildScheduled == false) {
          _logger.info('Scheduling next build');
          _nextBuildScheduled = true;
        }
        return;
      }
      assert(_nextBuildScheduled == false);

      /// Remove any updates that were generated outputs or otherwise not
      /// interesting.
      updatedInputs.removeWhere(_shouldSkipInput);
      if (updatedInputs.isEmpty && !force) {
        return;
      }

      _logger.info('Preparing for next build');
      _logger.info('Clearing cache for invalidated assets');
      void clearNodeAndDeps(AssetId id) {
        var node = _assetGraph.get(id);
        if (node == null) return;
        _cache.remove(id);
        for (var output in node.outputs) {
          clearNodeAndDeps(output);
        }
      }
      for (var input in updatedInputs) {
        clearNodeAndDeps(input);
      }
      updatedInputs.clear();

      _logger.info('Starting build');
      _currentBuild = runBuild();
      _currentBuild.then((result) {
        if (result.status == BuildStatus.Success) {
          _logger.info('Build completed successfully');
        } else {
          _logger.warning('Build failed');
        }
        _resultStreamController.add(result);
        _currentBuild = null;
        if (_nextBuildScheduled) {
          _nextBuildScheduled = false;
          doBuild();
        }
      });
    }

    Timer buildTimer;
    scheduleBuild() {
      if (buildTimer?.isActive == true) buildTimer.cancel();
      buildTimer = new Timer(_debounceDelay, doBuild);
    }

    final watchers = <DirectoryWatcher>[];
    _logger.info('Setting up file watchers');
    for (var package in _packageGraph.allPackages.values) {
      _logger.fine('Setting up watcher at ${package.location.toFilePath()}');
      var watcher = _directoryWatcherFactory(package.location.toFilePath());
      watchers.add(watcher);
      _allListeners.add(watcher.events.listen((WatchEvent e) {
        _logger.fine('Got WatchEvent for path ${e.path}');
        var id = new AssetId(package.name, path.normalize(e.path));
        updatedInputs.add(id);
        scheduleBuild();
      }));
    }

    Future.wait(watchers.map((w) => w.ready)).then((_) {
      // Schedule the first build!
      doBuild(true);
    });

    return _resultStreamController.stream;
  }

  /// Checks if we should skip a watch event for this [id].
  bool _shouldSkipInput(AssetId id) {
    if (id.path.startsWith('.build')) return true;
    var node = _assetGraph.get(id);
    return node is GeneratedAssetNode;
  }
}
