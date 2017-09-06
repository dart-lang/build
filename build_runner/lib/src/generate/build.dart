// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../asset/reader.dart';
import '../asset/writer.dart';
import '../package_graph/package_graph.dart';
import '../server/server.dart';
import 'build_impl.dart';
import 'build_result.dart';
import 'directory_watcher_factory.dart';
import 'options.dart';
import 'phase.dart';
import 'watch_impl.dart';

/// Runs all of the actions in [buildActions] once.
///
/// By default, the user will be prompted to delete any files which already
/// exist but were not generated by this specific build script. The
/// [deleteFilesByDefault] option can be set to [true] to skip this prompt.
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
/// The [terminateEventStream] is a stream which can send termination events.
/// By default the [ProcessSignal.SIGINT] stream is used. In this mode, it
/// will simply consume the first event and allow the build to continue.
/// Multiple termination events will cause a normal shutdown.
Future<BuildResult> build(List<BuildAction> buildActions,
    {bool deleteFilesByDefault,
    bool writeToCache,
    PackageGraph packageGraph,
    RunnerAssetReader reader,
    RunnerAssetWriter writer,
    Level logLevel,
    onLog(LogRecord record),
    Stream terminateEventStream}) async {
  var options = new BuildOptions(
      deleteFilesByDefault: deleteFilesByDefault,
      writeToCache: writeToCache,
      packageGraph: packageGraph,
      reader: reader,
      writer: writer,
      logLevel: logLevel,
      onLog: onLog);
  var terminator = new _Terminator(terminateEventStream);
  var buildImpl = new BuildImpl(options, buildActions);

  var result = await buildImpl.runBuild();

  await terminator.cancel();
  await options.logListener.cancel();
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
/// `DirectoryWatcher`s. By default a normal `DirectoryWatcher` will be used.
///
/// The [terminateEventStream] is a stream which can send termination events.
/// By default the [ProcessSignal.SIGINT] stream is used. In this mode, the
/// first event will allow any ongoing builds to finish, and then the program
///  will complete normally. Subsequent events are not handled (and will
///  typically cause a shutdown).
Stream<BuildResult> watch(List<BuildAction> buildActions,
    {bool deleteFilesByDefault,
    bool writeToCache,
    PackageGraph packageGraph,
    RunnerAssetReader reader,
    RunnerAssetWriter writer,
    Level logLevel,
    onLog(LogRecord record),
    Duration debounceDelay,
    DirectoryWatcherFactory directoryWatcherFactory,
    Stream terminateEventStream}) {
  var options = new BuildOptions(
      deleteFilesByDefault: deleteFilesByDefault,
      writeToCache: writeToCache,
      packageGraph: packageGraph,
      reader: reader,
      writer: writer,
      logLevel: logLevel,
      onLog: onLog,
      debounceDelay: debounceDelay,
      directoryWatcherFactory: directoryWatcherFactory);
  var terminator = new _Terminator(terminateEventStream);
  var buildResults =
      runWatch(options, buildActions, terminator.shouldTerminate);

  buildResults.builds.drain().then((_) async {
    await terminator.cancel();
    await options.logListener.cancel();
  });

  return buildResults.builds;
}

/// Same as [watch], except it also provides a server.
///
/// This server will block all requests if a build is current in process.
///
/// By default a static server will be set up to serve [directory] at
/// [address]:[port], but instead a [requestHandler] may be provided for custom
/// behavior.
Stream<BuildResult> serve(List<BuildAction> buildActions,
    {bool deleteFilesByDefault,
    PackageGraph packageGraph,
    RunnerAssetReader reader,
    RunnerAssetWriter writer,
    Level logLevel,
    onLog(LogRecord record),
    Duration debounceDelay,
    DirectoryWatcherFactory directoryWatcherFactory,
    Stream terminateEventStream,
    String directory,
    String address,
    int port,
    Handler requestHandler}) {
  var options = new BuildOptions(
      deleteFilesByDefault: deleteFilesByDefault,
      packageGraph: packageGraph,
      reader: reader,
      writer: writer,
      logLevel: logLevel,
      onLog: onLog,
      debounceDelay: debounceDelay,
      directoryWatcherFactory: directoryWatcherFactory,
      directory: directory,
      address: address,
      port: port);
  var terminator = new _Terminator(terminateEventStream);
  var buildResults =
      runWatch(options, buildActions, terminator.shouldTerminate);

  var serverStarted = startServer(buildResults, options);

  buildResults.builds.drain().then((_) async {
    await terminator.cancel();
    await serverStarted;
    await stopServer();
    await options.logListener.cancel();
  });

  return buildResults.builds;
}

class _Terminator {
  final Future shouldTerminate;
  final StreamSubscription _subscription;

  factory _Terminator(Stream terminateEventStream) {
    var shouldTerminate = new Completer();
    terminateEventStream ??= ProcessSignal.SIGINT.watch();
    int numEventsSeen = 0;
    StreamSubscription terminateListener = terminateEventStream.listen((_) {
      numEventsSeen++;
      if (numEventsSeen == 1) {
        shouldTerminate.complete();
      } else {
        exit(2);
      }
    });
    return new _Terminator._(shouldTerminate.future, terminateListener);
  }

  _Terminator._(this.shouldTerminate, this._subscription);

  Future cancel() => _subscription.cancel();
}
