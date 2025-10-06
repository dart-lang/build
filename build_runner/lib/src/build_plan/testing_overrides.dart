// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:built_collection/built_collection.dart';
import 'package:logging/logging.dart';
import 'package:watcher/watcher.dart';

import '../io/reader_writer.dart';
import 'build_phases.dart';
import 'builder_application.dart';
import 'package_graph.dart';

/// Settings that are not user-visible: they are overriden only for testing.
class TestingOverrides {
  final BuiltList<BuilderApplication>? builderApplications;
  final BuiltMap<String, BuildConfig>? buildConfig;
  final BuildPhases? buildPhases;
  final Duration? debounceDelay;
  final BuiltList<String>? defaultRootPackageSources;
  final DirectoryWatcher Function(String)? directoryWatcherFactory;
  final void Function(LogRecord)? onLog;
  final PackageGraph? packageGraph;
  final ReaderWriter? readerWriter;
  final void Function(AssetId, Iterable<AssetId>)? reportUnusedAssetsForInput;
  final Resolvers? resolvers;
  final Stream<ProcessSignal>? terminateEventStream;
  final bool flattenOutput;

  const TestingOverrides({
    this.builderApplications,
    this.buildConfig,
    this.buildPhases,
    this.debounceDelay,
    this.defaultRootPackageSources,
    this.directoryWatcherFactory,
    this.onLog,
    this.packageGraph,
    this.readerWriter,
    this.reportUnusedAssetsForInput,
    this.resolvers,
    this.terminateEventStream,
    this.flattenOutput = false,
  });

  TestingOverrides copyWith({
    BuiltList<BuilderApplication>? builderApplications,
    BuiltMap<String, BuildConfig>? buildConfig,
    PackageGraph? packageGraph,
  }) => TestingOverrides(
    builderApplications: builderApplications ?? this.builderApplications,
    buildConfig: buildConfig ?? this.buildConfig,
    buildPhases: buildPhases,
    debounceDelay: debounceDelay,
    defaultRootPackageSources: defaultRootPackageSources,
    directoryWatcherFactory: directoryWatcherFactory,
    onLog: onLog,
    packageGraph: packageGraph ?? this.packageGraph,
    readerWriter: readerWriter,
    reportUnusedAssetsForInput: reportUnusedAssetsForInput,
    resolvers: resolvers,
    terminateEventStream: terminateEventStream,
    flattenOutput: flattenOutput,
  );
}
