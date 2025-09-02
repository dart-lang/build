// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: implementation_imports
import 'package:build_runner_core/src/generate/run_builder.dart'
    as build_runner_core;
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';

import '../analyzer/resolver.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../builder/build_step.dart';
import '../builder/builder.dart';
import '../resource/resource.dart';

@Deprecated('''
This method has moved to `package:build_runner_core` and will be
deleted from `package:build`.

The currently supported ways to run builders are using `build_runner`
on the command line or `build_test` in tests. If you need ongoing
support for a different way to run builders please get in touch at
https://github.com/dart-lang/build/discussions.
''')
Future<void> runBuilder(
  Builder builder,
  Iterable<AssetId> inputs,
  AssetReader assetReader,
  AssetWriter assetWriter,
  Resolvers? resolvers, {
  Logger? logger,
  ResourceManager? resourceManager,
  StageTracker? stageTracker,
  void Function(AssetId input, Iterable<AssetId> assets)?
  reportUnusedAssetsForInput,
  PackageConfig? packageConfig,
}) => build_runner_core.runBuilder(
  builder,
  inputs,
  assetReader,
  assetWriter,
  resolvers,
  logger: logger,
  resourceManager: resourceManager,
  stageTracker: stageTracker,
  reportUnusedAssetsForInput: reportUnusedAssetsForInput,
  packageConfig: packageConfig,
);
