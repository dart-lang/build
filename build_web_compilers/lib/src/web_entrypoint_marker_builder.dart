// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:glob/glob.dart';

/// A builder that gathers information about a web target's 'main' entrypoint.
class WebEntrypointMarkerBuilder implements Builder {
  @override
  final buildExtensions = const {
    r'$web$': ['.web.entrypoint.json'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final scratchSpace = await buildStep.fetchResource(scratchSpaceResource);

    final webAssets = await buildStep.findAssets(Glob('web/**')).toList();
    final webEntrypointJson = <String, dynamic>{};

    for (final asset in webAssets) {
      if (asset.extension == '.dart') {
        final moduleLibrary = ModuleLibrary.fromSource(
          asset,
          await buildStep.readAsString(asset),
        );
        if (moduleLibrary.hasMain && moduleLibrary.isEntryPoint) {
          // We must save the main entrypoint as the recompilation target for
          // the Frontend Server before any JS files are emitted.
          scratchSpace.entrypointAssetId = asset;
          webEntrypointJson['entrypoint'] = asset.uri.toString();
          break;
        }
      }
    }

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'web/.web.entrypoint.json'),
      jsonEncode(webEntrypointJson),
    );
  }
}
