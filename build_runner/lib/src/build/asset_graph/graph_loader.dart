// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:built_collection/built_collection.dart';

import '../../bootstrap/build_process_state.dart';
import '../../build_plan/build_phases.dart';
import '../../build_plan/package_graph.dart';
import '../../constants.dart';
import '../../exceptions.dart';
import '../../io/reader_writer.dart';
import '../../logging/build_log.dart';
import 'exceptions.dart';
import 'graph.dart';

/// Loads and verifies an [AssetGraph].
class AssetGraphLoader {
  final ReaderWriter readerWriter;
  final PackageGraph packageGraph;
  final BuildPhases buildPhases;

  AssetGraphLoader({
    required this.readerWriter,
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
    if (!await readerWriter.canRead(assetGraphId)) {
      return null;
    }

    try {
      return await _load(assetGraphId);
    } on AssetGraphCorruptedException catch (_) {
      // Start fresh if the cached asset_graph cannot be deserialized
      buildLog.fullBuildBecause(FullBuildReason.incompatibleAssetGraph);
      await Future.wait([
        readerWriter.deleteDirectory(_generatedOutputDirectoryId),
      ]);
      return null;
    }
  }

  Future<AssetGraph?> _load(AssetId assetGraphId) async {
    final cachedGraph = AssetGraph.deserialize(
      await readerWriter.readAsBytes(assetGraphId),
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
        readerWriter.delete(assetGraphId),
        cachedGraph.deleteOutputs(packageGraph, readerWriter),
        readerWriter.deleteDirectory(_generatedOutputDirectoryId),
      ]);
      if (_runningFromSnapshot) {
        throw const BuildScriptChangedException();
      }
      return null;
    }
    if (!isSameSdkVersion(cachedGraph.dartVersion, Platform.version)) {
      buildLog.fullBuildBecause(FullBuildReason.incompatibleBuild);
      await Future.wait([
        readerWriter.delete(assetGraphId),
        cachedGraph.deleteOutputs(packageGraph, readerWriter),
        readerWriter.deleteDirectory(_generatedOutputDirectoryId),
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

/// Checks whether [thisVersion] and [thatVersion] have the same semver
/// identifier without extra platform specific information.
bool isSameSdkVersion(String? thisVersion, String? thatVersion) =>
    thisVersion?.split(' ').first == thatVersion?.split(' ').first;
