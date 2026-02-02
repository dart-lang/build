// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart' hide BuilderDefinition;
import 'package:built_collection/built_collection.dart';
import 'package:logging/logging.dart';
import 'package:watcher/watcher.dart';

import '../io/reader_writer.dart';
import 'build_packages.dart';
import 'build_phases.dart';
import 'builder_definition.dart';

/// Settings that are not user-visible: they are overriden only for testing.
class TestingOverrides {
  final BuiltList<AbstractBuilderDefinition>? builderDefinitions;
  final BuiltMap<String, BuildConfig>? buildConfig;
  final BuildPackages? buildPackages;
  final BuildPhases? buildPhases;
  final Duration? debounceDelay;
  final BuiltList<String>? defaultRootPackageSources;
  final DirectoryWatcher Function(String)? directoryWatcherFactory;
  final void Function(LogRecord)? onLog;
  final ReaderWriter? readerWriter;
  final void Function(AssetId, Iterable<AssetId>)? reportUnusedAssetsForInput;
  final Resolvers? resolvers;
  final Stream<ProcessSignal>? terminateEventStream;
  final bool flattenOutput;

  const TestingOverrides({
    this.builderDefinitions,
    this.buildConfig,
    this.buildPackages,
    this.buildPhases,
    this.debounceDelay,
    this.defaultRootPackageSources,
    this.directoryWatcherFactory,
    this.flattenOutput = false,
    this.onLog,
    this.readerWriter,
    this.reportUnusedAssetsForInput,
    this.resolvers,
    this.terminateEventStream,
  });

  TestingOverrides copyWith({
    BuiltList<BuilderDefinition>? builderDefinitions,
    BuiltMap<String, BuildConfig>? buildConfig,
    BuildPackages? buildPackages,
  }) => TestingOverrides(
    builderDefinitions: builderDefinitions ?? this.builderDefinitions,
    buildConfig: buildConfig ?? this.buildConfig,
    buildPackages: buildPackages ?? this.buildPackages,
    buildPhases: buildPhases,
    debounceDelay: debounceDelay,
    defaultRootPackageSources: defaultRootPackageSources,
    directoryWatcherFactory: directoryWatcherFactory,
    onLog: onLog,
    readerWriter: readerWriter,
    reportUnusedAssetsForInput: reportUnusedAssetsForInput,
    resolvers: resolvers,
    terminateEventStream: terminateEventStream,
    flattenOutput: flattenOutput,
  );
}
