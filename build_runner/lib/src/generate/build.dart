// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:watcher/watcher.dart';

import '../logging/std_io_logging.dart';
import '../package_graph/build_config_overrides.dart';
import '../server/server.dart';
import 'terminator.dart';
import 'watch_impl.dart' as watch_impl;

/// Runs all of the BuilderApplications in [builders] once.
///
/// By default, the user will be prompted to delete any files which already
/// exist but were not generated by this specific build script. The
/// [deleteFilesByDefault] option can be set to `true` to skip this prompt.
///
/// A [packageGraph] may be supplied, otherwise one will be constructed using
/// [PackageGraph.forThisPackage]. The default functionality assumes you are
/// running in the root directory of a package, with both a `pubspec.yaml` and
/// `.dart_tool/package_config.json` file present.
///
/// A [reader] and [writer] may also be supplied, which can read/write assets
/// to arbitrary locations or file systems. By default they will write directly
/// to the root package directory, and will use the [packageGraph] to know where
/// to read files from.
///
/// Logging may be customized by passing a custom [logLevel] below which logs
/// will be ignored, as well as an [onLog] handler which defaults to [print].
///
/// The [terminateEventStream] is a stream which can send termination events.
/// By default the [ProcessSignal.sigint] stream is used. In this mode, it
/// will simply consume the first event and allow the build to continue.
/// Multiple termination events will cause a normal shutdown.
///
/// If [outputSymlinksOnly] is `true`, then the merged output directories will
/// contain only symlinks, which is much faster but not generally suitable for
/// deployment.
///
/// If [verbose] is `true` then verbose logging will be enabled. This changes
/// the default [logLevel] to [Level.ALL] and removes stack frame folding, among
/// other things.
Future<BuildResult> build(List<BuilderApplication> builders,
    {bool? deleteFilesByDefault,
    bool? assumeTty,
    String? configKey,
    PackageGraph? packageGraph,
    RunnerAssetReader? reader,
    RunnerAssetWriter? writer,
    Resolvers? resolvers,
    Level? logLevel,
    void Function(LogRecord)? onLog,
    Stream<ProcessSignal>? terminateEventStream,
    bool? enableLowResourcesMode,
    Set<BuildDirectory>? buildDirs,
    bool? outputSymlinksOnly,
    bool? trackPerformance,
    bool? skipBuildScriptCheck,
    bool? verbose,
    bool? isReleaseBuild,
    Map<String, Map<String, dynamic>>? builderConfigOverrides,
    String? logPerformanceDir,
    Set<BuildFilter>? buildFilters}) async {
  builderConfigOverrides ??= const {};
  buildDirs ??= <BuildDirectory>{};
  buildFilters ??= <BuildFilter>{};
  deleteFilesByDefault ??= false;
  enableLowResourcesMode ??= false;
  isReleaseBuild ??= false;
  outputSymlinksOnly ??= false;
  packageGraph ??= await PackageGraph.forThisPackage();
  skipBuildScriptCheck ??= false;
  trackPerformance ??= false;
  verbose ??= false;
  var environment = OverrideableEnvironment(
      IOEnvironment(
        packageGraph,
        assumeTty: assumeTty,
        outputSymlinksOnly: outputSymlinksOnly,
      ),
      reader: reader,
      writer: writer,
      onLog: onLog ?? stdIOLogListener(assumeTty: assumeTty, verbose: verbose));
  var logSubscription =
      LogSubscription(environment, verbose: verbose, logLevel: logLevel);
  var options = await BuildOptions.create(
    logSubscription,
    deleteFilesByDefault: deleteFilesByDefault,
    packageGraph: packageGraph,
    skipBuildScriptCheck: skipBuildScriptCheck,
    overrideBuildConfig: await findBuildConfigOverrides(
        packageGraph, environment.reader,
        configKey: configKey),
    enableLowResourcesMode: enableLowResourcesMode,
    trackPerformance: trackPerformance,
    logPerformanceDir: logPerformanceDir,
    resolvers: resolvers,
  );
  var terminator = Terminator(terminateEventStream);
  try {
    return await runWithFileSystemBatch(() async {
      var build = await BuildRunner.create(
        options,
        environment,
        builders,
        builderConfigOverrides!,
        isReleaseBuild: isReleaseBuild!,
      );
      var result = await build
          .run({}, buildDirs: buildDirs!, buildFilters: buildFilters!);
      await build.beforeExit();
      return result;
    }, environment.writer);
  } finally {
    await terminator.cancel();
    await options.logListener.cancel();
  }
}

/// Same as [build], except it watches the file system and re-runs builds
/// automatically.
///
/// Call [ServeHandler.handlerFor] to create a [Handler] for use with
/// `package:shelf`. Requests for assets will be blocked while builds are
/// running then served with the latest version of the asset. Only source and
/// generated assets can be served through this handler.
///
/// The [debounceDelay] controls how often builds will run. As long as files
/// keep changing with less than that amount of time apart, builds will be put
/// off.
///
/// The [directoryWatcherFactory] allows you to inject a way of creating custom
/// `DirectoryWatcher`s. By default a normal `DirectoryWatcher` will be used.
///
/// The [terminateEventStream] is a stream which can send termination events.
/// By default the [ProcessSignal.sigint] stream is used. In this mode, the
/// first event will allow any ongoing builds to finish, and then the program
/// will complete normally. Subsequent events are not handled (and will
/// typically cause a shutdown).
Future<ServeHandler> watch(List<BuilderApplication> builders,
        {bool? deleteFilesByDefault,
        bool? assumeTty,
        String? configKey,
        PackageGraph? packageGraph,
        RunnerAssetReader? reader,
        RunnerAssetWriter? writer,
        Resolvers? resolvers,
        Level? logLevel,
        void Function(LogRecord)? onLog,
        Duration? debounceDelay,
        required DirectoryWatcher Function(String) directoryWatcherFactory,
        Stream<ProcessSignal>? terminateEventStream,
        bool? enableLowResourcesMode,
        Set<BuildDirectory>? buildDirs,
        bool? outputSymlinksOnly,
        bool? trackPerformance,
        bool? skipBuildScriptCheck,
        bool? verbose,
        bool? isReleaseBuild,
        Map<String, Map<String, dynamic>>? builderConfigOverrides,
        String? logPerformanceDir,
        Set<BuildFilter>? buildFilters}) =>
    watch_impl.watch(
      builders,
      assumeTty: assumeTty,
      deleteFilesByDefault: deleteFilesByDefault,
      configKey: configKey,
      packageGraph: packageGraph,
      reader: reader,
      writer: writer,
      resolvers: resolvers,
      logLevel: logLevel,
      onLog: onLog,
      debounceDelay: debounceDelay,
      directoryWatcherFactory: directoryWatcherFactory,
      terminateEventStream: terminateEventStream,
      enableLowResourcesMode: enableLowResourcesMode,
      buildDirs: buildDirs,
      outputSymlinksOnly: outputSymlinksOnly,
      trackPerformance: trackPerformance,
      skipBuildScriptCheck: skipBuildScriptCheck,
      verbose: verbose,
      builderConfigOverrides: builderConfigOverrides,
      isReleaseBuild: isReleaseBuild,
      logPerformanceDir: logPerformanceDir,
      buildFilters: buildFilters,
    );
