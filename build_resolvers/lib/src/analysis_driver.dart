// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart'
    show MemoryByteStore;
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart'
    show PerformanceLog;
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as p;

import 'build_asset_uri_resolver.dart';

/// Builds an [AnalysisDriver] backed by a summary SDK and package summary
/// files.
///
/// Any code which is not covered by the summaries must be resolvable through
/// [buildAssetUriResolver].
AnalysisDriver analysisDriver(BuildAssetUriResolver buildAssetUriResolver) {
  AnalysisEngine.instance.processRequiredPlugins();
  var resourceProvider = PhysicalResourceProvider.INSTANCE;
  var sdk = FolderBasedDartSdk(resourceProvider,
      resourceProvider.getFolder(p.dirname(p.dirname(Platform.executable))))
    ..useSummary = true;
  var sdkResolver = DartUriResolver(sdk);

  var resolvers = [sdkResolver, buildAssetUriResolver];
  var sourceFactory = SourceFactory(resolvers);

  var logger = PerformanceLog(null);
  var scheduler = AnalysisDriverScheduler(logger);
  var driver = AnalysisDriver(
    scheduler,
    logger,
    buildAssetUriResolver.resourceProvider,
    MemoryByteStore(),
    FileContentOverlay(),
    null,
    sourceFactory,
    AnalysisOptionsImpl(),
  );

  scheduler.start();
  return driver;
}
