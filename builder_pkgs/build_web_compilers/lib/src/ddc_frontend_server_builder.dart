// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:scratch_space/scratch_space.dart';

import 'build_modules/build_modules.dart';
import 'common.dart';
import 'errors.dart';
import 'platforms.dart';

/// A builder that compiles DDC modules with the Frontend Server.
class DdcFrontendServerBuilder implements Builder {
  /// A custom directory to use for the scratch space, if provided.
  ///
  /// Used to share the scratch space directory with the `fes_manager` process
  /// when it is initialized separately from the build daemon (like in tests).
  final String? scratchSpaceDir;

  /// A persistent scratch space instance used when a custom scratch space
  /// directory is provided.
  ///
  /// We cache this instance to maintain ScratchSpace's in-memory digests cache
  /// for recompiles.
  ScratchSpace? _scratchSpace;

  DdcFrontendServerBuilder({this.scratchSpaceDir});

  @override
  Map<String, List<String>> get buildExtensions => {
    moduleExtension(ddcPlatform): [
      jsModuleExtension,
      jsModuleErrorsExtension,
      jsSourceMapExtension,
      metadataExtension,
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final frontendServerState = await buildStep.fetchResource(
      frontendServerStateResource,
    );
    final moduleContents = await buildStep.readAsString(buildStep.inputId);
    final module = Module.fromJson(
      json.decode(moduleContents) as Map<String, dynamic>,
    );
    final ddcEntrypointId = module.primarySource;
    final entrypoint = frontendServerState.entrypointAssetId;
    final isEntrypoint = entrypoint == null
        ? ddcEntrypointId.changeExtension('.ddc.module') == buildStep.inputId
        : ddcEntrypointId == entrypoint;
    if (isEntrypoint && entrypoint == null) {
      frontendServerState.entrypointAssetId = ddcEntrypointId;
    }
    final entrypointAssetId = frontendServerState.entrypointAssetId!;
    final transitiveDeps = await buildStep.trackStage(
      'CollectTransitiveDeps',
      () => module.computeTransitiveDependencies(buildStep),
    );
    final transitiveJsDeps = [
      for (final dep in transitiveDeps)
        if (dep.primarySource.package != buildStep.inputId.package) ...[
          dep.primarySource.changeExtension(jsModuleExtension),
          dep.primarySource.changeExtension(metadataExtension),
        ],
    ];
    final transitiveSources = [
      for (final dep in transitiveDeps) ...dep.sources,
    ];
    final scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
    await buildStep.trackStage(
      'EnsureAssets',
      () => scratchSpace.ensureAssets([
        ...module.sources,
        ...transitiveSources,
      ], buildStep),
    );
    final root = getRootPackageName();
    final driver = await buildStep.fetchResource(
      frontendServerProxyDriverResource,
    );
    await buildStep.fetchResource(persistentFrontendServerResource);
    final entrypointArg = sourceArg(frontendServerState.entrypointAssetId!);
    String assetPath(AssetId id) => id.package == root
        ? id.path
        : 'packages/${id.package}/${id.path.replaceFirst('lib/', '')}';
    final changedAssetUris = [
      for (final asset in scratchSpace.changedFilesInBuild)
        Uri(scheme: multiRootScheme, host: '', path: '/${assetPath(asset)}'),
    ];
    try {
      frontendServerState.triggerSharedCompilation(entrypointAssetId, () async {
        final ScratchSpace sSpace;
        final customDir = scratchSpaceDir;
        if (customDir != null) {
          frontendServerState.customScratchSpacePath = customDir;
          sSpace = _scratchSpace ??= ScratchSpace.existing(
            Directory(customDir),
          );
        } else {
          sSpace = scratchSpace;
        }
        await buildStep.trackStage(
          'EnsureAssets',
          () => sSpace.ensureAssets([
            if (frontendServerState.entrypointAssetId!.package ==
                buildStep.inputId.package)
              frontendServerState.entrypointAssetId!,
          ], buildStep),
        );
        final compilerOutput = await driver.recompileAndRecord(
          entrypointArg,
          changedAssetUris,
          [assetPath(ddcEntrypointId.changeExtension(fesJsExtension))],
          recompileRestart: frontendServerState.needsRecompileRestart,
        );
        if (compilerOutput == null) {
          throw FrontendServerCompilationException(
            frontendServerState.entrypointAssetId!,
            'Frontend Server produced no output.',
          );
        }
        if (compilerOutput.errorCount != 0) {
          throw FrontendServerCompilationException(
            frontendServerState.entrypointAssetId!,
            compilerOutput.errorMessage ?? 'Unknown error',
          );
        }
      });
      await frontendServerState.waitForCompilation(entrypointAssetId);
      await buildStep.trackStage(
        'EnsureAssets',
        () => scratchSpace.ensureAssets(transitiveJsDeps, buildStep),
      );

      final jsOutputId = ddcEntrypointId.changeExtension(jsModuleExtension);
      final mapOutputId = ddcEntrypointId.changeExtension(jsSourceMapExtension);
      final metadataOutputId = ddcEntrypointId.changeExtension(
        metadataExtension,
      );

      final jsPath = '$testScratchSpacePathPrefix${assetPath(jsOutputId)}';
      final mapPath = '$testScratchSpacePathPrefix${assetPath(mapOutputId)}';
      final metadataPath =
          '$testScratchSpacePathPrefix${assetPath(metadataOutputId)}';

      final jsContent = await driver.readInMemoryFile(
        jsPath,
        entrypointArg,
        changedAssetUris,
      );
      final mapContent = await driver.readInMemoryFile(
        mapPath,
        entrypointArg,
        changedAssetUris,
      );
      final metadataContent = await driver.readInMemoryFile(
        metadataPath,
        entrypointArg,
        changedAssetUris,
      );

      if (jsContent != null) {
        await buildStep.writeAsString(jsOutputId, jsContent);
      }
      if (mapContent != null) {
        await buildStep.writeAsString(mapOutputId, mapContent);
      }
      if (metadataContent != null) {
        await buildStep.writeAsString(metadataOutputId, metadataContent);
      }

      if (isEntrypoint) {
        frontendServerState.needsRecompileRestart = false;
      }
    } catch (e) {
      frontendServerState.needsRecompileRestart = true;
      rethrow;
    }
  }
}
