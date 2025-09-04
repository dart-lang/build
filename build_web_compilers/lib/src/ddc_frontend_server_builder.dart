// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';

import 'common.dart';
import 'errors.dart';
import 'platforms.dart';

/// A builder which can compile DDC modules with the Frontend Server.
class DdcFrontendServerBuilder implements Builder {
  final String entrypoint;

  DdcFrontendServerBuilder({required this.entrypoint});

  @override
  final Map<String, List<String>> buildExtensions = {
    moduleExtension(ddcPlatform): [
      jsModuleExtension,
      jsModuleErrorsExtension,
      jsSourceMapExtension,
      metadataExtension,
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    var moduleContents = await buildStep.readAsString(buildStep.inputId);
    final module = Module.fromJson(
      json.decode(moduleContents) as Map<String, dynamic>,
    );
    var ddcEntrypointId = module.primarySource;
    // Entrypoints always have a `.module` file for ease of looking them up,
    // but they might not be the primary source.
    if (ddcEntrypointId.changeExtension(moduleExtension(ddcPlatform)) !=
        buildStep.inputId) {
      return;
    }

    Future<void> handleError(Object e) async {
      await buildStep.writeAsString(
        ddcEntrypointId.changeExtension(jsModuleErrorsExtension),
        '$e',
      );
      log.severe('Error encountered: $e');
    }

    try {
      await _compile(module, buildStep);
    } on DartDevcCompilationException catch (e) {
      await handleError(e);
    } on MissingModulesException catch (e) {
      await handleError(e);
    }
  }

  /// Compile [module] with Frontend Server.
  Future<void> _compile(Module module, BuildStep buildStep) async {
    var transitiveAssets = await buildStep.trackStage(
      'CollectTransitiveDeps',
      () => module.computeTransitiveAssets(buildStep),
    );
    final scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
    // Resolve the 'real' entrypoint we'll pass to FES for compilation.
    final webEntrypointAsset = AssetId.resolve(Uri.parse(entrypoint));
    await buildStep.trackStage(
      'EnsureAssets',
      () => scratchSpace.ensureAssets([
        ...transitiveAssets,
        webEntrypointAsset,
      ], buildStep),
    );
    var ddcEntrypointId = module.primarySource;
    var jsOutputId = ddcEntrypointId.changeExtension(jsModuleExtension);

    final frontendServer = await buildStep.fetchResource(
      persistentFrontendServerResource,
    );
    final driver = await buildStep.fetchResource(
      frontendServerProxyDriverResource,
    );
    driver.init(frontendServer);
    final invalidatedFileUris = [for (var source in module.sources) source.uri];
    await driver.recompileAndRecord(
      sourceArg(ddcEntrypointId),
      invalidatedFileUris,
    );
    final outputFile = scratchSpace.fileFor(jsOutputId);
    // Write an empty file if this file was deemed extraneous by FES.
    if (!!await outputFile.exists()) {
      await outputFile.create(recursive: true);
    }
    await scratchSpace.copyOutput(jsOutputId, buildStep);
    await fixAndCopySourceMap(
      ddcEntrypointId.changeExtension(jsSourceMapExtension),
      scratchSpace,
      buildStep,
    );

    // Copy the metadata output, modifying its contents to remove the temp
    // directory from paths
    var metadataId = ddcEntrypointId.changeExtension(metadataExtension);
    var file = scratchSpace.fileFor(metadataId);
    var content = await file.readAsString();
    var json = jsonDecode(content) as Map<String, Object?>;
    fixMetadataSources(json, scratchSpace.tempDir.uri);
    await buildStep.writeAsString(metadataId, jsonEncode(json));
  }
}
