// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../asset/asset.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../builder/builder.dart';
import '../builder/build_step.dart';
import 'build_result.dart';
import 'input_set.dart';
import 'phase.dart';

/// Runs all of the [Phases] in [phaseGroups].
Future<BuildResult> build(List<List<Phase>> phaseGroups) async {
  try {
    _validatePhases(phaseGroups);
    return _runPhases(phaseGroups);
  } catch (e, s) {
    return new BuildResult(BuildStatus.Failure, BuildType.Full, [],
        exception: e, stackTrace: s);
  }
}

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
  if (inputSet.package != _localPackageName) {
    throw new UnimplementedError('Running on packages other than the '
        'local package is not yet supported');
  }

  var files = new Set<File>();
  for (var glob in inputSet.globs) {
    files.addAll(glob.listSync(followLinks: false).where(
        (e) => e is File && !_ignoredDirs.contains(path.split(e.path)[1])));
  }
  return files;
}

/// Runs [builder] with [inputs] as inputs.
Stream<Asset> _runBuilder(Builder builder, List<AssetId> inputs) async* {
  for (var input in inputs) {
    var expectedOutputs = builder.declareOutputs(input);
    var inputAsset = new Asset(input, await _reader.readAsString(input));
    var buildStep =
        new BuildStep(inputAsset, expectedOutputs, _reader, _writer);
    await builder.build(buildStep);
    await buildStep.outputsCompleted;
    for (var output in buildStep.outputs) {
      yield output;
    }
  }
}

/// Very simple [AssetReader], only works on local package and assumes you are
/// running from the root of the package.
class _SimpleAssetReader implements AssetReader {
  const _SimpleAssetReader();

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async {
    assert(id.package == _localPackageName);
    return new File(id.path).readAsString(encoding: encoding);
  }
}

const AssetReader _reader = const _SimpleAssetReader();

/// Very simple [AssetWriter], only works on local package and assumes you are
/// running from the root of the package.
class _SimpleAssetWriter implements AssetWriter {
  final _outputDir;

  const _SimpleAssetWriter(this._outputDir);

  @override
  Future writeAsString(Asset asset, {Encoding encoding: UTF8}) async {
    assert(asset.id.package == _localPackageName);
    var file = new File(path.join(_outputDir, asset.id.path));
    await file.create(recursive: true);
    await file.writeAsString(asset.stringContents, encoding: encoding);
  }
}

const AssetWriter _writer = const _SimpleAssetWriter('generated');

const _ignoredDirs = const ['generated', 'build', 'packages'];
