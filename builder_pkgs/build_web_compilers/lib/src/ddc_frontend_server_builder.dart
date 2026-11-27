// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import 'build_modules/build_modules.dart';
import 'common.dart';
import 'errors.dart';
import 'platforms.dart';

/// A builder that compiles DDC modules with the Frontend Server.
class DdcFrontendServerBuilder implements Builder {
  final String? librariesPath;
  final String? platformSdk;
  final String? sdkKernelPath;

  DdcFrontendServerBuilder({
    this.librariesPath,
    this.platformSdk,
    this.sdkKernelPath,
  });
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
    if (isEntrypoint) {
      // The entrypoint's module depends on every library of the app.
      frontendServerState.appSources = [
        entrypointAssetId,
        ...module.sources,
        ...transitiveSources,
      ];
    }
    final scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
    // The entrypoint always has to be in the scratch space: any module can
    // trigger a compilation of the main app, including a deferred one.
    //
    // Stage it from here whenever this build step can read it, which also
    // records it as an input so that this step is rerun when it changes. A
    // generated entrypoint in another package can't be read here at all, as
    // it's a hidden output of a build phase that runs after this one; fall
    // back to the copy `WebEntrypointMarkerBuilder` staged in that case.
    //
    // The marker builder is guaranteed to have run first not because of its
    // `runs_before`, which can only order builders within a single package,
    // but because the DDC builders are optional: they are demand driven from
    // the root package's entrypoint builder, which runs after the marker.
    final entrypointIsStaged =
        frontendServerState.stagedEntrypointAssetId == entrypointAssetId;
    final stageEntrypoint =
        !entrypointIsStaged || await buildStep.canRead(entrypointAssetId);
    final root = getRootPackageName();
    final frontendServer = await buildStep.fetchResource(
      persistentFrontendServerResource,
    );
    await frontendServer.ensureStarted(
      librariesPath: librariesPath,
      platformSdk: platformSdk,
      sdkKernelPath: sdkKernelPath,
    );
    final driver = await buildStep.fetchResource(
      frontendServerProxyDriverResource,
    );
    final entrypointArg = sourceArg(entrypointAssetId);
    // Translates an AssetId to its scratch space file path.
    //
    // For example, AssetId('app', 'lib/src/foo.dart') becomes:
    // 'lib/src/foo.dart' if 'app' is the root package
    // 'packages/app/src/bar.dart' if 'app' is a standard package.
    String assetPath(AssetId id) => id.package == root
        ? id.path
        : 'packages/${id.package}/${id.path.replaceFirst('lib/', '')}';
    try {
      final changedAssetUris = <Uri>[];

      // Stages [assets] in the scratch space and records the ones that changed
      // as the URIs the Frontend Server knows them by.
      Future<bool> stage(Iterable<AssetId> assets) async {
        await scratchSpace.ensureAssets(assets, buildStep);
        final changed = [
          for (final asset in scratchSpace.changedFilesInBuild)
            asset.path.startsWith('lib/')
                ? Uri(
                    scheme: 'package',
                    path:
                        '${asset.package}/${asset.path.replaceFirst('lib/', '')}',
                  )
                : Uri(
                    scheme: multiRootScheme,
                    host: '',
                    path: '/${assetPath(asset)}',
                  ),
        ];
        scratchSpace.dispose();
        changedAssetUris.addAll(changed);
        return changed.isNotEmpty;
      }

      // Compiles the app and records whether that failed.
      Future<void> compile() async {
        try {
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
          frontendServerState.lastCompilationFailure = null;
        } on FrontendServerCompilationException catch (e) {
          frontendServerState.lastCompilationFailure = e;
          frontendServerState.needsRecompileRestart = true;
        }
      }

      await frontendServerState.runSharedCompilation(
        entrypointAssetId,
        () async {
          final changed = await stage([
            if (stageEntrypoint) entrypointAssetId,
            ...module.sources,
            ...transitiveSources,
          ]);
          // After a failure, only compile again if there is something new to
          // compile. Otherwise every remaining step of the build would repeat
          // the failing compile.
          if (changed ||
              (frontendServerState.lastCompilationFailure == null &&
                  frontendServerState.needsRecompileRestart)) {
            await compile();
          }
          if (frontendServerState.lastCompilationFailure != null) {
            // Every step compiles the whole app, so the failure can come from a
            // library that isn't a dependency of this module, and it can be out
            // of date: another step may have compiled before the step that
            // owns a changed library staged it. Stage the whole app and compile
            // again if that changed anything.
            //
            // Reading the whole app also makes it an input of this step. A step
            // that fails is then rerun when any library of the app changes, not
            // only when its own dependencies do.
            if (await stage(await _appSources(buildStep, entrypointAssetId))) {
              await compile();
            }
          }
          if (frontendServerState.lastCompilationFailure case final failure?) {
            throw failure;
          }
        },
      );

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

  /// The sources of all modules of the app that this step can read.
  ///
  /// They come from the entrypoint's module. A step in another package can't
  /// read that module, and uses the sources its step recorded instead. There
  /// are none if that step hasn't run in this process yet.
  Future<List<AssetId>> _appSources(
    BuildStep buildStep,
    AssetId entrypointAssetId,
  ) async {
    var sources = frontendServerState.appSources;
    final moduleId = entrypointAssetId.changeExtension(
      moduleExtension(ddcPlatform),
    );
    if (await buildStep.canRead(moduleId)) {
      final module = Module.fromJson(
        json.decode(await buildStep.readAsString(moduleId))
            as Map<String, dynamic>,
      );
      try {
        sources = [
          entrypointAssetId,
          ...module.sources,
          for (final dep in await module.computeTransitiveDependencies(
            buildStep,
          ))
            ...dep.sources,
        ];
      } on MissingModulesException {
        // Fall back to the recorded sources.
      }
    }
    return [
      for (final source in sources)
        if (await buildStep.canRead(source)) source,
    ];
  }
}
