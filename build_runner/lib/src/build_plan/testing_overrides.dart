// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:built_collection/built_collection.dart';
import 'package:logging/logging.dart';
import 'package:watcher/watcher.dart';

import '../build/build_result.dart';
import '../build/finalized_assets_view.dart';
import '../io/reader_writer.dart';
import 'build_directory.dart';
import 'package_graph.dart';

/// Settings that are not user-visible: they are overriden only for testing.
class TestingOverrides {
  final BuiltMap<String, BuildConfig>? buildConfig;
  final Duration? debounceDelay;
  final BuiltList<String>? defaultRootPackageSources;
  final DirectoryWatcher Function(String)? directoryWatcherFactory;
  final Future<BuildResult> Function(
    BuildResult,
    FinalizedAssetsView,
    ReaderWriter readerWriter,
    BuiltSet<BuildDirectory>,
  )?
  finalizeBuild;
  final void Function(LogRecord)? onLog;
  final PackageGraph? packageGraph;
  final ReaderWriter? readerWriter;
  final void Function(AssetId, Iterable<AssetId>)? reportUnusedAssetsForInput;
  final Resolvers? resolvers;
  final Stream<ProcessSignal>? terminateEventStream;

  const TestingOverrides({
    this.buildConfig,
    this.debounceDelay,
    this.defaultRootPackageSources,
    this.directoryWatcherFactory,
    this.finalizeBuild,
    this.onLog,
    this.packageGraph,
    this.readerWriter,
    this.reportUnusedAssetsForInput,
    this.resolvers,
    this.terminateEventStream,
  });
}
