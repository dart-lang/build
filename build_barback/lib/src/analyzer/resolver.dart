// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

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
  bool isLibrary(AssetId assetId) =>
      _resolver.isLibrary(toBarbackAssetId(assetId));

  @override
  LibraryElement getLibrary(AssetId assetId) {
    var library = _resolver.getLibrary(toBarbackAssetId(assetId));
    if (library == null) throw new NonLibraryAssetException(assetId);
    return library;
  }

  @override
  Iterable<LibraryElement> get libraries => _resolver.libraries;

  @override
  LibraryElement getLibraryByName(String libraryName) =>
      _resolver.getLibraryByName(libraryName);
}

class BarbackResolvers implements Resolvers {
  static final code_transformers.Resolvers _resolvers =
      new code_transformers.Resolvers(code_transformers.dartSdkDirectory);

  const BarbackResolvers();

  Future<ReleasableResolver> get(BuildStep buildStep) async =>
      new BarbackResolver(await _resolvers.get(toBarbackTransform(buildStep),
          [toBarbackAssetId(buildStep.inputId)], false));
}
