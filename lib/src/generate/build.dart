// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import '../asset/cache.dart';
import '../asset/file_based.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../package_graph/package_graph.dart';
import '../server/server.dart';
import 'build_impl.dart';
import 'build_result.dart';
import 'directory_watcher_factory.dart';
import 'phase.dart';
import 'watch_impl.dart';

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
///
/// The [teminateEventStream] is a stream which can send termination events.
/// By default the [ProcessSignal.SIGINT] stream is used. In this mode, it
/// will simply consume the first event and allow the build to continue.
/// Multiple termination events will cause a normal shutdown.
Future<BuildResult> build(List<List<Phase>> phaseGroups,
    {PackageGraph packageGraph,
    AssetReader reader,
    AssetWriter writer,
    Level logLevel,
    onLog(LogRecord),
    Stream terminateEventStream}) async {
  var logListener = _setupLogging(logLevel: logLevel, onLog: onLog);
  packageGraph ??= new PackageGraph.forThisPackage();
  var cache = new AssetCache();
  reader ??=
      new CachedAssetReader(cache, new FileBasedAssetReader(packageGraph));
  writer ??=
      new CachedAssetWriter(cache, new FileBasedAssetWriter(packageGraph));

  var buildImpl = new BuildImpl(reader, writer, packageGraph, phaseGroups);

  /// Run the build!
  var futureResult = buildImpl.runBuild();

  // Stop doing new builds when told to terminate.
  var listener = _setupTerminateLogic(terminateEventStream, () {
    new Logger('Build').info('Waiting for build to finish...');
    return futureResult;
  });

  var result = await futureResult;
  listener.cancel();
  logListener.cancel();
  return result;
}

/// Same as [build], except it watches the file system and re-runs builds
/// automatically.
///
/// The [debounceDelay] controls how often builds will run. As long as files
/// keep changing with less than that amount of time apart, builds will be put
/// off.
///
/// The [directoryWatcherFactory] allows you to inject a way of creating custom
/// [DirectoryWatcher]s. By default a normal [DirectoryWatcher] will be used.
///
/// The [teminateEventStream] is a stream which can send termination events.
/// By default the [ProcessSignal.SIGINT] stream is used. In this mode, the
/// first event will allow any ongoing builds to finish, and then the program
///  will complete normally. Subsequent events are not handled (and will
///  typically cause a shutdown).
Stream<BuildResult> watch(List<List<Phase>> phaseGroups,
    {PackageGraph packageGraph,
    AssetReader reader,
    AssetWriter writer,
    Level logLevel,
    onLog(LogRecord),
    Duration debounceDelay: const Duration(milliseconds: 250),
    DirectoryWatcherFactory directoryWatcherFactory,
    Stream terminateEventStream}) {
  // We never cancel this listener in watch mode, because we never exit unless
  // forced to.
  var logListener = _setupLogging(logLevel: logLevel, onLog: onLog);
  packageGraph ??= new PackageGraph.forThisPackage();
  var cache = new AssetCache();
  reader ??=
      new CachedAssetReader(cache, new FileBasedAssetReader(packageGraph));
  writer ??=
      new CachedAssetWriter(cache, new FileBasedAssetWriter(packageGraph));
  directoryWatcherFactory ??= defaultDirectoryWatcherFactory;
  var watchImpl = new WatchImpl(directoryWatcherFactory, debounceDelay, reader,
      writer, packageGraph, phaseGroups);

  var resultStream = watchImpl.runWatch();

  // Stop doing new builds when told to terminate.
  _setupTerminateLogic(terminateEventStream, () async {
    await watchImpl.terminate();
    logListener.cancel();
  });

  return resultStream;
}

/// Same as [watch], except it also provides a server. This server will block
/// all requests if a build is current in process.
Stream<BuildResult> serve(List<List<Phase>> phaseGroups,
    {PackageGraph packageGraph,
    AssetReader reader,
    AssetWriter writer,
    Level logLevel,
    onLog(LogRecord),
    Duration debounceDelay: const Duration(milliseconds: 250),
    DirectoryWatcherFactory directoryWatcherFactory,
    Stream terminateEventStream}) {
  // We never cancel this listener in watch mode, because we never exit unless
  // forced to.
  var logListener = _setupLogging(logLevel: logLevel, onLog: onLog);
  packageGraph ??= new PackageGraph.forThisPackage();
  var cache = new AssetCache();
  reader ??=
      new CachedAssetReader(cache, new FileBasedAssetReader(packageGraph));
  writer ??=
      new CachedAssetWriter(cache, new FileBasedAssetWriter(packageGraph));
  directoryWatcherFactory ??= defaultDirectoryWatcherFactory;
  var watchImpl = new WatchImpl(directoryWatcherFactory, debounceDelay, reader,
      writer, packageGraph, phaseGroups);

  var resultStream = watchImpl.runWatch();

  startServer(watchImpl);

  // Stop doing new builds when told to terminate.
  _setupTerminateLogic(terminateEventStream, () async {
    await watchImpl.terminate();
    await stopServer();
    logListener.cancel();
  });

  return resultStream;
}

/// Given [terminateEventStream], call [onTerminate] the first time an event is
/// seen. If a second event is recieved, simply exit.
StreamSubscription _setupTerminateLogic(
    Stream terminateEventStream, Future onTerminate()) {
  terminateEventStream ??= ProcessSignal.SIGINT.watch();
  int numEventsSeen = 0;
  var terminateListener;
  terminateListener = terminateEventStream.listen((_) {
    numEventsSeen++;
    if (numEventsSeen == 1) {
      onTerminate().then((_) {
        terminateListener.cancel();
      });
    } else {
      exit(2);
    }
  });
  return terminateListener;
}

StreamSubscription _setupLogging({Level logLevel, onLog(LogRecord)}) {
  logLevel ??= Level.INFO;
  Logger.root.level = logLevel;
  onLog ??= stdout.writeln;
  return Logger.root.onRecord.listen(onLog);
}
