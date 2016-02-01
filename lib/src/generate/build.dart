// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../asset/asset.dart';
import '../asset/file_based.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
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
/// to arbitrary locations or file systems. By default they will write to the
/// current directory, and will use the `packageGraph` to know where to read
/// files from.
Future<BuildResult> build(List<List<Phase>> phaseGroups,
    {PackageGraph packageGraph, AssetReader reader, AssetWriter writer}) async {
  packageGraph ??= new PackageGraph.forThisPackage();
  reader ??= new FileBasedAssetReader(packageGraph);
  writer ??= new FileBasedAssetWriter(packageGraph);
  return runZoned(() {
    _validatePhases(phaseGroups);
    return _runPhases(phaseGroups);
  }, onError: (e, s) {
    return new BuildResult(BuildStatus.Failure, BuildType.Full, [],
        exception: e, stackTrace: s);
  }, zoneValues: {
    _assetReaderKey: reader,
    _assetWriterKey: writer,
    _packageGraphKey: packageGraph,
  });
}

/// Keys for reading zone local values.
Symbol _assetReaderKey = #buildAssetReader;
Symbol _assetWriterKey = #buildAssetWriter;
Symbol _packageGraphKey = #buildPackageGraph;

/// Getters for zone local values.
AssetReader get _reader => Zone.current[_assetReaderKey];
AssetWriter get _writer => Zone.current[_assetWriterKey];
PackageGraph get _packageGraph => Zone.current[_packageGraphKey];

/// The local package name from your pubspec.
final String _localPackageName = () {
  var pubspec = new File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    throw 'Build scripts must be invoked from the top level package directory, '
        'which must contain a pubspec.yaml';
  }
  var yaml = loadYaml(pubspec.readAsStringSync()) as YamlMap;
  if (yaml['name'] == null) {
    throw 'You must have a `name` specified in your pubspec.yaml file.';
  }
  return yaml['name'];
}();

/// Validates the phases.
void _validatePhases(List<List<Phase>> phaseGroups) {
  if (phaseGroups.length > 1) {
    // Don't support using generated files as inputs yet, so we only support
    // one phase.
    throw new UnimplementedError(
        'Only one phase group is currently supported.');
  }
}

/// Runs the [phaseGroups] and returns a [Future<BuildResult>] which completes
/// once all [Phase]s are done.
Future<BuildResult> _runPhases(List<List<Phase>> phaseGroups) async {
  var outputs = [];
  for (var group in phaseGroups) {
    for (var phase in group) {
      var inputs = _assetIdsFor(phase.inputSets);
      for (var builder in phase.builders) {
        // TODO(jakemac): Optimize, we can run all the builders in a phase
        // at the same time instead of sequentially.
        await for (var output in _runBuilder(builder, inputs)) {
          outputs.add(output);
        }
      }
    }
  }
  return new BuildResult(BuildStatus.Success, BuildType.Full, outputs);
}

/// Gets all [AssetId]s matching [inputSets] in the current package.
List<AssetId> _assetIdsFor(List<InputSet> inputSets) {
  var ids = [];
  for (var inputSet in inputSets) {
    var files = _filesMatching(inputSet);
    for (var file in files) {
      var segments = file.uri.pathSegments;
      var newPath = path.joinAll(segments.getRange(
          segments.indexOf(inputSet.package) + 1, segments.length));
      ids.add(new AssetId(inputSet.package, newPath));
    }
  }
  return ids;
}

/// Returns all files matching [inputSet].
Set<File> _filesMatching(InputSet inputSet) {
  var files = new Set<File>();
  var root = _packageGraph[inputSet.package].location.toFilePath();
  for (var glob in inputSet.globs) {
    files.addAll(glob.listSync(followLinks: false, root: root).where(
        (e) => e is File && !_ignoredDirs.contains(path.split(e.path)[1])));
  }
  return files;
}
const _ignoredDirs = const ['build'];

/// Runs [builder] with [inputs] as inputs.
Stream<Asset> _runBuilder(Builder builder, List<AssetId> inputs) async* {
  for (var input in inputs) {
    var expectedOutputs = builder.declareOutputs(input);
    var inputAsset = new Asset(input, await _reader.readAsString(input));
    var buildStep =
        new BuildStepImpl(inputAsset, expectedOutputs, _reader, _writer);
    await builder.build(buildStep);
    await buildStep.outputsCompleted;
    for (var output in buildStep.outputs) {
      yield output;
    }
  }
}
