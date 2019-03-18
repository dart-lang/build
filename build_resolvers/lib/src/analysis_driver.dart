// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/dart/analysis/byte_store.dart'
    show MemoryByteStore;
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart'
    show PerformanceLog;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisOptionsImpl, AnalysisOptions;
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as p;
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summary_sdk.dart' show SummaryBasedDartSdk;

import 'build_asset_uri_resolver.dart';

/// Builds an [AnalysisDriver] backed by a summary SDK and package summary
/// files.
///
/// Any code which is not covered by the summaries must be resolvable through
/// [buildAssetUriResolver].
AnalysisDriver analysisDriver(BuildAssetUriResolver buildAssetUriResolver,
    AnalysisOptions analysisOptions) {
  var sdkPath = p.dirname(p.dirname(Platform.resolvedExecutable));
  var sdkSummary = p.join(sdkPath, 'lib', '_internal', 'strong.sum');
  var sdk = SummaryBasedDartSdk(sdkSummary, true);
  var sdkResolver = DartUriResolver(sdk);

  var resolvers = [sdkResolver, buildAssetUriResolver];
  var sourceFactory = SourceFactory(resolvers);

  var dataStore =
      SummaryDataStore([p.join(sdkPath, 'lib', '_internal', 'strong.sum')]);

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
    (analysisOptions as AnalysisOptionsImpl) ?? AnalysisOptionsImpl(),
    externalSummaries: dataStore,
  );

  scheduler.start();
  return driver;
}
