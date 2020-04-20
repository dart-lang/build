// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:analyzer/src/dart/analysis/byte_store.dart'
    show MemoryByteStore;
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/context/packages.dart' show Packages, Package;
import 'package:analyzer/src/dart/analysis/performance_logger.dart'
    show PerformanceLog;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisOptionsImpl, AnalysisOptions;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summary_sdk.dart' show SummaryBasedDartSdk;
import 'package:build/build.dart';
import 'package:package_config/package_config.dart' show PackageConfig;
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'build_asset_uri_resolver.dart';

/// Builds an [AnalysisDriver] backed by a summary SDK and package summary
/// files.
///
/// Any code which is not covered by the summaries must be resolvable through
/// [buildAssetUriResolver].
Future<AnalysisDriver> analysisDriver(
  BuildAssetUriResolver buildAssetUriResolver,
  AnalysisOptions analysisOptions,
  String sdkSummaryPath,
  PackageConfig packageConfig,
) async {
  var sdk = SummaryBasedDartSdk(sdkSummaryPath, true);
  var sdkResolver = DartUriResolver(sdk);

  var resolvers = [sdkResolver, buildAssetUriResolver];
  var sourceFactory = SourceFactory(resolvers);

  var dataStore = SummaryDataStore([sdkSummaryPath]);

  var logger = PerformanceLog(null);
  var scheduler = AnalysisDriverScheduler(logger);
  var packages = _buildAnalyzerPackages(
      packageConfig, buildAssetUriResolver.resourceProvider);
  var driver = AnalysisDriver(
      scheduler,
      logger,
      buildAssetUriResolver.resourceProvider,
      MemoryByteStore(),
      FileContentOverlay(),
      null,
      sourceFactory,
      analysisOptions as AnalysisOptionsImpl,
      externalSummaries: dataStore,
      packages: packages);

  scheduler.start();
  return driver;
}

Packages _buildAnalyzerPackages(
        PackageConfig packageConfig, ResourceProvider resourceProvider) =>
    Packages({
      for (var package in packageConfig.packages)
        package.name: Package(
          name: package.name,
          languageVersion: package.languageVersion == null
              ? null
              : Version(package.languageVersion.major,
                  package.languageVersion.minor, 0),
          // Analyzer does not see the original file paths at all, we need to
          // make them match the paths that we give it, so we use the `assetPath`
          // function to create those.
          rootFolder: resourceProvider
              .getFolder(p.url.normalize(assetPath(AssetId(package.name, '')))),
          libFolder: resourceProvider.getFolder(
              p.url.normalize(assetPath(AssetId(package.name, 'lib')))),
        ),
    });
