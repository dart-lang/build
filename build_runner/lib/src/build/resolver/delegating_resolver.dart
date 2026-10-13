// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:async/async.dart';
import 'package:build/build.dart';

import 'asset_ids.dart';

/// [Resolver] implementation that delegates to a `Future<Resolver>`.
class DelegatingResolver implements Resolver {
  final Future<Resolver> _delegate;

  DelegatingResolver(this._delegate);

  @override
  Future<bool> isLibrary(AssetId assetId) async =>
      (await _delegate).isLibrary(assetId.normalize());

  @override
  Stream<LibraryElement> get libraries {
    final completer = StreamCompleter<LibraryElement>();
    _delegate.then((r) => completer.setSourceStream(r.libraries));
    return completer.stream;
  }

  @override
  Future<AstNode?> astNodeFor(
    Fragment fragment, {
    bool resolve = false,
  }) async => (await _delegate).astNodeFor(fragment, resolve: resolve);

  @override
  Future<CompilationUnit> compilationUnitFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) async => (await _delegate).compilationUnitFor(
    assetId.normalize(),
    allowSyntaxErrors: allowSyntaxErrors,
  );

  @override
  Future<LibraryElement> libraryFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) async => (await _delegate).libraryFor(
    assetId.normalize(),
    allowSyntaxErrors: allowSyntaxErrors,
  );

  @override
  Future<LibraryElement?> findLibraryByName(String libraryName) async =>
      (await _delegate).findLibraryByName(libraryName);

  @override
  Future<AssetId> assetIdForElement(Element element) async =>
      (await _delegate).assetIdForElement(element);
}
