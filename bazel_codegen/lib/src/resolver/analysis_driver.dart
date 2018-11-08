// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show InSummaryUriResolver, SummaryDataStore;
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/src/dart/analysis/byte_store.dart'
    show MemoryByteStore;
import 'package:analyzer/src/dart/analysis/performance_logger.dart'
    show PerformanceLog;
import 'package:analyzer/src/summary/summary_sdk.dart' show SummaryBasedDartSdk;

import '../summaries/arg_parser.dart';
import 'build_asset_uri_resolver.dart';

/// Builds an [AnalysisDriver] backed by a summary SDK and package summary
/// files.
///
/// Any code which is not covered by the summaries must be resolvable through
/// [buildAssetUriResolver].
AnalysisDriver summaryAnalysisDriver(
    SummaryOptions options, BuildAssetUriResolver buildAssetUriResolver) {
  AnalysisEngine.instance.processRequiredPlugins();
  var sdk = SummaryBasedDartSdk(options.sdkSummary, true);
  var sdkResolver = DartUriResolver(sdk);

  var summaryData = SummaryDataStore(options.summaryPaths)
    ..addBundle(null, sdk.bundle);
  var summaryResolver =
      InSummaryUriResolver(PhysicalResourceProvider.INSTANCE, summaryData);

  var resolvers = [buildAssetUriResolver, sdkResolver, summaryResolver];
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
      externalSummaries: summaryData);

  scheduler.start();
  return driver;
}
