// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:built_collection/built_collection.dart';
import 'package:logging/logging.dart';
import 'package:watcher/watcher.dart';

import '../asset/writer.dart';
import '../package_graph/package_graph.dart';

/// Settings that are not user-visible: they are overriden only for testing.
class TestingOverrides {
  final BuiltMap<String, BuildConfig>? buildConfig;
  final Duration? debounceDelay;
  final DirectoryWatcher Function(String)? directoryWatcherFactory;
  final void Function(LogRecord)? onLog;
  final PackageGraph? packageGraph;
  final AssetReader? reader;
  final Resolvers? resolvers;
  final Stream<ProcessSignal>? terminateEventStream;
  final RunnerAssetWriter? writer;

  const TestingOverrides({
    this.buildConfig,
    this.debounceDelay,
    this.directoryWatcherFactory,
    this.onLog,
    this.packageGraph,
    this.reader,
    this.resolvers,
    this.terminateEventStream,
    this.writer,
  });
}
