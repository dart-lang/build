// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:logging/logging.dart';
import 'package:watcher/watcher.dart';

import '../asset/finalized_reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../changes/build_script_updates.dart';
import '../environment/build_environment.dart';
import '../package_graph/apply_builders.dart';
import '../util/constants.dart';
import 'build.dart';
import 'build_definition.dart';
import 'build_directory.dart';
import 'build_result.dart';
import 'options.dart';
import 'phase.dart';

final _logger = Logger('BuildSeries');

/// A series of builds with the same configuration.
///
/// Changes to inputs are tracked to determine what build steps need to rerun
/// each time, for fast "incremental" builds.
///
/// This happens either across multiple invocations of `build_runner build` or
/// within one long-running `build_runner watch` or `build_runner serve`.
///
/// In both cases, the `AssetGraph` is serialized after the build, to give the
/// starting state for the next `build_runner build`. For `watch` and `serve`
/// this serialized state is not actually used: the `AssetGraph` instance
/// already in memory is used directly.
class BuildSeries {
  final BuildEnvironment environment;
  final AssetGraph assetGraph;
  final BuildScriptUpdates? buildScriptUpdates;
  final BuildOptions options;
  final List<BuildPhase> buildPhases;

  final FinalizedReader finalizedReader;
  final AssetReaderWriter readerWriter;
  final RunnerAssetWriter deleteWriter;
  final ResourceManager resourceManager = ResourceManager();

  Future<void> beforeExit() => resourceManager.beforeExit();

  BuildSeries._(
    this.environment,
    this.assetGraph,
    this.buildScriptUpdates,
    this.options,
    this.buildPhases,
    this.finalizedReader,
  ) : deleteWriter = environment.writer.copyWith(
        generatedAssetHider: assetGraph,
      ),
      readerWriter = environment.reader.copyWith(
        generatedAssetHider: assetGraph,
        cache:
            options.enableLowResourcesMode
                ? const PassthroughFilesystemCache()
                : InMemoryFilesystemCache(),
      );

  Future<BuildResult> run(
    Map<AssetId, ChangeType> updates, {
    Set<BuildDirectory> buildDirs = const <BuildDirectory>{},
    Set<BuildFilter> buildFilters = const {},
  }) {
    finalizedReader.reset(BuildDirectory.buildPaths(buildDirs), buildFilters);
    return Build(this, buildDirs, buildFilters).run(updates)
      ..whenComplete(options.resolvers.reset);
  }

  static Future<BuildSeries> create(
    BuildOptions options,
    BuildEnvironment environment,
    List<BuilderApplication> builders,
    Map<String, Map<String, dynamic>> builderConfigOverrides, {
    bool isReleaseBuild = false,
  }) async {
    // Don't allow any changes to the generated asset directory after this
    // point.
    lockGeneratedOutputDirectory();

    var buildPhases = await createBuildPhases(
      options.targetGraph,
      builders,
      builderConfigOverrides,
      isReleaseBuild,
    );
    if (buildPhases.isEmpty) {
      _logger.severe('Nothing can be built, yet a build was requested.');
    }

    var buildDefinition = await BuildDefinition.prepareWorkspace(
      environment,
      options,
      buildPhases,
    );

    var finalizedReader = FinalizedReader(
      environment.reader.copyWith(
        generatedAssetHider: buildDefinition.assetGraph,
      ),
      buildDefinition.assetGraph,
      options.targetGraph,
      buildPhases,
      options.packageGraph.root.name,
    );
    var build = BuildSeries._(
      environment,
      buildDefinition.assetGraph,
      buildDefinition.buildScriptUpdates,
      options,
      buildPhases,
      finalizedReader,
    );
    return build;
  }
}
