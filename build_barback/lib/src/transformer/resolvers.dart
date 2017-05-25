// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:build/build.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:cli_util/cli_util.dart' as cli_util;

import 'crawl_imports.dart';

typedef FutureOr<String> Read(AssetId assetId);

class SinglePassResolvers implements Resolvers {
  final Iterable<AssetId> _entryPoints;
  final Read _read;

  SinglePassResolvers(this._entryPoints, this._read);

  Future<ReleasableResolver> _resolver;
  @override
  Future<ReleasableResolver> get([_]) =>
      _resolver ??= _createResolver(_entryPoints, _read);
}

Future<ReleasableResolver> _createResolver(Iterable<AssetId> entryPoints,
        FutureOr<String> read(AssetId assetId)) async =>
    new AnalysisResolver(
        await _createAnalysisContext(entryPoints, read), entryPoints);

Future<AnalysisContext> _createAnalysisContext(Iterable<AssetId> entryPoints,
    FutureOr<String> read(AssetId assetId)) async {
  var assetResolver =
      new _BuildAssetUriResolver(await crawlImports(entryPoints, read));

  var options = new AnalysisOptionsImpl()
    ..preserveComments = false
    ..analyzeFunctionBodies = true;
  var sdk = new FolderBasedDartSdk(PhysicalResourceProvider.INSTANCE,
      PhysicalResourceProvider.INSTANCE.getFolder(cli_util.getSdkDir().path));
  var dartUriResolver = new DartUriResolver(sdk);
  var context = AnalysisEngine.instance.createAnalysisContext()
    ..analysisOptions = options
    ..sourceFactory = new SourceFactory([dartUriResolver, assetResolver]);
  return context;
}

/// A [UriResolver] which can read build assets by reading them as strings.
///
/// Will only read each asset once. This resolver does not handle cases where
/// assets may change during a build process.
class _BuildAssetUriResolver implements UriResolver {
  final Map<Uri, Source> _knownAssets;

  _BuildAssetUriResolver(this._knownAssets);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) => _knownAssets[uri];

  @override
  Uri restoreAbsolute(Source source) {
    throw new UnimplementedError();
  }
}

/// a [Resolver] backed by an [AnalysisContext].
class AnalysisResolver implements ReleasableResolver {
  final AnalysisContext _analysisContext;
  final List<AssetId> _assetIds;

  AnalysisResolver(this._analysisContext, this._assetIds);

  @override
  void release() => _analysisContext.dispose();

  @override
  bool isLibrary(AssetId assetId) {
    var uri = assetId.uri;
    var source = _analysisContext.sourceFactory.forUri2(uri);
    return source != null &&
        _analysisContext.computeKindOf(source) == SourceKind.LIBRARY;
  }

  @override
  LibraryElement getLibrary(AssetId assetId) {
    var uri = assetId.uri;
    var source = _analysisContext.sourceFactory.forUri2(uri);
    if (source == null) throw 'missing source for $uri';
    var kind = _analysisContext.computeKindOf(source);
    if (kind != SourceKind.LIBRARY) return null;
    var library = _analysisContext.computeLibraryElement(source);
    if (library == null) throw 'Could not resolve $assetId';
    return library;
  }

  @override
  List<LibraryElement> get libraries {
    var allLibraries = new Set<LibraryElement>();
    var uncheckedLibraries = new Queue<LibraryElement>();
    uncheckedLibraries.addAll(_assetIds.map(getLibrary));
    while (uncheckedLibraries.isNotEmpty) {
      var library = uncheckedLibraries.removeFirst();
      allLibraries.add(library);
      uncheckedLibraries.addAll(library.importedLibraries
          .where((library) => !allLibraries.contains(library)));
    }
    return allLibraries.toList();
  }

  @override
  LibraryElement getLibraryByName(String name) =>
      libraries.firstWhere((library) => library.name == name, orElse: null);
}
