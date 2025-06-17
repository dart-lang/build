// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:built_collection/built_collection.dart';

import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../build_script_generate/build_process_state.dart';
import '../experiments.dart';
import '../generate/build_phases.dart';
import '../generate/exceptions.dart';
import '../logging/build_log.dart';
import '../package_graph/package_graph.dart';
import '../util/constants.dart';
import '../util/sdk_version_match.dart';
import 'exceptions.dart';
import 'graph.dart';

/// Loads and verifies an [AssetGraph].
class AssetGraphLoader {
  final AssetReader reader;
  final RunnerAssetWriter writer;
  final PackageGraph packageGraph;
  final BuildPhases buildPhases;

  AssetGraphLoader({
    required this.reader,
    required this.writer,
    required this.packageGraph,
    required this.buildPhases,
  });

  /// Loads and verifies an [AssetGraph].
  ///
  /// If there is no graph on disk, just returns `null`.
  ///
  /// If something has changed that invalidates the graph:
  ///
  ///  - deletes the invalid graph
  ///  - deletes outputs
  ///  - deletes the generated output directory
  ///  - if running from a snapshot, throws `BuildScriptChangedException`,
  ///    otherwise returns `null`
  Future<AssetGraph?> load() async {
    buildLog.doing('Reading the asset graph.');
    final assetGraphId = AssetId(packageGraph.root.name, assetGraphPath);
    if (!await reader.canRead(assetGraphId)) {
      return null;
    }

    try {
      return await _load(assetGraphId);
    } on AssetGraphCorruptedException catch (_) {
      // Start fresh if the cached asset_graph cannot be deserialized
      buildLog.fullBuildBecause(FullBuildReason.incompatibleAssetGraph);
      await Future.wait([writer.deleteDirectory(_generatedOutputDirectoryId)]);
      return null;
    }
  }

  Future<AssetGraph?> _load(AssetId assetGraphId) async {
    final cachedGraph = AssetGraph.deserialize(
      await reader.readAsBytes(assetGraphId),
    );
    final buildPhasesChanged =
        buildPhases.digest != cachedGraph.buildPhasesDigest;
    final pkgVersionsChanged =
        cachedGraph.packageLanguageVersions != packageGraph.languageVersions;
    final enabledExperimentsChanged =
        cachedGraph.enabledExperiments != enabledExperiments.build();
    if (buildPhasesChanged || pkgVersionsChanged || enabledExperimentsChanged) {
      buildLog.fullBuildBecause(FullBuildReason.incompatibleBuild);
      await Future.wait([
        writer.delete(assetGraphId),
        cachedGraph.deleteOutputs(packageGraph, writer),
        writer.deleteDirectory(_generatedOutputDirectoryId),
      ]);
      if (_runningFromSnapshot) {
        throw const BuildScriptChangedException();
      }
      return null;
    }
    if (!isSameSdkVersion(cachedGraph.dartVersion, Platform.version)) {
      buildLog.fullBuildBecause(FullBuildReason.incompatibleBuild);
      await Future.wait([
        writer.delete(assetGraphId),
        cachedGraph.deleteOutputs(packageGraph, writer),
        writer.deleteDirectory(_generatedOutputDirectoryId),
      ]);
      if (_runningFromSnapshot) {
        throw const BuildScriptChangedException();
      }
      return null;
    }

    // Move old build phases digests to "previous" fields, set the new ones.
    // These are used to check for phases to fully rerun due to changed options.
    cachedGraph.previousInBuildPhasesOptionsDigests =
        cachedGraph.inBuildPhasesOptionsDigests;
    cachedGraph.inBuildPhasesOptionsDigests =
        buildPhases.inBuildPhasesOptionsDigests;
    cachedGraph.previousPostBuildActionsOptionsDigests =
        cachedGraph.postBuildActionsOptionsDigests;
    cachedGraph.postBuildActionsOptionsDigests =
        buildPhases.postBuildActionsOptionsDigests;

    return cachedGraph;
  }

  AssetId get _generatedOutputDirectoryId =>
      AssetId(packageGraph.root.name, generatedOutputDirectory);
}

bool get _runningFromSnapshot => !Platform.script.path.endsWith('.dart');
