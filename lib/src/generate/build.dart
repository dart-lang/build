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
import '../asset/cache.dart';
import '../asset/file_based.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../builder/builder.dart';
import '../builder/build_step_impl.dart';
import '../package_graph/package_graph.dart';
import 'build_result.dart';
import 'input_set.dart';
import 'phase.dart';

/// Runs all of the [Phases] in [phaseGroups].
///
/// A [packageGraph] may be supplied, otherwise one will be constructed using
/// [PackageGraph.forThisPackage]. The default functionality assumes you are
/// running in the root directory of a package, with both a `pubspec.yaml` and
/// `.packages` file present.
///
/// A [reader] and [writer] may also be supplied, which can read/write assets
/// to arbitrary locations or file systems. By default they will write directly
/// to the root package directory, and will use the [packageGraph] to know where
/// to read files from.
///
/// Logging may be customized by passing a custom [logLevel] below which logs
/// will be ignored, as well as an [onLog] handler which defaults to [print].
Future<BuildResult> build(List<List<Phase>> phaseGroups,
    {PackageGraph packageGraph,
    AssetReader reader,
    AssetWriter writer,
    Level logLevel: Level.ALL,
    onLog(LogRecord)}) async {
  Logger.root.level = logLevel;
  onLog ??= print;
  var logListener = Logger.root.onRecord.listen(onLog);
  packageGraph ??= new PackageGraph.forThisPackage();
  var cache = new AssetCache();
  reader ??=
      new CachedAssetReader(cache, new FileBasedAssetReader(packageGraph));
  writer ??=
      new CachedAssetWriter(cache, new FileBasedAssetWriter(packageGraph));

  /// Run the build in a zone.
  var result = await runZoned(() async {
    try {
      /// Delete all previous outputs!
      await _deletePreviousOutputs(phaseGroups);

      /// Run a fresh build.
      var result = await _runPhases(phaseGroups);

      // Write out the new build_outputs file.
      var buildOutputsAsset = new Asset(
          _buildOutputsId,
          JSON.encode(
              result.outputs.map((output) => output.id.serialize()).toList()));
      await writer.writeAsString(buildOutputsAsset);

      return result;
    } catch (e, s) {
      return new BuildResult(BuildStatus.Failure, BuildType.Full, [],
          exception: e, stackTrace: s);
    }
  }, zoneValues: {
    _assetGraphKey: new AssetGraph(),
    _assetReaderKey: reader,
    _assetWriterKey: writer,
    _packageGraphKey: packageGraph,
  });

  await logListener.cancel();

  return result;
}

/// Keys for reading zone local values.
Symbol _assetGraphKey = #buildAssetGraph;
Symbol _assetReaderKey = #buildAssetReader;
Symbol _assetWriterKey = #buildAssetWriter;
Symbol _packageGraphKey = #buildPackageGraph;

/// Getters for zone local values.
AssetGraph get _assetGraph => Zone.current[_assetGraphKey];
AssetReader get _reader => Zone.current[_assetReaderKey];
AssetWriter get _writer => Zone.current[_assetWriterKey];
PackageGraph get _packageGraph => Zone.current[_packageGraphKey];

/// Asset containing previous build outputs.
AssetId get _buildOutputsId =>
    new AssetId(_packageGraph.root.name, '.build/build_outputs.json');

