// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:built_collection/built_collection.dart';
// ignore: implementation_imports
import 'package:logging/logging.dart';

import '../asset/writer.dart';
import '../asset_graph/exceptions.dart';
import '../asset_graph/graph.dart';
import '../generate/build_phases.dart';
import '../generate/exceptions.dart';
import '../logging/failure_reporter.dart';
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';
import '../util/constants.dart';
import '../util/sdk_version_match.dart';

final _logger = Logger('AssetGraphLoader');

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
    final assetGraphId = AssetId(packageGraph.root.name, assetGraphPath);
    if (!await reader.canRead(assetGraphId)) {
      return null;
    }

    return logTimedAsync(_logger, 'Reading cached asset graph', () async {
      try {
        return await _load(assetGraphId);
      } on AssetGraphCorruptedException catch (_) {
        // Start fresh if the cached asset_graph cannot be deserialized
        _logger.warning(
          'Throwing away cached asset graph due to '
          'version mismatch or corrupted asset graph.',
        );
        await Future.wait([
          writer.deleteDirectory(_generatedOutputDirectoryId),
          FailureReporter.cleanErrorCache(),
        ]);
        return null;
      }
    });
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
      if (buildPhasesChanged) {
        _logger.warning(
          'Throwing away cached asset graph because the build phases '
          'have changed. This most commonly would happen as a result of '
          'adding a new dependency or updating your dependencies.',
        );
      }
      if (pkgVersionsChanged) {
        _logger.warning(
          'Throwing away cached asset graph because the language '
          'version of some package(s) changed. This would most commonly '
          'happen when updating dependencies or changing your min sdk '
          'constraint.',
        );
      }
      if (enabledExperimentsChanged) {
        _logger.warning(
          'Throwing away cached asset graph because the enabled Dart '
          'language experiments changed:\n\n'
          'Previous value: ${cachedGraph.enabledExperiments.join(' ')}\n'
          'Current value: ${enabledExperiments.join(' ')}',
        );
      }
      await Future.wait([
        writer.delete(assetGraphId),
        cachedGraph.deleteOutputs(packageGraph, writer),
        writer.deleteDirectory(_generatedOutputDirectoryId),
        FailureReporter.cleanErrorCache(),
      ]);
      if (_runningFromSnapshot) {
        throw const BuildScriptChangedException();
      }
      return null;
    }
    if (!isSameSdkVersion(cachedGraph.dartVersion, Platform.version)) {
      _logger.warning(
        'Throwing away cached asset graph due to Dart SDK update.',
      );
      await Future.wait([
        writer.delete(assetGraphId),
        cachedGraph.deleteOutputs(packageGraph, writer),
        writer.deleteDirectory(_generatedOutputDirectoryId),
        FailureReporter.cleanErrorCache(),
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
