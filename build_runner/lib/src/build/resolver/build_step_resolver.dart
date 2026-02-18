// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:build/build.dart';
import 'package:pool/pool.dart';

import '../build_step_impl.dart';
import 'build_resolver.dart';

/// [Resolver] for a single build step.
class BuildStepResolver implements ReleasableResolver {
  final BuildResolver _buildResolver;
  final BuildStepImpl _buildStep;

  final _entryPoints = <AssetId>{};

  // Ensures we only resolve one entrypoint at a time from the same build step,
  // otherwise there are race conditions with `_entryPoints` being updated
  // before it is actually ready, or resolving entrypoints more than once.
  final Pool _perActionResolvePool = Pool(1);

  BuildStepResolver(this._buildResolver, this._buildStep);

  Stream<LibraryElement> get _librariesFromEntrypoints async* {
    await _updateDriverForEntrypoint(_buildStep.inputId, transitive: true);

    final seen = <LibraryElement>{};
    final toVisit = Queue<LibraryElement>();

    // keep a copy of entry points in case [_resolveIfNecessary] is called
    // before this stream is done.
    final entryPoints = _entryPoints.toList();
    for (final entryPoint in entryPoints) {
      if (!await _buildResolver.isLibrary(entryPoint)) continue;
      final library = await _buildResolver.libraryFor(
        entryPoint,
        allowSyntaxErrors: true,
      );
      toVisit.add(library);
      seen.add(library);
    }
    while (toVisit.isNotEmpty) {
      final current = toVisit.removeFirst();
      // TODO - avoid crawling or returning libraries which are not visible via
      // `BuildStep.canRead`. They'd still be reachable by crawling the element
      // model manually.
      yield current;
      final toCrawl =
          current.firstFragment.libraryImports
              .map((import) => import.importedLibrary)
              .followedBy(
                current.firstFragment.libraryExports.map(
                  (export) => export.exportedLibrary,
                ),
              )
              .nonNulls
              .where((library) => !seen.contains(library))
              .toSet();
      toVisit.addAll(toCrawl);
      seen.addAll(toCrawl);
    }
  }

  @override
  Stream<LibraryElement> get libraries async* {
    yield* _buildResolver.sdkLibraries;
    yield* _librariesFromEntrypoints.where((library) => !library.isInSdk);
  }

  @override
  Future<LibraryElement?> findLibraryByName(String libraryName) =>
      _buildStep.trackStage('findLibraryByName $libraryName', () async {
        await for (final library in libraries) {
          if (library.name == libraryName) return library;
        }
        return null;
      });

  @override
  Future<bool> isLibrary(AssetId assetId) =>
      _buildStep.trackStage('isLibrary $assetId', () async {
        if (!await _buildStep.canRead(assetId)) return false;
        await _updateDriverForEntrypoint(assetId, transitive: false);
        return _buildResolver.isLibrary(assetId);
      });

  @override
  Future<AstNode?> astNodeFor(Fragment fragment, {bool resolve = false}) =>
      _buildStep.trackStage(
        'astNodeFor $fragment',
        () => _buildResolver.astNodeFor(fragment, resolve: resolve),
      );

  @override
  Future<CompilationUnit> compilationUnitFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) => _buildStep.trackStage('compilationUnitFor $assetId', () async {
    if (!await _buildStep.canRead(assetId)) {
      throw AssetNotFoundException(assetId);
    }
    await _updateDriverForEntrypoint(assetId, transitive: false);
    return _buildResolver.compilationUnitFor(
      assetId,
      allowSyntaxErrors: allowSyntaxErrors,
    );
  });

  @override
  Future<LibraryElement> libraryFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) => _buildStep.trackStage('libraryFor $assetId', () async {
    if (!await _buildStep.canRead(assetId)) {
      throw AssetNotFoundException(assetId);
    }
    await _updateDriverForEntrypoint(assetId, transitive: true);
    return _buildResolver.libraryFor(
      assetId,
      allowSyntaxErrors: allowSyntaxErrors,
    );
  });

  /// Updates the analysis driver with updated source of [entrypoint] at
  /// the phase viewed by this build step.
  ///
  /// If [transitive], then all the transitive imports from [entrypoint] are
  /// also updated.
  ///
  /// Records what was read in the build step's `InputTracker`.
  Future<void> _updateDriverForEntrypoint(
    AssetId entrypoint, {
    required bool transitive,
  }) => _perActionResolvePool.withResource(() async {
    if (!_entryPoints.contains(entrypoint)) {
      // We only want transitively resolved ids in `_entrypoints`.
      if (transitive) _entryPoints.add(entrypoint);

      // The resolver will only visit assets that haven't been resolved
      // in this step yet.
      await _buildStep.trackStage(
        'Resolving library $entrypoint',
        () => _buildResolver.updateDriverForEntrypoint(
          phasedReader: _buildStep.phasedReader,
          inputTracker: _buildStep.inputTracker,
          entrypoint: entrypoint,
          transitive: transitive,
        ),
      );
    }
  });

  @override
  void release() {}

  @override
  Future<AssetId> assetIdForElement(Element element) =>
      _buildResolver.assetIdForElement(element);
}
