// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_daemon/daemon_builder.dart';
import 'package:build_daemon/data/build_status.dart' as daemon;
import 'package:build_daemon/data/server_log.dart';
import 'package:build_runner/src/entrypoint/options.dart';
import 'package:build_runner/src/package_graph/build_config_overrides.dart';
import 'package:build_runner/src/watcher/asset_change.dart';
import 'package:build_runner/src/watcher/change_filter.dart';
import 'package:build_runner/src/watcher/collect_changes.dart';
import 'package:build_runner/src/watcher/delete_writer.dart';
import 'package:build_runner/src/watcher/graph_watcher.dart';
import 'package:build_runner/src/watcher/node_watcher.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/generate/build_impl.dart';
import 'package:logging/logging.dart';
import 'package:watcher/watcher.dart';

/// A Daemon Builder that uses build_runner_core for building.
class BuildRunnerDaemonBuilder implements DaemonBuilder {
  final _buildResults = StreamController<daemon.BuildResults>();
  final _changesFromLastBuild = <AssetChange>[];

  final BuildImpl _builder;
  final BuildOptions _buildOptions;
  final StreamController<ServerLog> _outputStreamController;
  final Stream<AssetChange> _graphEvents;
  Stream<WatchEvent> _changes;

  BuildRunnerDaemonBuilder._(
    this._builder,
    this._buildOptions,
    this._outputStreamController,
    this._graphEvents,
  ) {
    _changes = _graphEvents.map((data) {
      _changesFromLastBuild.add(data);
      return WatchEvent(data.type, data.id.path);
    });
  }

  @override
  Stream<daemon.BuildResults> get builds => _buildResults.stream;

  Stream<WatchEvent> get changes => _changes;

  @override
  Stream<ServerLog> get logs => _outputStreamController.stream;

  @override
  Future<void> build(Set<String> targets, Set<String> logToPaths) async {
    _logMessage(Level.INFO, 'About to build $targets...');
    try {
      var mergedChanges = collectChanges([_changesFromLastBuild]);
      var result =
          await _builder.run(mergedChanges, buildDirs: targets.toList());
      var results = <daemon.BuildResult>[];
      for (var target in targets) {
        if (result.status == BuildStatus.success) {
          // TODO(grouma) - Can we notify if a target was cached?
          results.add(daemon.DefaultBuildResult((b) => b
            ..status = daemon.BuildStatus.succeeded
            ..target = target));
        } else {
          results.add(daemon.DefaultBuildResult((b) => b
            ..status = daemon.BuildStatus.failed
            // TODO(grouma) - We should forward the error messages instead.
            // We can use the AssetGraph and FailureReporter to provide a better
            // error message.
            ..error = 'FailureType: ${result.failureType.exitCode}'
            ..target = target));
        }
      }
      _buildResults.add(daemon.BuildResults((b) => b..results.addAll(results)));
    } catch (e) {
      var results = <daemon.BuildResult>[];
      for (var target in targets) {
        results.add(daemon.DefaultBuildResult((b) => b
          ..status = daemon.BuildStatus.failed
          ..error = '$e'
          ..target = target));
      }
      _buildResults.add(daemon.BuildResults((b) => b..results.addAll(results)));
      _logMessage(Level.SEVERE, 'Build Failed:\n${e.toString()}');
    }
    _changesFromLastBuild.clear();
  }

  @override
  Future<void> stop() async {
    await _builder.beforeExit();
    await _buildOptions.logListener.cancel();
  }

  void _logMessage(Level level, String message) {
    // TODO(grouma) - use the logic in std_io_logging.dart to include color.
    _outputStreamController.add(ServerLog((b) => b.log =
        LogRecord(level, message, 'BuildRunnerBuildDaemon').toString()));
  }

  static Future<BuildRunnerDaemonBuilder> create(
    PackageGraph packageGraph,
    List<BuilderApplication> builders,
    SharedOptions sharedOptions,
  ) async {
    var expectedDeletes = Set<AssetId>();
    var outputStreamController = StreamController<ServerLog>();

    var environment =
        OverrideableEnvironment(IOEnvironment(packageGraph), onLog: (record) {
      // Print here as well so that severe errors can be caught by the
      // daemon client.
      print(record);
      outputStreamController.add(ServerLog((b) => b.log = '$record'));
    });

    var daemonEnvironment = OverrideableEnvironment(environment,
        writer: OnDeleteWriter(environment.writer, expectedDeletes.add));

    var logSubscription =
        LogSubscription(environment, verbose: sharedOptions.verbose);

    var overrideBuildConfig =
        await findBuildConfigOverrides(packageGraph, sharedOptions.configKey);

    var buildOptions = await BuildOptions.create(
      logSubscription,
      packageGraph: packageGraph,
      deleteFilesByDefault: sharedOptions.deleteFilesByDefault,
      overrideBuildConfig: overrideBuildConfig,
      skipBuildScriptCheck: sharedOptions.skipBuildScriptCheck,
      enableLowResourcesMode: sharedOptions.enableLowResourcesMode,
      trackPerformance: sharedOptions.trackPerformance,
      logPerformanceDir: sharedOptions.logPerformanceDir,
    );

    var builder = await BuildImpl.create(buildOptions, daemonEnvironment,
        builders, sharedOptions.builderConfigOverrides,
        isReleaseBuild: sharedOptions.isReleaseBuild);

    var graphEvents = PackageGraphWatcher(packageGraph,
            watch: (node) => PackageNodeWatcher(node,
                watch: (path) => Platform.isWindows
                    ? PollingDirectoryWatcher(path)
                    : DirectoryWatcher(path)))
        .watch()
        .where((change) => shouldProcess(
              change,
              builder.assetGraph,
              buildOptions,
              sharedOptions.outputMap?.isNotEmpty == true,
              expectedDeletes,
            ));

    return BuildRunnerDaemonBuilder._(
        builder, buildOptions, outputStreamController, graphEvents);
  }
}
