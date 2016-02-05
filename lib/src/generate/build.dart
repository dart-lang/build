// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../asset/asset.dart';
import '../asset/cache.dart';
import '../asset/file_based.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../builder/builder.dart';
import '../builder/build_step_impl.dart';
import '../package_graph/package_graph.dart';
import 'build_result.dart';
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
  // No need to create a package graph if we were supplied a reader/writer.
  packageGraph ??= new PackageGraph.forThisPackage();
  var cache = new AssetCache();
  reader ??=
      new CachedAssetReader(cache, new FileBasedAssetReader(packageGraph));
  writer ??=
      new CachedAssetWriter(cache, new FileBasedAssetWriter(packageGraph));
  var result = runZoned(() {
    return _runPhases(phaseGroups);
  }, onError: (e, s) {
    return new BuildResult(BuildStatus.Failure, BuildType.Full, [],
        exception: e, stackTrace: s);
  }, zoneValues: {
    _assetReaderKey: reader,
    _assetWriterKey: writer,
    _packageGraphKey: packageGraph,
  });
  await logListener.cancel();
  return result;
}

/// Keys for reading zone local values.
Symbol _assetReaderKey = #buildAssetReader;
Symbol _assetWriterKey = #buildAssetWriter;
Symbol _packageGraphKey = #buildPackageGraph;

/// Getters for zone local values.
AssetReader get _reader => Zone.current[_assetReaderKey];
AssetWriter get _writer => Zone.current[_assetWriterKey];
PackageGraph get _packageGraph => Zone.current[_packageGraphKey];

/// Runs the [phaseGroups] and returns a [Future<BuildResult>] which completes
/// once all [Phase]s are done.
Future<BuildResult> _runPhases(List<List<Phase>> phaseGroups) async {
  var outputs = [];
  for (var group in phaseGroups) {
    for (var phase in group) {
      var inputs = (await _reader.listAssetIds(phase.inputSets).toList())
          .where(_isValidInput);
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

/// Checks if an [input] is valid.
bool _isValidInput(AssetId input) {
  var parts = path.split(input.path);
  // Files must be in a top level directory.
  if (parts.length == 1) return false;
  if (input.package != _packageGraph.root.name) return parts[0] == 'lib';
  return true;
}

/// Runs [builder] with [inputs] as inputs.
Stream<Asset> _runBuilder(Builder builder, Iterable<AssetId> inputs) async* {
  for (var input in inputs) {
    var expectedOutputs = builder.declareOutputs(input);
    var inputAsset = new Asset(input, await _reader.readAsString(input));
    var buildStep =
        new BuildStepImpl(inputAsset, expectedOutputs, _reader, _writer);
    await builder.build(buildStep);
    await buildStep.complete();
    for (var output in buildStep.outputs) {
      yield output;
    }
  }
}
