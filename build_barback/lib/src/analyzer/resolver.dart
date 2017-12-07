// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analyzer/src/generated/engine.dart';
import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:code_transformers/resolver.dart' as code_transformers
    show Resolver, Resolvers, dartSdkDirectory;

import '../util/barback.dart';

class BarbackResolver implements ReleasableResolver {
  final code_transformers.Resolver _resolver;

  BarbackResolver(this._resolver);

  @override
  void release() => _resolver.release();

  @override
  Future<bool> isLibrary(AssetId assetId) async =>
      _resolver.isLibrary(toBarbackAssetId(assetId));

  @override
  Future<LibraryElement> libraryFor(AssetId assetId) async {
    var library = _resolver.getLibrary(toBarbackAssetId(assetId));
    if (library == null) throw new NonLibraryAssetException(assetId);
    return library;
  }

  @override
  Stream<LibraryElement> get libraries =>
      new Stream.fromIterable(_resolver.libraries);

  @override
  Future<LibraryElement> findLibraryByName(String libraryName) async =>
      _resolver.getLibraryByName(libraryName);
}

final code_transformers.Resolvers codeTransformerResolvers =
    new code_transformers.Resolvers(code_transformers.dartSdkDirectory,
        // Same as bazel_codegen/src/summaries/analysis_context.dart
        options: new AnalysisOptionsImpl()..strongMode = true);

class BarbackResolvers implements Resolvers {
  const BarbackResolvers();

  @override
  Future<ReleasableResolver> get(BuildStep buildStep) async =>
      new BarbackResolver(await codeTransformerResolvers.get(
          toBarbackTransform(buildStep),
          [toBarbackAssetId(buildStep.inputId)],
          false));
}
