// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_daemon/daemon_builder.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart' hide OutputLocation;
import 'package:build_daemon/data/server_log.dart';
import 'package:build_runner/src/entrypoint/options.dart';
import 'package:build_runner/src/package_graph/build_config_overrides.dart';
import 'package:build_runner/src/watcher/asset_change.dart';
import 'package:build_runner/src/watcher/change_filter.dart';
import 'package:build_runner/src/watcher/collect_changes.dart';
import 'package:build_runner/src/watcher/delete_writer.dart';
import 'package:build_runner/src/watcher/graph_watcher.dart';
import 'package:build_runner/src/watcher/node_watcher.dart';
import 'package:build_runner_core/build_runner_core.dart'
    hide BuildResult, BuildStatus;
import 'package:build_runner_core/build_runner_core.dart' as core
    show BuildStatus;
import 'package:build_runner_core/src/generate/build_impl.dart';
import 'package:logging/logging.dart';
import 'package:watcher/watcher.dart';

/// A Daemon Builder that uses build_runner_core for building.
class BuildRunnerDaemonBuilder implements DaemonBuilder {
  final _buildResults = StreamController<BuildResults>();

  final BuildImpl _builder;
  final BuildOptions _buildOptions;
  final StreamController<ServerLog> _outputStreamController;
  final Stream<WatchEvent> _changes;

  Completer<Null> _buildingCompleter;

  @override
  final Stream<ServerLog> logs;

  BuildRunnerDaemonBuilder._(
    this._builder,
    this._buildOptions,
    this._outputStreamController,
    this._changes,
  ) : logs = _outputStreamController.stream.asBroadcastStream();

  /// Waits for a running build to complete before returning.
  ///
  /// If there is no running build, it will return immediately.
  Future<void> get building => _buildingCompleter?.future;

  @override
  Stream<BuildResults> get builds => _buildResults.stream;

  Stream<WatchEvent> get changes => _changes;

  FinalizedReader get reader => _builder.finalizedReader;

  @override
  Future<void> build(
      Set<BuildTarget> targets, Iterable<WatchEvent> fileChanges) async {
    var defaultTargets = targets.cast<DefaultBuildTarget>();
    var changes = fileChanges
        .map<AssetChange>(
            (change) => AssetChange(AssetId.parse(change.path), change.type))
        .toList();
    var targetNames = targets.map((t) => t.target).toSet();
    _logMessage(Level.INFO, 'About to build ${targetNames.toList()}...');
    _signalStart(targetNames);
    var results = <BuildResult>[];
    var buildDirs = defaultTargets.map((target) {
      OutputLocation outputLocation;
      if (target.outputLocation != null) {
        outputLocation = OutputLocation(target.outputLocation.output,
            useSymlinks: target.outputLocation.useSymlinks,
            hoist: target.outputLocation.hoist);
      }
      return BuildDirectory(
        target.target,
        outputLocation: outputLocation,
      );
    }).toSet();
    try {
      var mergedChanges = collectChanges([changes]);
      var result = await _builder.run(mergedChanges, buildDirs: buildDirs);
      for (var target in targets) {
        if (result.status == core.BuildStatus.success) {
          // TODO(grouma) - Can we notify if a target was cached?
          results.add(DefaultBuildResult((b) => b
            ..status = BuildStatus.succeeded
            ..target = target.target));
        } else {
          results.add(DefaultBuildResult((b) => b
            ..status = BuildStatus.failed
            // TODO(grouma) - We should forward the error messages instead.
            // We can use the AssetGraph and FailureReporter to provide a better
            // error message.
            ..error = 'FailureType: ${result.failureType.exitCode}'
            ..target = target.target));
        }
      }
    } catch (e) {
      for (var target in targets) {
        results.add(DefaultBuildResult((b) => b
          ..status = BuildStatus.failed
          ..error = '$e'
          ..target = target.target));
      }
      _logMessage(Level.SEVERE, 'Build Failed:\n${e.toString()}');
    }
    _signalEnd(results);
  }

  @override
  Future<void> stop() async {
    await _builder.beforeExit();
    await _buildOptions.logListener.cancel();
  }

  void _logMessage(Level level, String message) =>
      _outputStreamController.add(ServerLog(
        (b) => b.log = '[$level] $message',
      ));

  void _signalEnd(Iterable<BuildResult> results) {
    _buildingCompleter.complete();
    _buildResults.add(BuildResults((b) => b..results.addAll(results)));
  }

  void _signalStart(Iterable<String> targets) {
    _buildingCompleter = Completer();
    var results = <BuildResult>[];
    for (var target in targets) {
      results.add(DefaultBuildResult((b) => b
        ..status = BuildStatus.started
        ..target = target));
    }
    _buildResults.add(BuildResults((b) => b..results.addAll(results)));
  }

  static Future<BuildRunnerDaemonBuilder> create(
    PackageGraph packageGraph,
    List<BuilderApplication> builders,
    SharedOptions sharedOptions,
  ) async {
    var expectedDeletes = Set<AssetId>();
    var outputStreamController = StreamController<ServerLog>();

    var environment = OverrideableEnvironment(
        IOEnvironment(packageGraph,
            outputSymlinksOnly: sharedOptions.outputSymlinksOnly),
        onLog: (record) {
      outputStreamController.add(ServerLog((b) => b.log = record.toString()));
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
              // Assume we will create an outputDir.
              true,
              expectedDeletes,
            ));

    var changes =
        graphEvents.map((data) => WatchEvent(data.type, '${data.id}'));

    return BuildRunnerDaemonBuilder._(
        builder, buildOptions, outputStreamController, changes);
  }
}
