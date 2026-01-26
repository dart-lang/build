// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

/// A builder that gathers information about a web target's 'main' entrypoint.
class WebEntrypointMarkerBuilder implements Builder {
  /// Records state (such as the web entrypoint) required when compiling DDC
  /// with the Frontend Server, which supports hot reload.
  ///
  /// A no-op if [usesWebHotReload] is not set.
  final bool usesWebHotReload;

  WebEntrypointMarkerBuilder({this.usesWebHotReload = false});

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
    final frontendServerStateWasLoaded = await frontendServerState
        .checkAndDeserializeState(buildStep);
    if (frontendServerStateWasLoaded) return;

    final webAssets = await buildStep.findAssets(Glob('web/**')).toList();
    final webEntrypointJson = <String, Object?>{};

    for (final asset in webAssets) {
      if (asset.extension == '.dart') {
        final moduleLibrary = ModuleLibrary.fromSource(
          asset,
          await buildStep.readAsString(asset),
        );
        if (moduleLibrary.hasMain && moduleLibrary.isEntryPoint) {
          // We must save the main entrypoint as the recompilation target for
          // the Frontend Server before any JS files are emitted.
          frontendServerState.entrypointAssetId = asset;
          webEntrypointJson['entrypoint'] = asset.toString();
          break;
        }
      }
    }

    final rootDir = p.dirname(buildStep.inputId.path);
    final webEntrypointAsset = AssetId(
      buildStep.inputId.package,
      p.join(rootDir, '.web.entrypoint.json'),
    );

    await buildStep.writeAsString(
      webEntrypointAsset,
      jsonEncode(webEntrypointJson),
    );
  }
}
