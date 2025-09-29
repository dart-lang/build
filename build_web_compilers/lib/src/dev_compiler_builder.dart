// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_modules/build_modules.dart';
import 'package:path/path.dart' as p;

import '../builders.dart';
import 'common.dart';
import 'errors.dart';

/// A builder which can output ddc modules!
class DevCompilerBuilder implements Builder {
  final bool useIncrementalCompiler;

  /// Whether to generate full dill file outputs for each module.
  ///
  /// Full dill file is an additional file produced by DDC that stores full
  /// kernel for code compiled for one module, not including dependencies.
  /// Note that outlines are still produced and used by DDC as dependency
  /// summaries, independent of this setting.
  /// Full dill is used by the expression compilation service run by the
  /// debugger to compile expressions in debugging worklows that use modular
  /// build, such as webdev.
  final bool generateFullDill;

  /// Whether to generate debug symbols file outputs for each module.
  ///
  /// Debug symbols file is an additional file produced by DDC that stores
  /// symbols for code compiled for one module, not including dependencies.
  /// Debug symbols are used by the to display variables and objects in
  /// watch, expression evaluation, and variable inspection windows.
  final bool emitDebugSymbols;

  /// Enables canary features in DDC.
  final bool canaryFeatures;

  /// Emits code with the DDC module system.
  final bool ddcModules;

  final bool trackUnusedInputs;

  final DartPlatform platform;

  /// The sdk kernel file for the current platform.
  final String sdkKernelPath;

  /// The root directory of the platform's dart SDK.
  ///
  /// If not provided, defaults to the directory of
  /// [Platform.resolvedExecutable].
  ///
  /// On flutter this is the path to the root of the flutter_patched_sdk
  /// directory, which contains the platform kernel files.
  final String platformSdk;

  /// The absolute path to the libraries file for the current platform.
  ///
  /// If not provided, defaults to "lib/libraries.json" in the sdk directory.
  final String librariesPath;

  /// Environment defines to pass to ddc (as -D variables).
  final Map<String, String> environment;

  DevCompilerBuilder({
    this.useIncrementalCompiler = true,
    this.generateFullDill = false,
    this.emitDebugSymbols = false,
    this.canaryFeatures = false,
    this.ddcModules = false,
    this.trackUnusedInputs = false,
    required this.platform,
    String? sdkKernelPath,
    String? librariesPath,
    String? platformSdk,
    this.environment = const {},
  }) : platformSdk = platformSdk ?? sdkDir,
       librariesPath =
           librariesPath ??
           p.join(platformSdk ?? sdkDir, 'lib', 'libraries.json'),
       buildExtensions = {
         moduleExtension(platform): [
           jsModuleExtension,
           jsModuleErrorsExtension,
           jsSourceMapExtension,
           metadataExtension,
           symbolsExtension,
           fullKernelExtension,
         ],
       },
       sdkKernelPath = sdkKernelPath ?? sdkDdcKernelPath;

  @override
  final Map<String, List<String>> buildExtensions;

  @override
  Future build(BuildStep buildStep) async {
    final module = Module.fromJson(
      json.decode(await buildStep.readAsString(buildStep.inputId))
          as Map<String, dynamic>,
    );
    // Entrypoints always have a `.module` file for ease of looking them up,
    // but they might not be the primary source.
    if (module.primarySource.changeExtension(moduleExtension(platform)) !=
        buildStep.inputId) {
      return;
    }

    Future<void> handleError(Object e) async {
      await buildStep.writeAsString(
        module.primarySource.changeExtension(jsModuleErrorsExtension),
        '$e',
      );
      log.severe('$e');
    }

    try {
      await _createDevCompilerModule(
        module,
        buildStep,
        useIncrementalCompiler,
        generateFullDill,
        emitDebugSymbols,
        canaryFeatures,
        ddcModules,
        trackUnusedInputs,
        platformSdk,
        sdkKernelPath,
        librariesPath,
        environment,
      );
    } on DartDevcCompilationException catch (e) {
      await handleError(e);
    } on MissingModulesException catch (e) {
      await handleError(e);
    }
  }
}

