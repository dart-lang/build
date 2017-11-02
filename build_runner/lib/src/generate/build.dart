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
import 'build_impl.dart' as build_impl;
import 'build_result.dart';
import 'directory_watcher_factory.dart';
import 'phase.dart';
import 'watch_impl.dart' as watch_impl;

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
        Stream terminateEventStream}) =>
    build_impl.build(buildActions,
        deleteFilesByDefault: deleteFilesByDefault,
        writeToCache: writeToCache,
        packageGraph: packageGraph,
        reader: reader,
        writer: writer,
        logLevel: logLevel,
        onLog: onLog,
        terminateEventStream: terminateEventStream);

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
/// By default the [ProcessSignal.SIGINT] stream is used. In this mode, the
/// first event will allow any ongoing builds to finish, and then the program
///  will complete normally. Subsequent events are not handled (and will
///  typically cause a shutdown).
Future<ServeHandler> watch(List<BuildAction> buildActions,
        {bool deleteFilesByDefault,
        bool writeToCache,
        PackageGraph packageGraph,
        RunnerAssetReader reader,
        RunnerAssetWriter writer,
        Level logLevel,
        onLog(LogRecord record),
        Duration debounceDelay,
        DirectoryWatcherFactory directoryWatcherFactory,
        Stream terminateEventStream}) =>
    watch_impl.watch(buildActions,
        deleteFilesByDefault: deleteFilesByDefault,
        writeToCache: writeToCache,
        packageGraph: packageGraph,
        reader: reader,
        writer: writer,
        logLevel: logLevel,
        onLog: onLog,
        debounceDelay: debounceDelay,
        directoryWatcherFactory: directoryWatcherFactory,
        terminateEventStream: terminateEventStream);
