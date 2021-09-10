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
import 'package:scratch_space/scratch_space.dart';

import '../builders.dart';
import 'common.dart';
import 'errors.dart';

String jsModuleErrorsExtension(bool soundNullSafety) =>
    '${soundnessExt(soundNullSafety)}.ddc.js.errors';
String jsModuleExtension(bool soundNullSafety) =>
    '${soundnessExt(soundNullSafety)}.ddc.js';
String jsSourceMapExtension(bool soundNullSafety) =>
    '${soundnessExt(soundNullSafety)}.ddc.js.map';
String metadataExtension(bool soundNullSafety) =>
    '${soundnessExt(soundNullSafety)}.ddc.js.metadata';
String symbolsExtension(bool soundNullSafety) =>
    '${soundnessExt(soundNullSafety)}.ddc.js.symbols';
String fullKernelExtension(bool soundNullSafety) =>
    '${soundnessExt(soundNullSafety)}.ddc.full.dill';

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

  /// Whether or not strong null safety should be enabled.
  final bool soundNullSafety;

  DevCompilerBuilder(
      {this.useIncrementalCompiler = true,
      this.generateFullDill = false,
      this.emitDebugSymbols = false,
      this.trackUnusedInputs = false,
      required this.platform,
      String? sdkKernelPath,
      String? librariesPath,
      String? platformSdk,
      this.environment = const {},
      this.soundNullSafety = false})
      : platformSdk = platformSdk ?? sdkDir,
        librariesPath = librariesPath ??
            p.join(platformSdk ?? sdkDir, 'lib', 'libraries.json'),
        buildExtensions = {
          moduleExtension(platform): [
            jsModuleExtension(soundNullSafety),
            jsModuleErrorsExtension(soundNullSafety),
            jsSourceMapExtension(soundNullSafety),
            metadataExtension(soundNullSafety),
            symbolsExtension(soundNullSafety),
            fullKernelExtension(soundNullSafety),
          ],
        },
        sdkKernelPath = sdkKernelPath ?? sdkDdcKernelPath(soundNullSafety);

  @override
  final Map<String, List<String>> buildExtensions;

  @override
  Future build(BuildStep buildStep) async {
    var module = Module.fromJson(
        json.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    // Entrypoints always have a `.module` file for ease of looking them up,
    // but they might not be the primary source.
    if (module.primarySource.changeExtension(moduleExtension(platform)) !=
        buildStep.inputId) {
      return;
    }

    Future<void> handleError(e) async {
      await buildStep.writeAsString(
          module.primarySource
              .changeExtension(jsModuleErrorsExtension(soundNullSafety)),
          '$e');
      log.severe('$e');
    }

    try {
      await _createDevCompilerModule(
          module,
          buildStep,
          useIncrementalCompiler,
          generateFullDill,
          emitDebugSymbols,
          trackUnusedInputs,
          platformSdk,
          sdkKernelPath,
          librariesPath,
          environment,
          soundNullSafety);
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
    bool trackUnusedInputs,
    String dartSdk,
    String sdkKernelPath,
    String librariesPath,
    Map<String, String> environment,
    bool soundNullSafety,
    {bool debugMode = true}) async {
  var transitiveDeps = await buildStep.trackStage('CollectTransitiveDeps',
      () => module.computeTransitiveDependencies(buildStep));
  var transitiveKernelDeps = [
    for (var dep in transitiveDeps)
      dep.primarySource.changeExtension(ddcKernelExtension(soundNullSafety)),
  ];
  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);

  var allAssetIds = <AssetId>{...module.sources, ...transitiveKernelDeps};
  await buildStep.trackStage(
      'EnsureAssets', () => scratchSpace.ensureAssets(allAssetIds, buildStep));
  var jsId =
      module.primarySource.changeExtension(jsModuleExtension(soundNullSafety));
  var jsOutputFile = scratchSpace.fileFor(jsId);
  var sdkSummary = p.url.join(dartSdk, sdkKernelPath);

  // Maps the inputs paths we provide to the ddc worker to asset ids, if
  // `trackUnusedInputs` is `true`.
  Map<String, AssetId>? kernelInputPathToId;

  // If `trackUnusedInputs` is `true`, this is the file we will use to
  // communicate the used inputs with the ddc worker.
  File? usedInputsFile;

  if (trackUnusedInputs) {
    usedInputsFile = await File(p.join(
            (await Directory.systemTemp.createTemp('ddk_builder_')).path,
            'used_inputs.txt'))
        .create();
    kernelInputPathToId = {};
  }

  var request = WorkRequest()
    ..arguments.addAll([
      '--dart-sdk-summary=$sdkSummary',
      '--modules=amd',
      '--no-summarize',
      if (generateFullDill) '--experimental-output-compiled-kernel',
      if (emitDebugSymbols) '--emit-debug-symbols',
      '-o',
      jsOutputFile.path,
      debugMode ? '--source-map' : '--no-source-map',
      for (var dep in transitiveDeps) _summaryArg(dep, soundNullSafety),
      '--packages=$multiRootScheme:///.dart_tool/package_config.json',
      '--module-name=${ddcModuleName(jsId, soundNullSafety)}',
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
      for (var source in module.sources) _sourceArg(source),
      for (var define in environment.entries) '-D${define.key}=${define.value}',
      for (var experiment in enabledExperiments)
        '--enable-experiment=$experiment',
      '--${soundNullSafety ? '' : 'no-'}sound-null-safety',
    ])
    ..inputs.add(Input()
      ..path = sdkSummary
      ..digest = [0])
    ..inputs.addAll(await Future.wait(transitiveKernelDeps.map((dep) async {
      var file = scratchSpace.fileFor(dep);
      if (kernelInputPathToId != null) {
        kernelInputPathToId[file.uri.toString()] = dep;
      }
      return Input()
        ..path = file.path
        ..digest = (await buildStep.digest(dep)).bytes;
    })));

  try {
    var driverResource = dartdevkDriverResource;
    var driver = await buildStep.fetchResource(driverResource);
    var response = await driver.doWork(request,
        trackWork: (response) =>
            buildStep.trackStage('Compile', () => response, isExternal: true));

    // TODO(jakemac53): Fix the ddc worker mode so it always sends back a bad
    // status code if something failed. Today we just make sure there is an output
    // JS file to verify it was successful.
    var message = response.output
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
      var currentFullKernelId = module.primarySource
          .changeExtension(fullKernelExtension(soundNullSafety));
      await scratchSpace.copyOutput(currentFullKernelId, buildStep);
    }

    if (debugMode) {
      // We need to modify the sources in the sourcemap to remove the custom
      // `multiRootScheme` that we use.
      var sourceMapId = module.primarySource
          .changeExtension(jsSourceMapExtension(soundNullSafety));
      var file = scratchSpace.fileFor(sourceMapId);
      var content = await file.readAsString();
      var json = jsonDecode(content);
      json['sources'] = fixSourceMapSources((json['sources'] as List).cast());
      await buildStep.writeAsString(sourceMapId, jsonEncode(json));

      // Copy the metadata output, modifying its contents to remove the temp
      // directory from paths
      var metadataId = module.primarySource
          .changeExtension(metadataExtension(soundNullSafety));
      file = scratchSpace.fileFor(metadataId);
      content = await file.readAsString();
      json = jsonDecode(content);
      _fixMetadataSources(
          json as Map<String, dynamic>, scratchSpace.tempDir.uri);
      await buildStep.writeAsString(metadataId, jsonEncode(json));

      // Copy the symbols output, modifying its contents to remove the temp
      // directory from paths
      if (emitDebugSymbols) {
        var symbolsId = module.primarySource
            .changeExtension(symbolsExtension(soundNullSafety));
        await scratchSpace.copyOutput(symbolsId, buildStep);
      }
    }

    // Note that we only want to do this on success, we can't trust the unused
    // inputs if there is a failure.
    if (usedInputsFile != null) {
      await reportUnusedKernelInputs(usedInputsFile, transitiveKernelDeps,
          kernelInputPathToId!, buildStep);
    }
  } finally {
    await usedInputsFile?.parent.delete(recursive: true);
  }
}

