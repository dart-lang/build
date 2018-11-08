// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show AnalysisDriver;
import 'package:analyzer/src/generated/source.dart' show SourceKind;
import 'package:build/build.dart';

import '../assets/path_translation.dart';
import '../summaries/arg_parser.dart';
import 'analysis_driver.dart';
import 'build_asset_uri_resolver.dart';

/// A [Resolvers] which builds a single [AnalysisDriver] backed by summaries
/// and shares it across [AnalysisResolver] instances.
///
/// For each call to [get] the [AssetId]s will be read and made available to the
/// analysisDriver.
class AnalysisDriverResolvers implements Resolvers {
  final BuildAssetUriResolver _assetResolver;
  final AnalysisDriver _driver;
  final String _sourcesFile;
  final String _packagePath;
  final Map<String, String> _packageMap;
  Future<Null> _priming;

  factory AnalysisDriverResolvers(
      SummaryOptions options, Map<String, String> packageMap) {
    var assetResolver = BuildAssetUriResolver();
    return AnalysisDriverResolvers._(
        assetResolver,
        summaryAnalysisDriver(options, assetResolver),
        options.sourcesFile,
        options.packagePath,
        packageMap);
  }

  AnalysisDriverResolvers._(this._assetResolver, this._driver,
      this._sourcesFile, this._packagePath, this._packageMap);

  @override
  Future<ReleasableResolver> get(BuildStep buildStep) async {
    await (_priming ??= _primeWithSources(buildStep.readAsString));
    var entryPoints = [buildStep.inputId];
    await _assetResolver.addAssets(entryPoints, buildStep.readAsString);
    return AnalysisResolver(_driver, entryPoints);
  }

  Future<Null> _primeWithSources(ReadAsset readAsset) async {
    var sourceFiles = await File(_sourcesFile).readAsLines();
    var assets = findAssetIds(sourceFiles, _packagePath, _packageMap);
    await _assetResolver.addAssets(assets, readAsset);
  }

  @override
  void reset() => _driver.dispose();
}

/// a [Resolver] backed by an [AnalysisDriver].
class AnalysisResolver implements ReleasableResolver {
  final AnalysisDriver _analysisDriver;
  final List<AssetId> _assetIds;

  AnalysisResolver(this._analysisDriver, this._assetIds);

  @override
  void release() {}

  @override
  Future<bool> isLibrary(AssetId assetId) async {
    var uri = assetUri(assetId);
    var source = _analysisDriver.sourceFactory.forUri2(uri);
    return source != null &&
        (await _analysisDriver.getSourceKind(assetPath(assetId))) ==
            SourceKind.LIBRARY;
  }

  @override
  Future<LibraryElement> libraryFor(AssetId assetId) async {
    var path = assetPath(assetId);
    var uri = assetUri(assetId);
    var source = _analysisDriver.sourceFactory.forUri2(uri);
    if (source == null) throw ArgumentError('missing source for $uri');
    var kind = await _analysisDriver.getSourceKind(path);
    if (kind != SourceKind.LIBRARY) return null;
    return _analysisDriver.getLibraryByUri(assetId.uri.toString());
  }

  @override
  Stream<LibraryElement> get libraries async* {
    var allLibraries = Set<LibraryElement>();
    var uncheckedLibraries = Queue<LibraryElement>()
      ..addAll(await Future.wait(_assetIds.map(libraryFor)));
    while (uncheckedLibraries.isNotEmpty) {
      var library = uncheckedLibraries.removeFirst();
      allLibraries.add(library);
      yield library;
      uncheckedLibraries.addAll(library.importedLibraries
          .where((library) => !allLibraries.contains(library)));
    }
  }

  @override
  Future<LibraryElement> findLibraryByName(String name) => libraries
      .firstWhere((library) => library.name == name, orElse: () => null);
}