/// Compile [module] with the dev compiler.
Future<void> _createDevCompilerModule(
  Module module,
  BuildStep buildStep,
  bool useIncrementalCompiler,
  bool generateFullDill,
  bool emitDebugSymbols,
  bool canaryFeatures,
  bool ddcModules,
  bool trackUnusedInputs,
  String dartSdk,
  String sdkKernelPath,
  String librariesPath,
  Map<String, String> environment, {
  bool debugMode = true,
}) async {
  final transitiveDeps = await buildStep.trackStage(
    'CollectTransitiveDeps',
    () => module.computeTransitiveDependencies(buildStep),
  );
  final transitiveKernelDeps = [
    for (final dep in transitiveDeps)
      dep.primarySource.changeExtension(ddcKernelExtension),
  ];
  final scratchSpace = await buildStep.fetchResource(scratchSpaceResource);

  final allAssetIds = <AssetId>{...module.sources, ...transitiveKernelDeps};
  await buildStep.trackStage(
    'EnsureAssets',
    () => scratchSpace.ensureAssets(allAssetIds, buildStep),
  );
  final jsId = module.primarySource.changeExtension(jsModuleExtension);
  final jsOutputFile = scratchSpace.fileFor(jsId);
  final sdkSummary = p.url.join(dartSdk, sdkKernelPath);

  // Maps the inputs paths we provide to the ddc worker to asset ids, if
  // `trackUnusedInputs` is `true`.
  Map<String, AssetId>? kernelInputPathToId;

  // If `trackUnusedInputs` is `true`, this is the file we will use to
  // communicate the used inputs with the ddc worker.
  File? usedInputsFile;

  if (trackUnusedInputs) {
    usedInputsFile =
        await File(
          p.join(
            (await Directory.systemTemp.createTemp('ddk_builder_')).path,
            'used_inputs.txt',
          ),
        ).create();
    kernelInputPathToId = {};
  }

  final request =
      WorkRequest()
        ..arguments.addAll([
          '--dart-sdk-summary=$sdkSummary',
          '--modules=${ddcModules ? 'ddc' : 'amd'}',
          '--no-summarize',
          if (generateFullDill) '--experimental-output-compiled-kernel',
          if (emitDebugSymbols) '--emit-debug-symbols',
          if (canaryFeatures) '--canary',
          '-o',
          jsOutputFile.path,
          debugMode ? '--source-map' : '--no-source-map',
          for (final dep in transitiveDeps) _summaryArg(dep),
          '--packages=$multiRootScheme:///.dart_tool/package_config.json',
          '--module-name=${ddcModuleName(jsId)}',
          '--multi-root-scheme=$multiRootScheme',
          '--multi-root=.',
          '--track-widget-creation',
          '--inline-source-map',
          '--libraries-file=${p.toUri(librariesPath)}',
          '--experimental-emit-debug-metadata',
          if (useIncrementalCompiler) ...[
            '--reuse-compiler-result',
            '--use-incremental-compiler',
          ],
          if (usedInputsFile != null)
            '--used-inputs-file=${usedInputsFile.uri.toFilePath()}',
          for (final source in module.sources) sourceArg(source),
          for (final define in environment.entries)
            '-D${define.key}=${define.value}',
          for (final experiment in enabledExperiments)
            '--enable-experiment=$experiment',
        ])
        ..inputs.add(
          Input()
            ..path = sdkSummary
            ..digest = [0],
        )
        ..inputs.addAll(
          await Future.wait(
            transitiveKernelDeps.map((dep) async {
              final file = scratchSpace.fileFor(dep);
              if (kernelInputPathToId != null) {
                kernelInputPathToId[file.uri.toString()] = dep;
              }
              return Input()
                ..path = file.path
                ..digest = (await buildStep.digest(dep)).bytes;
            }),
          ),
        );

  try {
    final driverResource = dartdevkDriverResource;
    final driver = await buildStep.fetchResource(driverResource);
    final response = await driver.doWork(
      request,
      trackWork:
          (response) =>
              buildStep.trackStage('Compile', () => response, isExternal: true),
    );

    // TODO(jakemac53): Fix the ddc worker mode so it always sends back a bad
    // status code if something failed. Today we just make sure there is an
    // output JS file to verify it was successful.
    final message = response.output
        .replaceAll('${scratchSpace.tempDir.path}/', '')
        .replaceAll('$multiRootScheme:///', '');
    if (response.exitCode != EXIT_CODE_OK ||
        !jsOutputFile.existsSync() ||
        message.contains('Error:')) {
      throw DartDevcCompilationException(jsId, message);
    }

    if (message.isNotEmpty) {
      log.info('\n$message');
    }

    // Copy the output back using the buildStep.
    await scratchSpace.copyOutput(jsId, buildStep);

    if (generateFullDill) {
      final currentFullKernelId = module.primarySource.changeExtension(
        fullKernelExtension,
      );
      await scratchSpace.copyOutput(currentFullKernelId, buildStep);
    }

    if (debugMode) {
      await fixAndCopySourceMap(
        module.primarySource.changeExtension(jsSourceMapExtension),
        scratchSpace,
        buildStep,
      );

      // Copy the metadata output, modifying its contents to remove the temp
      // directory from paths
      final metadataId = module.primarySource.changeExtension(
        metadataExtension,
      );
      final file = scratchSpace.fileFor(metadataId);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, Object?>;
      fixMetadataSources(json, scratchSpace.tempDir.uri);
      await buildStep.writeAsString(metadataId, jsonEncode(json));

      // Copy the symbols output, modifying its contents to remove the temp
      // directory from paths
      if (emitDebugSymbols) {
        final symbolsId = module.primarySource.changeExtension(
          symbolsExtension,
        );
        await scratchSpace.copyOutput(symbolsId, buildStep);
      }
    }

    // Note that we only want to do this on success, we can't trust the unused
    // inputs if there is a failure.
    if (usedInputsFile != null) {
      await reportUnusedKernelInputs(
        usedInputsFile,
        transitiveKernelDeps,
        kernelInputPathToId!,
        buildStep,
      );
    }
  } finally {
    await usedInputsFile?.parent.delete(recursive: true);
  }
}

/// Returns the `--summary=` argument for a dependency.
String _summaryArg(Module module) {
  final kernelAsset = module.primarySource.changeExtension(ddcKernelExtension);
  final moduleName = ddcModuleName(
    module.primarySource.changeExtension(jsModuleExtension),
  );
  return '--summary=${scratchSpace.fileFor(kernelAsset).path}=$moduleName';
}
