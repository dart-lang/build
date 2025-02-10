// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:build/build.dart' show AssetId, BuildStep;
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:graphs/graphs.dart';
import 'package:path/path.dart' as p;

import 'analysis_driver_filesystem.dart';
import 'analysis_driver_model.dart';

const _ignoredSchemes = ['dart', 'dart-ext'];

const transitiveDigestExtension = '.transitive_digest';

/// Switches [BuildAssetUriResolver.sharedInstance] from [BuildAssetUriResolver]
/// to [AnalysisDriverModel].
void useExperimentalResolver() {
  BuildAssetUriResolver._sharedInstance = AnalysisDriverModel();
}

class BuildAssetUriResolver implements AnalysisDriverModel {
  /// A cache of the directives for each Dart library.
  ///
  /// This is stored across builds and is only invalidated if we read a file and
  /// see that it's content is different from what it was last time it was read.
  final _cachedAssetState = <AssetId, _AssetState>{};

  /// A cache of the digest for each Dart asset.
  ///
  /// This is stored across builds and used to invalidate the values in
  /// [_cachedAssetState] only when the actual content of the library
  /// changed.
  final _cachedAssetDigests = <AssetId, Digest>{};

  @override
  final filesystem = AnalysisDriverFilesystem();

  /// The assets which are known to be readable at some point during the current
  /// build.
  ///
  /// When actions can run out of order an asset can move from being readable
  /// (in the later phase) to being unreadable (in the earlier phase which ran
  /// later). If this happens we don't want to hide the asset from the analyzer.
  final globallySeenAssets = HashSet<AssetId>();

  /// The assets which have been resolved from a [BuildStep], either as an
  /// input, subsequent calls to a resolver, or a transitive import thereof.
  final _buildStepTransitivelyResolvedAssets = <BuildStep, HashSet<AssetId>>{};

  /// Use the [sharedInstance] getter to get the shared instance, which is what
  /// real builds should do. There should always be a 1:1 relationship between
  /// [BuildAssetUriResolver]s and `AnalyzerResolvers`.
  BuildAssetUriResolver();

  /// The instance used by the shared `AnalyzerResolvers` instance, which is
  /// what should be used by normal builds.
  ///
  /// This is not used within testing contexts or similar custom contexts.
  static AnalysisDriverModel get sharedInstance => _sharedInstance;
  static AnalysisDriverModel _sharedInstance = _sharedUriResolverInstance;
  // Keep a [BuildAssetUriResolver] instance even if [useExperimentalResolver]
  // is called, for [dependenciesOf].
  static final BuildAssetUriResolver _sharedUriResolverInstance =
      BuildAssetUriResolver();

  @override
  Future<void> performResolve(
      BuildStep buildStep,
      List<AssetId> entryPoints,
      Future<void> Function(
              FutureOr<void> Function(AnalysisDriverForPackageBuild))
          withDriverResource,
      {required bool transitive}) async {
    final transitivelyResolved = _buildStepTransitivelyResolvedAssets
        .putIfAbsent(buildStep, HashSet.new);
    bool notCrawled(AssetId asset) => !transitivelyResolved.contains(asset);

    final uncrawledIds = entryPoints.where(notCrawled);
    if (transitive) {
      await crawlAsync<AssetId, _AssetState?>(
          uncrawledIds,
          (id) => _updateCachedAssetState(id, buildStep,
              transitivelyResolved: transitivelyResolved), (id, state) async {
        if (state == null) return const [];
        // Establishes a dependency on the transitive deps digest.
        final hasTransitiveDigestAsset =
            await buildStep.canRead(id.addExtension(transitiveDigestExtension));
        return hasTransitiveDigestAsset
            // Only crawl assets that we haven't yet loaded into the
            // analyzer if we are using transitive digests for invalidation.
            ? state.dependencies.whereNot(_cachedAssetDigests.containsKey)
            // Otherwise fall back on crawling all source deps.
            : state.dependencies.where(notCrawled);
      }).drain<void>();
    } else {
      for (final id in uncrawledIds) {
        await _updateCachedAssetState(id, buildStep);
      }
    }
    await withDriverResource((driver) async {
      for (final path in filesystem.changedPaths) {
        driver.changeFile(path);
      }
      filesystem.clearChangedPaths();
      await driver.applyPendingFileChanges();
    });
  }

