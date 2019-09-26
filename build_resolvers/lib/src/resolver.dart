// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show AnalysisDriver;
import 'package:analyzer/src/generated/engine.dart' hide Logger;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/summary_file_builder.dart';
import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package:path/path.dart' as p;

import 'analysis_driver.dart';
import 'build_asset_uri_resolver.dart';
import 'human_readable_duration.dart';

final _logger = Logger('build_resolvers');

/// Implements [Resolver.libraries] and [Resolver.findLibraryByName] by crawling
/// down from entrypoints.
class PerActionResolver implements ReleasableResolver {
  final ReleasableResolver _delegate;
  final Iterable<AssetId> _entryPoints;

  PerActionResolver(this._delegate, this._entryPoints);

  @override
  Stream<LibraryElement> get libraries async* {
    final seen = Set<LibraryElement>();
    final toVisit = Queue<LibraryElement>();
    for (final entryPoint in _entryPoints) {
      if (!await _delegate.isLibrary(entryPoint)) continue;
      final library = await _delegate.libraryFor(entryPoint);
      toVisit.add(library);
      seen.add(library);
    }
    while (toVisit.isNotEmpty) {
      final current = toVisit.removeFirst();
      // TODO - avoid crawling or returning libraries which are not visible via
      // `BuildStep.canRead`. They'd still be reachable by crawling the element
      // model manually.
      yield current;
      final toCrawl = current.importedLibraries
          .followedBy(current.exportedLibraries)
          .where((l) => !seen.contains(l))
          .toSet();
      toVisit.addAll(toCrawl);
      seen.addAll(toCrawl);
    }
  }

  @override
  Future<LibraryElement> findLibraryByName(String libraryName) async =>
      libraries.firstWhere((l) => l.name == libraryName, orElse: () => null);

  @override
  Future<bool> isLibrary(AssetId assetId) => _delegate.isLibrary(assetId);

  @override
  Future<LibraryElement> libraryFor(AssetId assetId) =>
      _delegate.libraryFor(assetId);

  @override
  void release() => _delegate.release();

  @override
  Future<AssetId> assetIdForElement(Element element) =>
      _delegate.assetIdForElement(element);
}

class AnalyzerResolver implements ReleasableResolver {
  final BuildAssetUriResolver _uriResolver;
  final AnalysisDriver _driver;

  AnalyzerResolver(this._driver, this._uriResolver);

  @override
  Future<bool> isLibrary(AssetId assetId) async {
    var source = _driver.sourceFactory.forUri2(assetId.uri);
    return source != null &&
        (await _driver.getSourceKind(assetPath(assetId))) == SourceKind.LIBRARY;
  }

  @override
  Future<LibraryElement> libraryFor(AssetId assetId) async {
    var path = assetPath(assetId);
    var uri = assetId.uri;
    var source = _driver.sourceFactory.forUri2(uri);
    if (source == null) throw ArgumentError('missing source for $uri');
    var kind = await _driver.getSourceKind(path);
    if (kind != SourceKind.LIBRARY) return null;
    return _driver.getLibraryByUri(assetId.uri.toString());
  }

  @override
  // Do nothing
  void release() {}

  @override
  Stream<LibraryElement> get libraries {
    // We don't know what libraries to expose without leaking libraries written
    // by later phases.
    throw UnimplementedError();
  }

  @override
  Future<LibraryElement> findLibraryByName(String libraryName) {
    // We don't know what libraries to expose without leaking libraries written
    // by later phases.
    throw UnimplementedError();
  }

  @override
  Future<AssetId> assetIdForElement(Element element) async {
    final uri = element.source.uri;
    if (!uri.isScheme('package') && !uri.isScheme('asset')) {
      throw UnresolvableAssetException(
          '${element.name} in ${element.source.uri}');
    }
    return AssetId.resolve('${element.source.uri}');
  }
}

class AnalyzerResolvers implements Resolvers {
  /// Nullable, the default analysis options are used if not provided.
  final AnalysisOptions _analysisOptions;

  /// A function that returns the path to the SDK summary when invoked.
  ///
  /// Defaults to [_defaultSdkSummaryGenerator].
  final Future<String> Function() _sdkSummaryGenerator;

