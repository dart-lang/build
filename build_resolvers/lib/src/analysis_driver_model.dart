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

  /// The import graph of all sources needed for analysis.
  final _graph = _Graph();

  /// Assets that have been synced into the in-memory filesystem
  /// [resourceProvider].
  final _syncedOntoResourceProvider = <AssetId>{};

  /// Notifies that [step] has completed.
  ///
  /// All build steps must complete before [reset] is called.
  void notifyComplete(BuildStep step) {
    // This implementation doesn't keep state per `BuildStep`, nothing to do.
  }

  /// Clear cached information specific to an individual build.
  void reset() {
    _graph.clear();
    _syncedOntoResourceProvider.clear();
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
    // Immediately take the lock on `driver` so that the whole class state,
    // `_graph` and `_readForAnalyzir`, is only mutated by one build step at a
    // time. Otherwise, interleaved access complicates processing significantly.
    await withDriverResource((driver) async {
      return _performResolve(driver, buildStep, entryPoints, withDriverResource,
          transitive: transitive);
    });
  }

  Future<void> _performResolve(
      AnalysisDriverForPackageBuild driver,
      BuildStep buildStep,
      List<AssetId> entryPoints,
      Future<void> Function(
              FutureOr<void> Function(AnalysisDriverForPackageBuild))
          withDriverResource,
      {required bool transitive}) async {
    var idsToSyncOntoResourceProvider = entryPoints;
    Iterable<AssetId> inputIds = entryPoints;

    // If requested, find transitive imports.
    if (transitive) {
      await _graph.load(buildStep, entryPoints);
      idsToSyncOntoResourceProvider = _graph.nodes.keys.toList();
      inputIds = _graph.inputsFor(entryPoints);

      // Check for missing inputs that were written during the build.
      for (final id in inputIds
          .where((id) => !id.path.endsWith(_transitiveDigestExtension))) {
        if (_graph.nodes[id]!.isMissing) {
          if (await buildStep.canRead(id)) {
            idsToSyncOntoResourceProvider.add(id);
            _syncedOntoResourceProvider.remove(id);
          }
        }
      }
    }

    // Notify [buildStep] of its inputs.
    for (final id in inputIds) {
      await buildStep.canRead(id);
    }

    // Sync changes onto the "URI resolver", the in-memory filesystem.
    final changedIds = <AssetId>[];
    for (final id in idsToSyncOntoResourceProvider) {
      if (!_syncedOntoResourceProvider.add(id)) continue;
      final content =
          await buildStep.canRead(id) ? await buildStep.readAsString(id) : null;
      final inMemoryFile = resourceProvider.getFile(id.asPath);
      final inMemoryContent =
          inMemoryFile.exists ? inMemoryFile.readAsStringSync() : null;

      if (content != inMemoryContent) {
        if (content == null) {
          // TODO(davidmorgan): per "globallySeenAssets" in
          // BuildAssetUriResolver, deletes should only be applied at the end
          // of the build, in case the file is actually there but not visible
          // to the current reader.
          resourceProvider.deleteFile(id.asPath);
          changedIds.add(id);
        } else {
          if (inMemoryContent == null) {
            resourceProvider.newFile(id.asPath, content);
          } else {
            resourceProvider.modifyFile(id.asPath, content);
          }
          changedIds.add(id);
        }
      }
    }

    // Notify the analyzer of changes and wait for it to update its internal
    // state.
    for (final id in changedIds) {
      driver.changeFile(id.asPath);
    }
    await driver.applyPendingFileChanges();
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

/// The directive graph of all known sources.
///
/// Also tracks whether there is a `.transitive_digest` file next to each source
/// asset, and tracks missing files.
class _Graph {
  final Map<AssetId, _Node> nodes = {};

  /// Walks the import graph from [ids] loading into [nodes].
  Future<void> load(AssetReader reader, Iterable<AssetId> ids) async {
    final nextIds = Queue.of(ids);
    while (nextIds.isNotEmpty) {
      final nextId = nextIds.removeFirst();

      // Skip if already seen.
      if (nodes.containsKey(nextId)) continue;

      final hasTransitiveDigestAsset =
          await reader.canRead(nextId.addExtension(_transitiveDigestExtension));

      // Skip if not readable.
      if (!await reader.canRead(nextId)) {
        nodes[nextId] = _Node.missing(
            id: nextId, hasTransitiveDigestAsset: hasTransitiveDigestAsset);
        continue;
      }

      final content = await reader.readAsString(nextId);
      final deps = _parseDependencies(content, nextId);
      nodes[nextId] = _Node(
          id: nextId,
          deps: deps,
          hasTransitiveDigestAsset: hasTransitiveDigestAsset);
      nextIds.addAll(deps.where((id) => !nodes.containsKey(id)));
    }
  }

  void clear() {
    nodes.clear();
  }

  /// The inputs for a build action analyzing [entryPoints].
  ///
  /// This is transitive deps, but cut off by the presence of any
  /// `.transitive_digest` file next to an asset.
  Set<AssetId> inputsFor(Iterable<AssetId> entryPoints) {
    final result = entryPoints.toSet();
    final nextIds = Queue.of(entryPoints);

    while (nextIds.isNotEmpty) {
      final nextId = nextIds.removeFirst();
      final node = nodes[nextId]!;

      // Add the transitive digest file as an input. If it exists, skip deps.
      result.add(nextId.addExtension(_transitiveDigestExtension));
      if (node.hasTransitiveDigestAsset) {
        continue;
      }

      // Skip if there are no deps because the file is missing.
      if (node.isMissing) continue;

      // For each dep, if it's not in `result` yet, it's newly-discovered:
      // add it to `nextIds`.
      for (final dep in node.deps) {
        if (result.add(dep)) {
          nextIds.add(dep);
        }
      }
    }
    return result;
  }

  @override
  String toString() => nodes.toString();
}

/// A node in the directive graph.
class _Node {
  final AssetId id;
  final List<AssetId> deps;
  final bool isMissing;
  final bool hasTransitiveDigestAsset;

  _Node(
      {required this.id,
      required this.deps,
      required this.hasTransitiveDigestAsset})
      : isMissing = false;

  _Node.missing({required this.id, required this.hasTransitiveDigestAsset})
      : isMissing = true,
        deps = const [];

  @override
  String toString() => '$id:'
      '${hasTransitiveDigestAsset ? 'digest:' : ''}'
      '${isMissing ? 'missing' : deps}';
}

// Transitive digest files are built next to source inputs. As the name
// suggests, they contain the transitive digest of all deps of the file.
// So, establishing a dependency on a transitive digest file is equivalent
// to establishing a dependency on all deps of the file.
const _transitiveDigestExtension = '.transitive_digest';
