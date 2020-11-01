// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show AnalysisDriver;
import 'package:analyzer/src/generated/source.dart';
import 'package:build/build.dart' show AssetId, BuildStep;
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:graphs/graphs.dart';
import 'package:path/path.dart' as p;

const _ignoredSchemes = ['dart', 'dart-ext'];

class BuildAssetUriResolver extends UriResolver {
  /// A cache of the directives for each Dart library.
  ///
  /// This is stored across builds and is only invalidated if we read a file and
  /// see that it's content is different from what it was last time it was read.
  final _cachedAssetDependencies = <AssetId, Set<AssetId>>{};

  /// A cache of the digest for each Dart asset.
  ///
  /// This is stored across builds and used to invalidate the values in
  /// [_cachedAssetDependencies] only when the actual content of the library
  /// changed.
  final _cachedAssetDigests = <AssetId, Digest>{};

  /// Asset paths which have been updated in [resourceProvider] but not yet
  /// updated in the analysis driver.
  final _needsChangeFile = HashSet<String>();

  final resourceProvider = MemoryResourceProvider(context: p.posix);

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

  /// Updates [resourceProvider] and [driver] with updated versions of
  /// [entryPoints].
  ///
  /// If [transitive], then all the transitive imports from [entryPoints] are
  /// also updated.
  Future<void> performResolve(
      BuildStep buildStep, List<AssetId> entryPoints, AnalysisDriver driver,
      {@required bool transitive}) async {
    final transitivelyResolved = _buildStepTransitivelyResolvedAssets
        .putIfAbsent(buildStep, () => HashSet());
    bool notCrawled(AssetId asset) => !transitivelyResolved.contains(asset);

    final uncrawledIds = entryPoints.where(notCrawled);
    final assetStates = transitive
        ? await crawlAsync<AssetId, _AssetState>(
            uncrawledIds,
            (id) => _updateCachedAssetState(id, buildStep,
                transitivelyResolved: transitivelyResolved),
            (id, state) => state.dependencies.where(notCrawled)).toList()
        : [
            for (var id in uncrawledIds)
              await _updateCachedAssetState(id, buildStep),
          ];

    for (final state in assetStates) {
      if (_needsChangeFile.remove(state.path)) {
        driver.changeFile(state.path);
      }
    }
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
  Future<_AssetState> _updateCachedAssetState(AssetId id, BuildStep buildStep,
      {Set<AssetId> /*?*/ transitivelyResolved}) async {
    final path = assetPath(id);
    if (!await buildStep.canRead(id)) {
      if (globallySeenAssets.contains(id)) {
        // ignore from this graph, some later build step may still be using it
        // so it shouldn't be removed from [resourceProvider], but we also
        // don't care about it's transitive imports.
        return null;
      }
      _cachedAssetDependencies.remove(id);
      _cachedAssetDigests.remove(id);
      if (resourceProvider.getFile(path).exists) {
        resourceProvider.deleteFile(path);
      }
      return _AssetState(path, const []);
    }
    globallySeenAssets.add(id);
    transitivelyResolved?.add(id);
    final digest = await buildStep.digest(id);
    if (_cachedAssetDigests[id] == digest) {
      return _AssetState(path, _cachedAssetDependencies[id]);
    } else {
      final isChange = _cachedAssetDigests.containsKey(id);
      final content = await buildStep.readAsString(id);
      if (_cachedAssetDigests[id] == digest) {
        // Cache may have been updated while reading asset content
        return _AssetState(path, _cachedAssetDependencies[id]);
      }
      if (isChange) {
        resourceProvider.updateFile(path, content);
      } else {
        resourceProvider.newFile(path, content);
      }
      _cachedAssetDigests[id] = digest;
      _needsChangeFile.add(path);
      final dependencies =
          _cachedAssetDependencies[id] = _parseDirectives(content, id);
      return _AssetState(path, dependencies);
    }
  }

  /// Attempts to parse [uri] into an [AssetId].
  ///
  /// Handles 'package:' or 'asset:' URIs, as well as 'file:' URIs that have the
  /// same pattern used by [assetPath].
  ///
  /// Returns null if the Uri cannot be parsed.
  AssetId parseAsset(Uri uri) {
    if (_ignoredSchemes.any(uri.isScheme)) return null;
    if (uri.isScheme('package') || uri.isScheme('asset')) {
      return AssetId.resolve('$uri');
    }
    if (uri.isScheme('file')) {
      final parts = p.split(uri.path);
      return AssetId(parts[1], p.posix.joinAll(parts.skip(2)));
    }
    return null;
  }

  /// Attempts to parse [uri] into an [AssetId] and returns it if it is cached.
  ///
  /// Handles 'package:' or 'asset:' URIs, as well as 'file:' URIs that have the
  /// same pattern used by [assetPath].
  ///
  /// Returns null if the Uri cannot be parsed or is not cached.
  AssetId lookupCachedAsset(Uri uri) {
    final assetId = parseAsset(uri);
    if (assetId == null || !_cachedAssetDigests.containsKey(assetId)) {
      return null;
    }

    return assetId;
  }

  void notifyComplete(BuildStep step) {
    _buildStepTransitivelyResolvedAssets.remove(step);
  }

  /// Clear cached information specific to an individual build.
  void reset() {
    assert(_buildStepTransitivelyResolvedAssets.isEmpty,
        'Reset was called before all build steps completed');
    globallySeenAssets.clear();
    _needsChangeFile.clear();
  }

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    final assetId = parseAsset(uri);
    if (assetId == null) return null;

    return resourceProvider
        .getFile(assetPath(assetId))
        .createSource(assetId.uri);
  }

  @override
  Uri restoreAbsolute(Source source) =>
      lookupCachedAsset(source.uri)?.uri ?? source.uri;
}

String assetPath(AssetId assetId) =>
    p.posix.join('/${assetId.package}', assetId.path);

/// Returns all the directives from a Dart library that can be resolved to an
/// [AssetId].
Set<AssetId> _parseDirectives(String content, AssetId from) =>
    HashSet.of(parseString(content: content, throwIfDiagnostics: false)
        .unit
        .directives
        .whereType<UriBasedDirective>()
        .where((directive) {
          var uri = Uri.parse(directive.uri.stringValue);
          return !_ignoredSchemes.any(uri.isScheme);
        })
        .map((d) => AssetId.resolve(d.uri.stringValue, from: from))
        .where((id) => id != null));

class _AssetState {
  final String path;
  final Iterable<AssetId> dependencies;

  _AssetState(this.path, this.dependencies);
}