  // Lazy, all access must be preceded by a call to `_ensureInitialized`.
  AnalyzerResolver _resolver;
  BuildAssetUriResolver _uriResolver;

  /// Nullable, should not be accessed outside of [_ensureInitialized].
  Future<void> _initialized;

  AnalyzerResolvers(
      [this._analysisOptions, Future<String> Function() sdkSummaryGenerator])
      : _sdkSummaryGenerator =
            sdkSummaryGenerator ?? _defaultSdkSummaryGenerator;

  /// Create a Resolvers backed by an [AnalysisContext] using options
  /// [_analysisOptions].
  Future<void> _ensureInitialized() {
    return _initialized ??= () async {
      _uriResolver = BuildAssetUriResolver();
      var driver = analysisDriver(
          _uriResolver, _analysisOptions, await _sdkSummaryGenerator());
      _resolver = AnalyzerResolver(driver, _uriResolver);
    }();
  }

  @override
  Future<ReleasableResolver> get(BuildStep buildStep) async {
    await _ensureInitialized();

    await _uriResolver.performResolve(
        buildStep, [buildStep.inputId], _resolver._driver);
    return PerActionResolver(_resolver, [buildStep.inputId]);
  }

  /// Must be called between each build.
  @override
  void reset() {
    _uriResolver?.seenAssets?.clear();
  }
}

/// Lazily creates a summary of the users SDK and caches it under
/// `.dart_tool/build_resolvers`.
///
/// This is only intended for use in typical dart packages, which must
/// have an already existing `.dart_tool` directory (this is how we
/// validate we are running under a typical dart package and not a custom
/// environment).
Future<String> _defaultSdkSummaryGenerator() async {
  var dartToolPath = '.dart_tool';
  if (!await Directory(dartToolPath).exists()) {
    throw StateError(
        'The default analyzer resolver can only be used when the current '
        'working directory is a standard pub package.');
  }

  var cacheDir = p.join(dartToolPath, 'build_resolvers');
  var summaryPath = p.join(cacheDir, 'sdk.sum');
  var analyzerPathFile = File('$summaryPath.analyzer.path');
  var sdkVersionFile = File('$summaryPath.sdk.version');
  var summaryFile = File(summaryPath);

  // Invalidate existing summary/version/analyzer files if present.
  if (await sdkVersionFile.exists() && await analyzerPathFile.exists()) {
    if (!await _checkSdkVersion(sdkVersionFile) ||
        !await _checkAnalyzerPath(analyzerPathFile)) {
      await sdkVersionFile.delete();
      await analyzerPathFile.delete();
      if (await summaryFile.exists()) await summaryFile.delete();
    }
  } else if (await summaryFile.exists()) {
    // Fallback for cases where we could not do a proper version check.
    await summaryFile.delete();
  }

  // Generate the summary and version files if necessary.
  if (!await summaryFile.exists()) {
    var watch = Stopwatch()..start();
    _logger.info('Generating SDK summary...');
    await summaryFile.create(recursive: true);
    var sdkPath = p.dirname(p.dirname(Platform.resolvedExecutable));
    await summaryFile.writeAsBytes(SummaryBuilder.forSdk(sdkPath).build());

    await _createSdkVersionFile(sdkVersionFile);
    await _createAnalyzerPathFile(analyzerPathFile);
    watch.stop();
    _logger.info('Generating SDK summary completed, took '
        '${humanReadable(watch.elapsed)}\n');
  }

  return p.absolute(summaryPath);
}

Future<String> get _analyzerPath =>
    PackageResolver.current.packagePath('analyzer');

Future<bool> _checkAnalyzerPath(File analyzerPathFile) async {
  var lastPath = await analyzerPathFile.readAsString();
  return lastPath == await _analyzerPath;
}

Future<void> _createAnalyzerPathFile(File analyzerPathFile) async {
  await analyzerPathFile.create(recursive: true);
  await analyzerPathFile.writeAsString(await _analyzerPath);
}

Future<bool> _checkSdkVersion(File sdkVersionFile) async {
  var lastVersion = await sdkVersionFile.readAsString();
  return lastVersion == Platform.version;
}

Future<void> _createSdkVersionFile(File sdkVersionFile) async {
  await sdkVersionFile.create(recursive: true);
  await sdkVersionFile.writeAsString(Platform.version);
}
