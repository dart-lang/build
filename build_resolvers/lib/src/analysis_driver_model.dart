// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'analysis_driver_model_uri_resolver.dart';

/// Manages analysis driver and related build state.
///
/// - Tracks the import graph of all sources needed for analysis.
/// - Given a set of entrypoints, adds them to known sources, optionally with
///   their transitive imports.
/// - Given a set of entrypoints, informs a `BuildStep` which inputs it now
///   depends on because of analysis.
/// - Maintains an in-memory filesystem that is the analyzer's view of the
///   build.
/// - Notifies the analyzer of changes to that in-memory filesystem.
///
/// TODO(davidmorgan): the implementation here is unfinished and not used
/// anywhere; finish it. See `build_asset_uri_resolver.dart` for the current
/// implementation.
class AnalysisDriverModel {
  /// In-memory filesystem for the analyzer.
  final MemoryResourceProvider resourceProvider =
      MemoryResourceProvider(context: p.posix);

  /// Notifies that [step] has completed.
  ///
  /// All build steps must complete before [reset] is called.
  void notifyComplete(BuildStep step) {
    // TODO(davidmorgan): add test coverage, fix implementation.
  }

  /// Clear cached information specific to an individual build.
  void reset() {
    // TODO(davidmorgan): add test coverage, fix implementation.
  }

  /// Attempts to parse [uri] into an [AssetId] and returns it if it is cached.
  ///
  /// Handles 'package:' or 'asset:' URIs, as well as 'file:' URIs of the form
  /// `/$packageName/$assetPath`.
  ///
  /// Returns null if the `Uri` cannot be parsed or is not cached.
  AssetId? lookupCachedAsset(Uri uri) {
    final assetId = AnalysisDriverModelUriResolver.parseAsset(uri);
    // TODO(davidmorgan): not clear if this is the right "exists" check.
    if (assetId == null || !resourceProvider.getFile(assetId.asPath).exists) {
      return null;
    }

    return assetId;
  }

  /// Updates [resourceProvider] and the analysis driver given by
  /// `withDriverResource`  with updated versions of [entryPoints].
  ///
  /// If [transitive], then all the transitive imports from [entryPoints] are
  /// also updated.
  ///
  /// Notifies [buildStep] of all inputs that result from analysis. If
  /// [transitive], this includes all transitive dependencies.
  ///
  /// If while finding transitive deps a `.transitive_deps` file is
  /// encountered next to a source file then this cuts off the reporting
  /// of deps to the [buildStep], but does not affect the reporting of
  /// files to the analysis driver.
  Future<void> performResolve(
      BuildStep buildStep,
      List<AssetId> entryPoints,
      Future<void> Function(
              FutureOr<void> Function(AnalysisDriverForPackageBuild))
          withDriverResource,
      {required bool transitive}) async {
    /// TODO(davidmorgan): add test coverage for whether transitive
    /// sources are read when [transitive] is false, fix the implementation
    /// here.
    /// TODO(davidmorgan): add test coverage for whether
    /// `.transitive_deps` files cut off the reporting of deps to the
    /// [buildStep], fix the implementation here.

    // Find transitive deps, this also informs [buildStep] of all inputs).
    final ids = await _expandToTransitive(buildStep, entryPoints);

    // Apply changes to in-memory filesystem.
    for (final id in ids) {
      if (await buildStep.canRead(id)) {
        final content = await buildStep.readAsString(id);

        /// TODO(davidmorgan): add test coverage for when a file is
        /// modified rather than added, fix the implementation here.
        resourceProvider.newFile(id.asPath, content);
      } else {
        if (resourceProvider.getFile(id.asPath).exists) {
          resourceProvider.deleteFile(id.asPath);
        }
      }
    }

    // Notify the analyzer of changes.
    await withDriverResource((driver) async {
      for (final id in ids) {
        // TODO(davidmorgan): add test coverage for over-notification of
        // changes, fix the implementaion here.
        driver.changeFile(id.asPath);
      }
      await driver.applyPendingFileChanges();
    });
  }

  /// Walks the import graph from [ids], returns full transitive deps.
  Future<Set<AssetId>> _expandToTransitive(
      AssetReader reader, Iterable<AssetId> ids) async {
    final result = <AssetId>{};
    final nextIds = Queue.of(ids);
    while (nextIds.isNotEmpty) {
      final nextId = nextIds.removeFirst();

      // Skip if already seen.
      if (!result.add(nextId)) continue;

      // Skip if not readable.
      if (!await reader.canRead(nextId)) continue;

      final content = await reader.readAsString(nextId);
      final deps = _parseDependencies(content, nextId);
      nextIds.addAll(deps.where((id) => !result.contains(id)));
    }
    return result;
  }
}

const _ignoredSchemes = ['dart', 'dart-ext'];

/// Parses Dart source in [content], returns all depedencies: all assets
/// mentioned in directives, excluding `dart:` and `dart-ext` schemes.
List<AssetId> _parseDependencies(String content, AssetId from) =>
    parseString(content: content, throwIfDiagnostics: false)
        .unit
        .directives
        .whereType<UriBasedDirective>()
        .map((directive) => directive.uri.stringValue)
        // Uri.stringValue can be null for strings that use interpolation.
        .nonNulls
        .where(
          (uriContent) => !_ignoredSchemes.any(Uri.parse(uriContent).isScheme),
        )
        .map((content) => AssetId.resolve(Uri.parse(content), from: from))
        .toList();

extension _AssetIdExtensions on AssetId {
  /// Asset path for the in-memory filesystem.
  String get asPath => AnalysisDriverModelUriResolver.assetPath(this);
}
