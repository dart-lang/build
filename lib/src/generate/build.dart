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
import '../asset_graph/graph.dart';
import '../package_graph/package_graph.dart';
import 'build_impl.dart';
import 'build_result.dart';
import 'phase.dart';
import 'directory_watcher_factory.dart';

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

  var buildImpl = new BuildImpl(
      cache, new AssetGraph(), reader, writer, packageGraph, phaseGroups);

  /// Run the build!
  var futureResult = buildImpl.runBuild();

  // Handle the first SIGINT, and shut down gracefully.
  terminateEventStream ??= ProcessSignal.SIGINT.watch();
  int numEventsSeen = 0;
  var terminateListener = terminateEventStream.listen((_) {
    numEventsSeen++;
    if (numEventsSeen == 1) {
      new Logger('Build').info('Waiting for build to finish...');
    } else {
      exit(2);
    }
  });

  return futureResult.then((result) async {
    await logListener.cancel();
    await terminateListener.cancel();
    return result;
  });
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
  _setupLogging(logLevel: logLevel, onLog: onLog);
  packageGraph ??= new PackageGraph.forThisPackage();
  var cache = new AssetCache();
  reader ??=
      new CachedAssetReader(cache, new FileBasedAssetReader(packageGraph));
  writer ??=
      new CachedAssetWriter(cache, new FileBasedAssetWriter(packageGraph));
  directoryWatcherFactory ??= defaultDirectoryWatcherFactory;
  var watchImpl = new WatchImpl(directoryWatcherFactory, debounceDelay, cache,
      new AssetGraph(), reader, writer, packageGraph, phaseGroups);

  var resultStream = watchImpl.runWatch();

  // Handle the first SIGINT, and shut down gracefully. Second one causes a
  // full shutdown.
  terminateEventStream ??= ProcessSignal.SIGINT.watch();
  int numEventsSeen = 0;
  var terminateListener;
  terminateListener = terminateEventStream.listen((_) {
    numEventsSeen++;
    if (numEventsSeen == 1) {
      watchImpl.terminate().then((_) {
        terminateListener.cancel();
      });
    } else {
      exit(2);
    }
  });

  return resultStream;
}

StreamSubscription _setupLogging({Level logLevel, onLog(LogRecord)}) {
  logLevel ??= Level.INFO;
  Logger.root.level = logLevel;
  onLog ??= stdout.writeln;
  return Logger.root.onRecord.listen(onLog);
}
