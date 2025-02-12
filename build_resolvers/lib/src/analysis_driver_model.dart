// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';

import 'analysis_driver_filesystem.dart';

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
  final AnalysisDriverFilesystem filesystem = AnalysisDriverFilesystem();

  /// The import graph of all sources needed for analysis.
  final _graph = _Graph();

  /// Assets that have been synced into the in-memory filesystem
  /// [filesystem].
  final _syncedOntoFilesystem = <AssetId>{};

  /// Notifies that [step] has completed.
  ///
  /// All build steps must complete before [reset] is called.
  void notifyComplete(BuildStep step) {
    // This implementation doesn't keep state per `BuildStep`, nothing to do.
  }

  /// Clear cached information specific to an individual build.
  void reset() {
    _graph.clear();
    _syncedOntoFilesystem.clear();
  }

  /// Attempts to parse [uri] into an [AssetId] and returns it if it is cached.
  ///
  /// Handles 'package:' or 'asset:' URIs, as well as 'file:' URIs of the form
  /// `/$packageName/$assetPath`.
  ///
  /// Returns null if the `Uri` cannot be parsed or is not cached.
  AssetId? lookupCachedAsset(Uri uri) {
    final assetId = AnalysisDriverFilesystem.parseAsset(uri);
    // TODO(davidmorgan): not clear if this is the right "exists" check.
    if (assetId == null || !filesystem.getFile(assetId.asPath).exists) {
      return null;
    }

    return assetId;
  }

  /// Updates [filesystem] and the analysis driver given by
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
    var idsToSyncOntoFilesystem = entryPoints;
    Iterable<AssetId> inputIds = entryPoints;

    // If requested, find transitive imports.
    if (transitive) {
      final previouslyMissingFiles = await _graph.load(buildStep, entryPoints);
      _syncedOntoFilesystem.removeAll(previouslyMissingFiles);
      idsToSyncOntoFilesystem = _graph.nodes.keys.toList();
      inputIds = _graph.inputsFor(entryPoints);
    }

    // Notify [buildStep] of its inputs.
    buildStep.requireInputTracker.assetsRead.addAll(inputIds);

    // Sync changes onto the "URI resolver", the in-memory filesystem.
    for (final id in idsToSyncOntoFilesystem) {
      if (!_syncedOntoFilesystem.add(id)) continue;
      final content =
          await buildStep.canRead(id) ? await buildStep.readAsString(id) : null;
      if (content == null) {
        filesystem.deleteFile(id.asPath);
      } else {
        filesystem.writeFile(id.asPath, content);
      }
    }

    // Notify the analyzer of changes and wait for it to update its internal
    // state.
    for (final path in filesystem.changedPaths) {
      driver.changeFile(path);
    }
    filesystem.clearChangedPaths();
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
  String get asPath => AnalysisDriverFilesystem.assetPath(this);
}

/// The directive graph of all known sources.
///
/// Also tracks whether there is a `.transitive_digest` file next to each source
/// asset, and tracks missing files.
class _Graph {
  final Map<AssetId, _Node> nodes = {};

  /// Walks the import graph from [ids] loading into [nodes].
  ///
  /// Checks files that are in the graph as missing to determine whether they
  /// are now available.
  ///
  /// Returns the set of files that were in the graph as missing and have now
  /// been loaded.
  Future<Set<AssetId>> load(AssetReader reader, Iterable<AssetId> ids) async {
    // TODO(davidmorgan): check if List is faster.
    final nextIds = Queue.of(ids);
    final processed = <AssetId>{};
    final previouslyMissingFiles = <AssetId>{};
    while (nextIds.isNotEmpty) {
      final id = nextIds.removeFirst();

      if (!processed.add(id)) continue;

      // Read nodes not yet loaded or that were missing when loaded.
      var node = nodes[id];
      if (node == null || node.isMissing) {
        if (await reader.canRead(id)) {
          // If it was missing when loaded, record that.
          if (node != null && node.isMissing) {
            previouslyMissingFiles.add(id);
          }
          // Load the node.
          final hasTransitiveDigestAsset =
              await reader.canRead(id.addExtension(_transitiveDigestExtension));
          final content = await reader.readAsString(id);
          final deps = _parseDependencies(content, id);
          node = _Node(
              id: id,
              deps: deps,
              hasTransitiveDigestAsset: hasTransitiveDigestAsset);
        } else {
          node ??= _Node.missing(id: id, hasTransitiveDigestAsset: false);
        }
        nodes[id] = node;
      }

      // Continue to deps even for already-loaded nodes, to check missing files.
      nextIds.addAll(node.deps.where((id) => !processed.contains(id)));
    }

    return previouslyMissingFiles;
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
