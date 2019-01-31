// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show AnalysisDriver;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as native_path;

import 'analysis_driver.dart';
import 'build_asset_uri_resolver.dart';

// We should always be using url paths here since it's always Dart/pub code.
final path = native_path.url;

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
  final AnalyzerResolver _resolver;
  final BuildAssetUriResolver _uriResolver;

  AnalyzerResolvers._(this._resolver, this._uriResolver);

  /// Create a Resolvers backed by an [AnalysisContext] using options
  /// [analysisOptions].
  ///
  /// If no argument is passed a default AnalysisOptions is used.
  factory AnalyzerResolvers([AnalysisOptions analysisOptions]) {
    var uriResolver = BuildAssetUriResolver();
    var driver = analysisDriver(uriResolver, analysisOptions);
    return AnalyzerResolvers._(
        AnalyzerResolver(driver, uriResolver), uriResolver);
  }

  @override
  Future<ReleasableResolver> get(BuildStep buildStep) async {
    await _uriResolver.performResolve(
        buildStep, [buildStep.inputId], _resolver._driver);
    return PerActionResolver(_resolver, [buildStep.inputId]);
  }

  /// Must be called between each build.
  @override
  void reset() => _uriResolver.seenAssets.clear();
}
