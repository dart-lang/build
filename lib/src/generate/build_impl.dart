// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../asset/asset.dart';
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
import 'exceptions.dart';
import 'input_set.dart';
import 'phase.dart';

/// Class which manages running builds.
class BuildImpl {
  final AssetGraph _assetGraph;
  final AssetReader _reader;
  final AssetWriter _writer;
  final PackageGraph _packageGraph;
  final List<List<Phase>> _phaseGroups;
  final _inputsByPackage = <String, Set<AssetId>>{};
  bool _buildRunning = false;
  final _logger = new Logger('Build');

  BuildImpl(this._assetGraph, this._reader, this._writer,
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
      /// Cache file exists, delete all outputs which don't appear in the
      /// [_assetGraph], or are marked as needing an update.
      ///
      /// Removes all files from [_inputsByPackage] regardless of state.
      var previousOutputs =
          JSON.decode(await _reader.readAsString(_buildOutputsId));
      await _writer.delete(_buildOutputsId);
      _inputsByPackage[_buildOutputsId.package]?.remove(_buildOutputsId);
      await Future.wait(previousOutputs.map((output) async {
        var outputId = new AssetId.deserialize(output);
        _inputsByPackage[outputId.package]?.remove(outputId);
        var node = _assetGraph.get(outputId);
        if (node == null || (node as GeneratedAssetNode).needsUpdate) {
          await _writer.delete(outputId);
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
      switch (input.toLowerCase()) {
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
      /// Collects all the ids for files which are output by this stage. This
      /// also includes files which didn't get regenerated because they weren't,
      /// dirty unlike [outputs] which only gets files which were explicitly
      /// generated in this build.
      final groupOutputIds = new Set<AssetId>();
      for (var phase in group) {
        var inputs = _matchingInputs(phase.inputSets);
        for (var builder in phase.builders) {
          // TODO(jakemac): Optimize, we can run all the builders in a phase
          // at the same time instead of sequentially.
          await for (var output
              in _runBuilder(builder, inputs, phaseGroupNum, groupOutputIds)) {
            outputs.add(output);
          }
        }
      }

      /// Once the group is done, add all outputs so they can be used in the next
      /// phase.
      for (var outputId in groupOutputIds) {
        _inputsByPackage.putIfAbsent(
            outputId.package, () => new Set<AssetId>());
        _inputsByPackage[outputId.package].add(outputId);
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
      int phaseGroupNum, Set<AssetId> groupOutputs) async* {
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
      if (skipBuild) {
        /// If we skip the build, we still need to add the ids as outputs for
        /// any files which were output last time, so they can be used by
        /// subsequent phases.
        for (var output in expectedOutputs) {
          if (await _reader.hasInput(output)) {
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

      /// Mark all outputs as no longer needing an update.
      for (var output in expectedOutputs) {
        (_assetGraph.get(output) as GeneratedAssetNode).needsUpdate = false;
      }

      /// Update the asset graph based on the dependencies discovered.
      for (var dependency in buildStep.dependencies) {
        var dependencyNode = _assetGraph.addIfAbsent(
            dependency, () => new AssetNode(dependency));

        /// We care about all [expectedOutputs], not just real outputs.
        dependencyNode.outputs.addAll(expectedOutputs);
      }

      /// Yield the outputs.
      for (var output in buildStep.outputs) {
        groupOutputs.add(output.id);
        yield output;
      }
    }
  }
}
