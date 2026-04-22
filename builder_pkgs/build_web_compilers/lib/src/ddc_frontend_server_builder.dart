// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

import 'common.dart';
import 'errors.dart';
import 'platforms.dart';

/// A builder that compiles DDC modules with the Frontend Server.
class DdcFrontendServerBuilder implements Builder {
  final bool generateFullDill;

  DdcFrontendServerBuilder({this.generateFullDill = false});

  @override
  Map<String, List<String>> get buildExtensions => {
    moduleExtension(ddcPlatform): [
      jsModuleExtension,
      jsModuleErrorsExtension,
      jsSourceMapExtension,
      metadataExtension,
      if (generateFullDill) fullKernelExtension,
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
    final fullDillId = ddcEntrypointId.changeExtension(fullKernelExtension);
    final compilerOutput = await driver.recompileAndRecord(
      sourceArg(webEntrypointAsset),
      changedAssetUris,
      [sourceArg(jsFESOutputId), if (generateFullDill) sourceArg(fullDillId)],
    );
    if (compilerOutput == null) {
      throw FrontendServerCompilationException(
        webEntrypointAsset,
        'Frontend Server produced no output.',
      );
    }
    if (compilerOutput.errorCount != 0 ||
        (compilerOutput.errorMessage != null &&
            compilerOutput.errorMessage!.contains('Error:'))) {
      throw FrontendServerCompilationException(
        webEntrypointAsset,
        compilerOutput.errorMessage!,
      );
    }
    final fesOutputFile = scratchSpace.fileFor(jsFESOutputId);
    final fesMetadataId = ddcEntrypointId.changeExtension(
      '.dart.lib.js.metadata',
    );
    final fesMetadataFile = scratchSpace.fileFor(fesMetadataId);

    final metadataId = ddcEntrypointId.changeExtension(metadataExtension);
    final metadataFile = scratchSpace.fileFor(metadataId);

    final targetOutputFile = scratchSpace.fileFor(jsOutputId);
    final hasFesOutput = fesOutputFile.existsSync();
    final hasTargetOutput = targetOutputFile.existsSync();

    // Write empty files if this output was deemed extraneous by FES.
    if (!hasFesOutput && !hasTargetOutput) {
      await targetOutputFile.create(recursive: true);
      await metadataFile.create(recursive: true);
      return;
    }

    final fileToRead = hasFesOutput ? fesOutputFile : targetOutputFile;

    // Replace `.dart.lib.js` with `.ddc.js` in the `setSourceMap` call to
    // match the actual DDC output JS file name.
    final content = await fileToRead.readAsString();
    await _fixAndWriteJs(content, jsOutputId, buildStep);

    if (generateFullDill) {
      final outputDillFile = File(
        p.join(scratchSpace.tempDir.path, 'output.dill'),
      );
      log.info(
        'DdcFrontendServerBuilder: outputDillFile exists=${outputDillFile.existsSync()}',
      );
      if (outputDillFile.existsSync()) {
        final fullDillFile = scratchSpace.fileFor(fullDillId);
        await outputDillFile.copy(fullDillFile.path);
        await scratchSpace.copyOutput(fullDillId, buildStep);
      }
    }

    // Handle source map rename if needed
    final fesSourceMapId = ddcEntrypointId.changeExtension('.dart.lib.js.map');
    final fesSourceMapFile = scratchSpace.fileFor(fesSourceMapId);
    final targetSourceMapId = ddcEntrypointId.changeExtension(
      jsSourceMapExtension,
    );
    final targetSourceMapFile = scratchSpace.fileFor(targetSourceMapId);

    if (fesSourceMapFile.existsSync()) {
      await fesSourceMapFile.copy(targetSourceMapFile.path);
    }

    await fixAndCopySourceMap(targetSourceMapId, scratchSpace, buildStep);

    // Copy the metadata output, modifying its contents to remove the temp
    // directory from paths and renaming module references.
    final metadataFileToRead =
        fesMetadataFile.existsSync() ? fesMetadataFile : metadataFile;
    if (metadataFileToRead.existsSync()) {
      await _fixAndWriteMetadata(
        metadataFileToRead,
        metadataId,
        scratchSpace,
        buildStep,
      );
    }
  }

  Future<void> _fixAndWriteJs(
    String content,
    AssetId jsOutputId,
    BuildStep buildStep,
  ) async {
    var fixedContent = content.replaceAllMapped(
      RegExp(r'dartDevEmbedder\.debugger\.setSourceMap\([\s\S]*?\);'),
      (match) =>
          match.group(0)!.replaceAll('.dart.lib.js"', '$jsModuleExtension"'),
    );
    fixedContent = fixedContent.replaceAll(
      '.dart.lib.js.map',
      jsSourceMapExtension,
    );
    await buildStep.writeAsString(jsOutputId, fixedContent);
  }

  Future<void> _fixAndWriteMetadata(
    File file,
    AssetId metadataId,
    ScratchSpace scratchSpace,
    BuildStep buildStep,
  ) async {
    final content = await file.readAsString();
    final metadataJson = jsonDecode(content) as Map<String, Object?>;
    fixMetadataSources(metadataJson, scratchSpace.tempDir.uri);

    final metadataString = jsonEncode(metadataJson);
    final fixedMetadataString = metadataString.replaceAll(
      '.dart.lib.js',
      jsModuleExtension,
    );
    await buildStep.writeAsString(metadataId, fixedMetadataString);
  }
}
