// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

// ignore: deprecated_member_use
import 'package:analyzer/analyzer.dart' show parseDirectives;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show AnalysisDriver;
import 'package:analyzer/src/generated/source.dart';
import 'package:build/build.dart' show AssetId, BuildStep;
import 'package:crypto/crypto.dart';
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
  final _buildStepAssets = <BuildStep, HashSet<AssetId>>{};

  /// Crawl the transitive imports from [entryPoints] and ensure that the
  /// content of each asset is updated in [resourceProvider] and [driver].
  Future<void> performResolve(BuildStep buildStep, List<AssetId> entryPoints,
      AnalysisDriver driver) async {
    final seenInBuildStep =
        _buildStepAssets.putIfAbsent(buildStep, () => HashSet());
    bool notCrawled(AssetId asset) => !seenInBuildStep.contains(asset);

    final changedPaths = await crawlAsync<AssetId, _AssetState>(
            entryPoints.where(notCrawled), (id) async {
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
        return _AssetState.removed(path);
      }
      globallySeenAssets.add(id);
      seenInBuildStep.add(id);
      final digest = await buildStep.digest(id);
      if (_cachedAssetDigests[id] == digest) {
        return _AssetState.unchanged(path, _cachedAssetDependencies[id]);
      } else {
        final isChange = _cachedAssetDigests.containsKey(id);
        final content = await buildStep.readAsString(id);
        _cachedAssetDigests[id] = digest;
        final dependencies =
            _cachedAssetDependencies[id] = _parseDirectives(content, id);
        if (isChange) {
          resourceProvider.updateFile(path, content);
          return _AssetState.changed(path, dependencies);
        } else {
          resourceProvider.newFile(path, content);
          return _AssetState.newAsset(path, dependencies);
        }
      }
    }, (id, state) => state.directives.where(notCrawled))
        .where((state) => state.isAssetUpdate)
        .map((state) => state.path)
        .toList();
    changedPaths.forEach(driver.changeFile);
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
    _buildStepAssets.remove(step);
  }

  /// Clear cached information specific to an individual build.
  void reset() {
    assert(_buildStepAssets.isEmpty,
        'Reset was called before all build steps completed');
    globallySeenAssets.clear();
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
    // ignore: deprecated_member_use
    HashSet.of(parseDirectives(content, suppressErrors: true)
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
  final bool isAssetUpdate;
  final Iterable<AssetId> directives;

  _AssetState.removed(this.path)
      : isAssetUpdate = false,
        directives = const [];
  _AssetState.changed(this.path, this.directives) : isAssetUpdate = true;
  _AssetState.unchanged(this.path, this.directives) : isAssetUpdate = false;
  _AssetState.newAsset(this.path, this.directives) : isAssetUpdate = true;
}
