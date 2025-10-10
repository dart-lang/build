// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:io';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/analysis_options_map.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/summary2/package_bundle_format.dart';
import 'package:path/path.dart' as p;

export 'package:analyzer/dart/analysis/analysis_options.dart'
    show AnalysisOptions;
export 'package:analyzer/source/source.dart' show Source;
export 'package:analyzer/src/context/packages.dart' show Package, Packages;
export 'package:analyzer/src/dart/analysis/analysis_options.dart'
    show AnalysisOptionsImpl;
export 'package:analyzer/src/dart/analysis/byte_store.dart' show ByteStore;
export 'package:analyzer/src/dart/analysis/experiments.dart'
    show ExperimentStatus;
export 'package:analyzer/src/generated/source.dart' show UriResolver;

/// A somewhat low level API to create [AnalysisSession].
///
/// Ideally we want clients to use [AnalysisContextCollection], which
/// encapsulates any internals and is driven by `package_config.json` and
/// `analysis_options.yaml` files. But so far it looks that `build_resolvers`
/// wants to provide [UriResolver], and push [Packages] created by other means
/// than parsing `package_config.json`.
AnalysisDriverForPackageBuild createAnalysisDriver({
  required ResourceProvider resourceProvider,
  required Uint8List sdkSummaryBytes,
  required AnalysisOptions analysisOptions,
  FileContentCache? fileContentCache,
  required List<UriResolver> uriResolvers,
  required Packages packages,
  ByteStore? byteStore,
}) {
  final sdkBundle = PackageBundleReader(sdkSummaryBytes);
  final bundleSdk = SummaryBasedDartSdk.forBundle(sdkBundle);

  final runningDarkSdkPath = p.dirname(p.dirname(Platform.resolvedExecutable));
  final sdk = FolderBasedDartSdk(
    resourceProvider,
    resourceProvider.getFolder(runningDarkSdkPath),
  );

  //final sourceFactory = SourceFactory([DartUriResolver(sdk), ...uriResolvers]);
  final sourceFactory = SourceFactory([DartUriResolver(sdk), ...uriResolvers]);

  //final dataStore = SummaryDataStore();
  //dataStore.addBundle('', sdkBundle);

  final logger = PerformanceLog(null);
  byteStore ??= MemoryByteStore();

  final scheduler = AnalysisDriverScheduler(logger);
  scheduler.events.drain<void>().ignore();

  final sharedOptions = analysisOptions as AnalysisOptionsImpl;
  final optionsMap = AnalysisOptionsMap.forSharedOptions(sharedOptions);
  final driver = AnalysisDriver(
    scheduler: scheduler,
    logger: logger,
    resourceProvider: resourceProvider,
    byteStore: byteStore,
    sourceFactory: sourceFactory,
    analysisOptionsMap: optionsMap,
    fileContentCache: fileContentCache,
    // externalSummaries: dataStore,
    packages: packages,
    withFineDependencies: true,
    shouldReportInconsistentAnalysisException: false,
  );

  scheduler.start();

  return AnalysisDriverForPackageBuild._(bundleSdk.libraryUris, driver);
}

/// [AnalysisSession] plus a tiny bit more.
class AnalysisDriverForPackageBuild {
  final List<Uri> _sdkLibraryUris;
  final AnalysisDriver _driver;

  AnalysisDriverForPackageBuild._(this._sdkLibraryUris, this._driver);

  AnalysisSession get currentSession {
    return _driver.currentSession;
  }

  /// Returns URIs of libraries in the given SDK.
  List<Uri> get sdkLibraryUris {
    return _sdkLibraryUris;
  }

  /// Return a [Future] that completes after pending file changes are applied,
  /// so that [currentSession] can be used to compute results.
  Future<void> applyPendingFileChanges() {
    return _driver.applyPendingFileChanges();
  }

  /// The file with the given [path] might have changed - updated, added or
  /// removed. Or not, we don't know. Or it might have, but then changed back.
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [currentSession] most probably will be invalidated.
  /// Note, is does NOT at the time of writing this comment.
  /// But we are going to fix this.
  void changeFile(String path) {
    _driver.changeFile(path);
  }

  /// Return `true` if the [uri] can be resolved to an existing file.
  bool isUriOfExistingFile(Uri uri) {
    final source = _driver.sourceFactory.forUri2(uri);
    return source != null && source.exists();
  }
}
