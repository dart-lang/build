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

  /// Caches [ScratchSpace]s by their directory path.
  ///
  /// We typically expect one scratch space to be provided per compilation,
  /// but integration tests frequently run separate compilations on the same
  /// entrypoint in the same process.
  static final Map<String, ScratchSpace> _scratchSpaceCache = {};

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
    final transitiveDeps = await module.computeTransitiveDependencies(
      buildStep,
    );
    final transitiveSources = [
      for (final dep in transitiveDeps) ...dep.sources,
    ];
    var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
    await scratchSpace.ensureAssets([
      ...module.sources,
      ...transitiveSources,
    ], buildStep);
    final root = getRootPackageName();
    final driver = await buildStep.fetchResource(
      frontendServerProxyDriverResource,
    );
    await buildStep.fetchResource(persistentFrontendServerResource);
    final entrypointArg = sourceArg(entrypointAssetId);
    // Translates an AssetId to its scratch space file path.
    //
    // For example, AssetId('app', 'lib/src/foo.dart') becomes:
    // 'lib/src/foo.dart' if 'app' is the root package
    // 'packages/app/src/bar.dart' if 'app' is a standard package.
    String assetPath(AssetId id) => id.package == root
        ? id.path
        : 'packages/${id.package}/${id.path.replaceFirst('lib/', '')}';

    final changedAssetUris = [
      for (final asset in scratchSpace.changedFilesInBuild)
        if (asset.path.startsWith('lib/'))
          Uri(
            scheme: 'package',
            path: '${asset.package}/${asset.path.replaceFirst('lib/', '')}',
          )
        else
          Uri(scheme: multiRootScheme, host: '', path: '/${assetPath(asset)}'),
    ];
    try {
      frontendServerState.triggerSharedCompilation(entrypointAssetId, () async {
        final customDir = scratchSpaceDir;
        if (customDir != null) {
          scratchSpace = _scratchSpaceCache.putIfAbsent(
            customDir,
            () => ScratchSpace.existing(Directory(customDir)),
          );
        }
        if (customDir != null) {
          frontendServerState.customScratchSpacePath = customDir;
        }
        await scratchSpace.ensureAssets([
          entrypointAssetId,
          ...module.sources,
          ...transitiveSources,
          ...scratchSpace.changedFilesInBuild,
        ], buildStep);
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

      // Reads the compiled asset with [extension] from the Frontend Server's
      // filesystem and writes it to the build runner's output.
      Future<void> readAndWriteOutput(String extension) async {
        final outputId = ddcEntrypointId.changeExtension(extension);
        final path = '$testScratchSpacePathPrefix${assetPath(outputId)}';
        final content = await driver.readInMemoryFile(
          path,
          entrypointArg,
          changedAssetUris,
        );
        if (content != null) {
          await buildStep.writeAsString(outputId, content);
        }
      }

      await Future.wait([
        readAndWriteOutput(jsModuleExtension),
        readAndWriteOutput(jsSourceMapExtension),
        readAndWriteOutput(metadataExtension),
      ]);

      if (isEntrypoint) {
        frontendServerState.needsRecompileRestart = false;
      }
    } catch (e) {
      frontendServerState.needsRecompileRestart = true;
      rethrow;
    }
  }
}
