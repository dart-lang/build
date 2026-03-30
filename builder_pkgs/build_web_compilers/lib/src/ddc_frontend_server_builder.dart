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

/// A builder that compiles DDC modules with the Frontend Server.
class DdcFrontendServerBuilder implements Builder {
  DdcFrontendServerBuilder();

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
    final moduleContents = await buildStep.readAsString(buildStep.inputId);
    final module = Module.fromJson(
      json.decode(moduleContents) as Map<String, dynamic>,
    );
    final ddcEntrypointId = module.primarySource;
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
    } on FrontendServerCompilationException catch (e) {
      await handleError(e);
    } on MissingModulesException catch (e) {
      await handleError(e);
    }
  }

  /// Compile [module] with Frontend Server.
  Future<void> _compile(Module module, BuildStep buildStep) async {
    final transitiveAssets = await buildStep.trackStage(
      'CollectTransitiveDeps',
      () => module.computeTransitiveAssets(buildStep),
    );
    final frontendServerState = await buildStep.fetchResource(
      frontendServerStateResource,
    );

    if (frontendServerState.entrypointAssetId == null) {
      // Reuse the recorded entrypoint asset if it was generated in a previous
      // build.
      final webEntrypointAsset = AssetId(
        buildStep.inputId.package,
        'web/.web.entrypoint.json',
      );
      if (await buildStep.canRead(webEntrypointAsset)) {
        final contents =
            json.decode(await buildStep.readAsString(webEntrypointAsset))
                as Map<String, dynamic>;
        frontendServerState.entrypointAssetId = AssetId.parse(
          contents['entrypoint'] as String,
        );
      } else {
        log.severe(
          'Unable to read entrypoint when building ${buildStep.inputId}.',
        );
        return;
      }
    }

    final scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
    final webEntrypointAsset = frontendServerState.entrypointAssetId!;
    await buildStep.trackStage(
      'EnsureAssets',
      () => scratchSpace.ensureAssets([
        webEntrypointAsset,
        ...transitiveAssets,
      ], buildStep),
    );
    final changedAssetUris = [
      for (final asset in scratchSpace.changedFilesInBuild) asset.uri,
    ];
    final ddcEntrypointId = module.primarySource;
    final jsOutputId = ddcEntrypointId.changeExtension(jsModuleExtension);
    final jsFESOutputId = ddcEntrypointId.changeExtension('.dart.lib.js');

    final frontendServer = await buildStep.fetchResource(
      persistentFrontendServerResource,
    );
    final driver = await buildStep.fetchResource(
      frontendServerProxyDriverResource,
    );
    driver.init(frontendServer);

    // Request from the Frontend Server exactly the JS file requested by
    // build_runner. Frontend Server's recompilation logic will avoid
    // extraneous recompilation.
    final compilerOutput = await driver.recompileAndRecord(
      sourceArg(webEntrypointAsset),
      changedAssetUris,
      [sourceArg(jsFESOutputId)],
    );
    if (compilerOutput == null) {
      throw FrontendServerCompilationException(
        webEntrypointAsset,
        'Frontend Server produced no output.',
      );
    }
    if (compilerOutput.errorCount != 0 || compilerOutput.errorMessage != null) {
      throw FrontendServerCompilationException(
        webEntrypointAsset,
        compilerOutput.errorMessage!,
      );
    }
    final outputFile = scratchSpace.fileFor(jsOutputId);
    final metadataId = ddcEntrypointId.changeExtension(metadataExtension);
    final metadataFile = scratchSpace.fileFor(metadataId);
    // Write empty files if this output was deemed extraneous by FES.
    if (!outputFile.existsSync()) {
      await outputFile.create(recursive: true);
      await metadataFile.create(recursive: true);
      return;
    }
    await scratchSpace.copyOutput(jsOutputId, buildStep);
    await fixAndCopySourceMap(
      ddcEntrypointId.changeExtension(jsSourceMapExtension),
      scratchSpace,
      buildStep,
    );

    // Copy the metadata output, modifying its contents to remove the temp
    // directory from paths
    final content = await metadataFile.readAsString();
    final metadataJson = jsonDecode(content) as Map<String, Object?>;
    fixMetadataSources(metadataJson, scratchSpace.tempDir.uri);
    await buildStep.writeAsString(metadataId, jsonEncode(metadataJson));
  }
}
