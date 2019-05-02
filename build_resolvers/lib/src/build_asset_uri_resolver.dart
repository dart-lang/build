// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// ignore: deprecated_member_use
import 'package:analyzer/analyzer.dart' show parseDirectives;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show AnalysisDriver;
import 'package:analyzer/src/generated/source.dart';
import 'package:build/build.dart' show AssetId, BuildStep;
import 'package:graphs/graphs.dart';
import 'package:path/path.dart' as p;

const _ignoredSchemes = ['dart', 'dart-ext'];

class BuildAssetUriResolver extends UriResolver {
  /// A cache of the directives for each Dart library.
  ///
  /// This stored across builds and is only invalidated if we read a file and
  /// see that it's content is different from what it was last time it was read.
  final _cachedAssetDependencies = <AssetId, Set<AssetId>>{};

  /// A cache of the full content for each Dart asset.
  ///
  /// This is stored across builds and used to invalidate the values in
  /// [_cachedAssetDependencies] only when the actual content of the library
  /// changed.
  final _cachedAssetContents = <AssetId, String>{};

  final resourceProvider = MemoryResourceProvider(context: p.posix);

  /// The assets which are known to be readable at some point during the build.
  ///
  /// When actions can run out of order an asset can move from being readable
  /// (in the later phase) to being unreadable (in the earlier phase which ran
  /// later). If this happens we don't want to hide the asset from the analyzer.
  final seenAssets = Set<AssetId>();

  Future<void> performResolve(BuildStep buildStep, List<AssetId> entryPoints,
      AnalysisDriver driver) async {
    final states =
        await crawlAsync<AssetId, _AssetState>(entryPoints, (id) async {
      try {
        return _AssetState(id, await buildStep.readAsString(id));
      } catch (e) {
        if (seenAssets.contains(id)) {
          // ignore from this graph, some later build step may still be using it
          // so it shouldn't be removed from [resourceProvider], but we also
          // don't care about it's transitive imports.
          return null;
        }
        _cachedAssetDependencies.remove(id);
        _cachedAssetContents.remove(id);
        return _AssetState.removed(id);
      }
    }, (id, state) {
      if (state.isRemoved) return const [];
      if (_cachedAssetContents[id] == state.content) {
        return _cachedAssetDependencies[id];
      }
      _cachedAssetContents[id] = state.content;
      return _cachedAssetDependencies[id] = _parseDirectives(state);
    }).toList();

    for (final state in states) {
      final path = assetPath(state.id);
      if (state.isRemoved) {
        if (resourceProvider.getFile(path).exists) {
          resourceProvider.deleteFile(path);
        }
      } else {
        if (resourceProvider.getFile(path).exists) {
          resourceProvider.updateFile(path, state.content);
          driver.changeFile(path);
        } else {
          resourceProvider.newFile(path, state.content);
        }
      }
    }
  }

  /// Attempts to parse [uri] into an [AssetId] and returns it if it is cached.
  ///
  /// Handles 'package:' or 'asset:' URIs, as well as 'file:' URIs that have the
  /// same pattern used by [assetPath].
  ///
  /// Returns null if the Uri cannot be parsed or is not cached.
  AssetId lookupAsset(Uri uri) {
    if (_ignoredSchemes.any(uri.isScheme)) return null;
    if (uri.isScheme('package') || uri.isScheme('asset')) {
      final assetId = AssetId.resolve('$uri');
      return _cachedAssetContents.containsKey(assetId) ? assetId : null;
    }
    if (uri.isScheme('file')) {
      final parts = p.split(uri.path);
      final assetId = AssetId(parts[1], p.posix.joinAll(parts.skip(2)));
      return _cachedAssetContents.containsKey(assetId) ? assetId : null;
    }
    return null;
  }

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    final cachedId = lookupAsset(uri);
    if (cachedId == null) return null;
    return resourceProvider
        .getFile(assetPath(cachedId))
        .createSource(cachedId.uri);
  }

  @override
  Uri restoreAbsolute(Source source) =>
      lookupAsset(source.uri)?.uri ?? source.uri;
}

/// Returns all the directives from a Dart library that can be resolved to an
/// [AssetId].
Set<AssetId> _parseDirectives(_AssetState state) =>
    parseDirectives(state.content, suppressErrors: true)
        .directives
        .whereType<UriBasedDirective>()
        .where((directive) {
          var uri = Uri.parse(directive.uri.stringValue);
          return !_ignoredSchemes.any(uri.isScheme);
        })
        .map((d) => AssetId.resolve(d.uri.stringValue, from: state.id))
        .where((id) => id != null)
        .toSet();

class _AssetState {
  final AssetId id;
  final String content;
  final bool isRemoved;

  _AssetState(this.id, this.content) : isRemoved = false;
  _AssetState.removed(this.id)
      : isRemoved = true,
        content = null;
}

String assetPath(AssetId assetId) =>
    p.posix.join('/${assetId.package}', assetId.path);