/// Returns the `--summary=` argument for a dependency.
String _summaryArg(Module module, bool soundNullSafety) {
  final kernelAsset =
      module.primarySource.changeExtension(ddcKernelExtension(soundNullSafety));
  final moduleName = ddcModuleName(
      module.primarySource.changeExtension(jsModuleExtension(soundNullSafety)),
      soundNullSafety);
  return '--summary=${scratchSpace.fileFor(kernelAsset).path}=$moduleName';
}

/// The url to compile for a source.
///
/// Use the package: path for files under lib and the full absolute path for
/// other files.
String _sourceArg(AssetId id) {
  var uri = canonicalUriFor(id);
  return uri.startsWith('package:') ? uri : '$multiRootScheme:///${id.path}';
}

/// The module name according to ddc for [jsId] which represents the real js
/// module file.
String ddcModuleName(AssetId jsId, bool soundNullSafety) {
  var jsPath = jsId.path.startsWith('lib/')
      ? jsId.path.replaceFirst('lib/', 'packages/${jsId.package}/')
      : jsId.path;
  return jsPath.substring(
      0, jsPath.length - jsModuleExtension(soundNullSafety).length);
}

void _fixMetadataSources(Map<String, dynamic> json, Uri scratchUri) {
  String updatePath(String path) =>
      Uri.parse(path).path.replaceAll(scratchUri.path, '');

  var sourceMapUri = json['sourceMapUri'] as String?;
  if (sourceMapUri != null) {
    json['sourceMapUri'] = updatePath(sourceMapUri);
  }

  var moduleUri = json['moduleUri'] as String?;
  if (moduleUri != null) {
    json['moduleUri'] = updatePath(moduleUri);
  }

  var fullDillUri = json['fullDillUri'] as String?;
  if (fullDillUri != null) {
    json['fullDillUri'] = updatePath(fullDillUri);
  }

  var libraries = json['libraries'] as List<Object?>?;
  if (libraries != null) {
    for (var lib in libraries) {
      var libraryJson = lib as Map<String, Object?>?;
      if (libraryJson != null) {
        var fileUri = libraryJson['fileUri'] as String?;
        if (fileUri != null) {
          libraryJson['fileUri'] = updatePath(fileUri);
        }
      }
    }
  }
}