  /// Updates the internal state for [id], if it has changed.
  ///
  /// This calls `removeFile`, `updateFile` or `newFile` on the
  /// `resourceProvider`, but it does NOT call `changeFile` on the
  /// `AnalysisDriver`.
  ///
  /// After all assets have been updated, then `changeFile` should be called on
  /// the `AnalysisDriver` for all changed assets.
  ///
  /// If [id] can be read, then it will be added to [transitivelyResolved] (if
  /// non-null).
  Future<_AssetState?> _updateCachedAssetState(AssetId id, BuildStep buildStep,
      {Set<AssetId>? transitivelyResolved}) async {
    late final path = assetPath(id);
    if (!await buildStep.canRead(id)) {
      if (globallySeenAssets.contains(id)) {
        // ignore from this graph, some later build step may still be using it
        // so it shouldn't be removed from [resourceProvider], but we also
        // don't care about it's transitive imports.
        return null;
      }
      _cachedAssetState.remove(id);
      _cachedAssetDigests.remove(id);
      filesystem.deleteFile(path);
      return _AssetState(path, const {});
    }
    globallySeenAssets.add(id);
    transitivelyResolved?.add(id);
    final digest = await buildStep.digest(id);

    final cachedAsset = _cachedAssetDigests[id];
    if (cachedAsset == digest) {
      return _cachedAssetState[id];
    } else {
      final content = await buildStep.readAsString(id);
      if (_cachedAssetDigests[id] == digest) {
        // Cache may have been updated while reading asset content
        return _cachedAssetState[id];
      }
      filesystem.writeFile(path, content);
      _cachedAssetDigests[id] = digest;
      return _cachedAssetState[id] =
          _AssetState(path, _parseDependencies(content, id));
    }
  }

  /// Attempts to parse [uri] into an [AssetId].
  ///
  /// Handles 'package:' or 'asset:' URIs, as well as 'file:' URIs that have the
  /// same pattern used by [assetPath].
  ///
  /// Returns null if the Uri cannot be parsed.
  AssetId? parseAsset(Uri uri) {
    if (_ignoredSchemes.any(uri.isScheme)) return null;
    if (uri.isScheme('package') || uri.isScheme('asset')) {
      return AssetId.resolve(uri);
    }
    if (uri.isScheme('file')) {
      final parts = p.split(uri.path);
      return AssetId(parts[1], p.posix.joinAll(parts.skip(2)));
    }
    return null;
  }

  @override
  AssetId? lookupCachedAsset(Uri uri) {
    final assetId = parseAsset(uri);
    if (assetId == null || !_cachedAssetDigests.containsKey(assetId)) {
      return null;
    }

    return assetId;
  }

  @override
  void notifyComplete(BuildStep step) {
    _buildStepTransitivelyResolvedAssets.remove(step);
  }

  @override
  void reset() {
    assert(_buildStepTransitivelyResolvedAssets.isEmpty,
        'Reset was called before all build steps completed');
    globallySeenAssets.clear();
  }
}

String assetPath(AssetId assetId) =>
    p.posix.join('/${assetId.package}', assetId.path);

Future<String> packagePath(String package) async {
  var libRoot = await Isolate.resolvePackageUri(Uri.parse('package:$package/'));
  return p.dirname(p.fromUri(libRoot));
}

/// Returns all the directives from a Dart library that can be resolved to an
/// [AssetId].
Set<AssetId> _parseDependencies(String content, AssetId from) => HashSet.of(
      parseString(content: content, throwIfDiagnostics: false)
          .unit
          .directives
          .whereType<UriBasedDirective>()
          .map((directive) => directive.uri.stringValue)
          // Filter out nulls. uri.stringValue can be null for strings that use
          // interpolation.
          .whereType<String>()
          .where((uriContent) =>
              !_ignoredSchemes.any(Uri.parse(uriContent).isScheme))
          .map((content) => AssetId.resolve(Uri.parse(content), from: from)),
    );

/// Read the (potentially) cached dependencies of [id] based on parsing the
/// directives, and cache the results if they weren't already cached.
///
/// TODO(davidmorgan): remove this or make it use `AnalysisDriverModel`.
Future<Iterable<AssetId>?> dependenciesOf(
        AssetId id, BuildStep buildStep) async =>
    (await BuildAssetUriResolver._sharedUriResolverInstance
            ._updateCachedAssetState(id, buildStep))
        ?.dependencies;

class _AssetState {
  final String path;
  final Set<AssetId> dependencies;

  _AssetState(this.path, this.dependencies);
}
