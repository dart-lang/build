// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'build_modules/build_modules.dart';
import 'common.dart';

/// A builder that gathers information about a web target's 'main' entrypoint.
class WebEntrypointMarkerBuilder implements Builder {
  /// Records state (such as the web entrypoint) required when compiling DDC
  /// with the Frontend Server, which supports hot reload.
  ///
  /// A no-op if [usesWebHotReload] is not set.
  final bool usesWebHotReload;

  /// The directories to search in for the web target's `main` entrypoint.
  ///
  /// Directories are searched in the specified order.
  /// Defaults to [defaultWebDirs].
  final List<String> webAssetPaths;

  /// Creates a builder that marks the web target's `main` entrypoint.
  ///
  /// Does nothing unless [usesWebHotReload] is `true`.
  ///
  /// The entrypoint is searched for in [webAssetPaths],
  /// which defaults to [defaultWebDirs] if not specified.
  WebEntrypointMarkerBuilder({
    this.usesWebHotReload = false,
    List<String>? webAssetPaths,
  }) : webAssetPaths = webAssetPaths ?? defaultWebDirs;

  @override
  final buildExtensions = const {
    r'$web$': ['.web.entrypoint.json'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    if (!usesWebHotReload) return;

    final frontendServerState = await buildStep.fetchResource(
      frontendServerStateResource,
    );

    final hasCachedState = await frontendServerState.checkAndDeserializeState(
      buildStep,
    );

    final entrypointAssetId = hasCachedState
        ? frontendServerState.entrypointAssetId!
        : await _findEntrypoint(buildStep);
    if (entrypointAssetId != null) {
      // We must save the main entrypoint as the recompilation target for the
      // Frontend Server before any JS files are emitted.
      frontendServerState.entrypointAssetId = entrypointAssetId;
    }

    await buildStep.writeAsString(
      webEntrypointStateAssetId(buildStep.inputId.package),
      jsonEncode(<String, Object?>{
        if (entrypointAssetId != null) ...{
          'entrypoint': entrypointAssetId.toString(),
          'canonicalUri': sourceArg(entrypointAssetId),
        },
      }),
    );

    if (entrypointAssetId == null) return;

    // A generated entrypoint can only be read from a build step in its own
    // package. Stage it here, in the root package, so that the DDC builds of
    // dependency packages can compile against it instead; see
    // `DdcFrontendServerBuilder`.
    //
    // This runs after the state above is written so that a failure to read the
    // entrypoint doesn't take the recorded state down with it.
    final scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
    await buildStep.trackStage(
      'EnsureAssets',
      () => scratchSpace.ensureAssets([entrypointAssetId], buildStep),
    );
    frontendServerState.stagedEntrypointAssetId = entrypointAssetId;
  }

  /// Searches for and returns the highest-priority web app entrypoint,
  /// or `null` if no entrypoint is found.
  ///
  /// The directories in [webAssetPaths] are searched in order,
  /// with the candidates within each ranked by [_compareEntrypointPriority].
  Future<AssetId?> _findEntrypoint(BuildStep buildStep) async {
    for (final searchPath in webAssetPaths) {
      final candidates =
          await buildStep
                .findAssets(Glob('$searchPath/**'))
                .where((asset) => asset.extension == '.dart')
                .toList()
            ..sort(_compareEntrypointPriority);

      for (final asset in candidates) {
        final moduleLibrary = ModuleLibrary.fromSource(
          asset,
          await buildStep.readAsString(asset),
        );
        if (moduleLibrary.hasMain && moduleLibrary.isEntryPoint) return asset;
      }
    }
    return null;
  }
}

/// Compares [a] and [b] by how likely each is to be a web app's entrypoint.
///
/// Assets closer to the root of the searched directory sort first,
/// then those named `main.dart`, then those that sort first alphabetically.
int _compareEntrypointPriority(AssetId a, AssetId b) {
  // A top-level entrypoint is usually the app itself,
  // while a nested one is more often a secondary target,
  // such as a debug or example page.
  if (a.pathSegments.length.compareTo(b.pathSegments.length)
      case final depthComparison when depthComparison != 0) {
    return depthComparison;
  }

  // Among entrypoints alongside each other, `main.dart` is the convention.
  final aIsMain = p.url.basename(a.path) == 'main.dart';
  final bIsMain = p.url.basename(b.path) == 'main.dart';
  if (aIsMain != bIsMain) return aIsMain ? -1 : 1;

  // Fall back to a stable order so the entrypoint doesn't vary between builds.
  return a.path.compareTo(b.path);
}
