// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:code_transformers/resolver.dart' as code_transformers
    show Resolver, Resolvers, dartSdkDirectory;

import '../asset/id.dart';
import '../builder/build_step.dart';
import '../util/barback.dart';

class Resolver {
  final code_transformers.Resolver _resolver;

  Resolver(this._resolver);

  /// Release this resolver so it can be updated by following build steps.
  void release() => _resolver.release();

  /// Gets the resolved Dart library for an asset, or null if the AST has not
  /// been resolved.
  ///
  /// If the AST has not been resolved then this normally means that the
  /// transformer hosting this needs to be in an earlier phase.
  LibraryElement getLibrary(AssetId assetId) =>
      _resolver.getLibrary(toBarbackAssetId(assetId));

  /// Gets all libraries accessible from the entry point, recursively.
  ///
  /// This includes all Dart SDK libraries as well.
  Iterable<LibraryElement> get libraries => _resolver.libraries;

  /// Finds the first library identified by [libraryName], or null if no
  /// library can be found.
  LibraryElement getLibraryByName(String libraryName) =>
      _resolver.getLibraryByName(libraryName);
}

class Resolvers {
  static final code_transformers.Resolvers _resolvers =
      new code_transformers.Resolvers(code_transformers.dartSdkDirectory);

  const Resolvers();

  Future<Resolver> get(BuildStep buildStep, List<AssetId> entryPoints,
          bool resolveAllConstants) async =>
      new Resolver(await _resolvers.get(toBarbackTransform(buildStep),
          entryPoints.map(toBarbackAssetId).toList(), resolveAllConstants));
}