/// Deletes all previous output files.
Future _deletePreviousOutputs(List<List<Phase>> phaseGroups) async {
  if (await _reader.hasInput(_buildOutputsId)) {
    // Cache file exists, just delete all outputs contained in it.
    var previousOutputs =
        JSON.decode(await _reader.readAsString(_buildOutputsId));
    await _writer.delete(_buildOutputsId);
    await Future.wait(previousOutputs.map((output) {
      return _writer.delete(new AssetId.deserialize(output));
    }));
    return;
  }

  // No cache file exists, run `declareOutputs` on all phases and collect all
  // outputs which conflict with existing assets.
  final allInputs = await _allInputs(phaseGroups);
  final conflictingOutputs = new Set<AssetId>();
  for (var group in phaseGroups) {
    final groupOutputIds = <AssetId>[];
    for (var phase in group) {
      var inputs = _matchingInputs(allInputs, phase.inputSets);
      for (var input in inputs) {
        for (var builder in phase.builders) {
          var outputs = builder.declareOutputs(input);

          groupOutputIds.addAll(outputs);
          for (var output in outputs) {
            if (allInputs[output.package]?.contains(output) == true) {
              conflictingOutputs.add(output);
            }
          }
        }
      }
    }

    /// Once the group is done, add all outputs so they can be used in the next
    /// phase.
    for (var outputId in groupOutputIds) {
      allInputs.putIfAbsent(outputId.package, () => new Set<AssetId>());
      allInputs[outputId.package].add(outputId);
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

/// Runs the [phaseGroups] and returns a [Future<BuildResult>] which completes
/// once all [Phase]s are done.
Future<BuildResult> _runPhases(List<List<Phase>> phaseGroups) async {
  final allInputs = await _allInputs(phaseGroups);
  final outputs = <Asset>[];
  int phaseGroupNum = 0;
  for (var group in phaseGroups) {
    final groupOutputs = <Asset>[];
    for (var phase in group) {
      var inputs = _matchingInputs(allInputs, phase.inputSets);
      for (var builder in phase.builders) {
        // TODO(jakemac): Optimize, we can run all the builders in a phase
        // at the same time instead of sequentially.
        await for (var output
            in _runBuilder(builder, inputs, allInputs, phaseGroupNum)) {
          groupOutputs.add(output);
          outputs.add(output);
        }
      }
    }

    /// Once the group is done, add all outputs so they can be used in the next
    /// phase.
    for (var output in groupOutputs) {
      allInputs.putIfAbsent(output.id.package, () => new Set<AssetId>());
      allInputs[output.id.package].add(output.id);
    }
    phaseGroupNum++;
  }
  return new BuildResult(BuildStatus.Success, BuildType.Full, outputs);
}

/// Returns a map of all the available inputs by package.
Future<Map<String, Set<AssetId>>> _allInputs(
    List<List<Phase>> phaseGroups) async {
  final packages = new Set<String>();
  for (var group in phaseGroups) {
    for (var phase in group) {
      for (var inputSet in phase.inputSets) {
        packages.add(inputSet.package);
      }
    }
  }

  var inputSets = packages.map((package) => new InputSet(package));
  var allInputs = await _reader.listAssetIds(inputSets).toList();
  var inputsByPackage = {};
  for (var input in allInputs) {
    inputsByPackage.putIfAbsent(input.package, () => new Set<AssetId>());

    if (_isValidInput(input)) {
      inputsByPackage[input.package].add(input);
    }
  }
  return inputsByPackage;
}

/// Gets a list of all inputs matching [inputSets] given [allInputs].
Set<AssetId> _matchingInputs(
    Map<String, Set<AssetId>> inputsByPackage, Iterable<InputSet> inputSets) {
  var inputs = new Set<AssetId>();
  for (var inputSet in inputSets) {
    assert(inputsByPackage.containsKey(inputSet.package));
    for (var input in inputsByPackage[inputSet.package]) {
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
    Map<String, Set<AssetId>> allInputs, int phaseGroupNum) async* {
  for (var input in primaryInputs) {
    var expectedOutputs = builder.declareOutputs(input);

    /// Validate [expectedOutputs].
    for (var output in expectedOutputs) {
      if (output.package != _packageGraph.root.name) {
        throw new InvalidOutputException(new Asset(output, ''));
      }
      if (allInputs[output.package]?.contains(output) == true) {
        throw new InvalidOutputException(new Asset(output, ''));
      }
    }

    /// Add nodes to the [AssetGraph] for [expectedOutputs] and [input].
    var inputNode = _assetGraph.addIfAbsent(input, () => new AssetNode(input));
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
      var dependencyNode =
          _assetGraph.addIfAbsent(dependency, () => new AssetNode(dependency));

      /// We care about all [expectedOutputs], not just real outputs.
      dependencyNode.outputs.addAll(expectedOutputs);
    }

    /// Yield the outputs.
    for (var output in buildStep.outputs) {
      yield output;
    }
  }
}
