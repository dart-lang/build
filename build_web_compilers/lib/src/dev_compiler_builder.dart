// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

import '../builders.dart';
import 'common.dart';
import 'errors.dart';

const jsModuleErrorsExtension = '.ddc.js.errors';
const jsModuleExtension = '.ddc.js';
const jsSourceMapExtension = '.ddc.js.map';

/// A builder which can output ddc modules!
class DevCompilerBuilder implements Builder {
  final bool useIncrementalCompiler;

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

  /// Experiments to pass to ddc (as --enable-experiment=<experiment> args).
  final Iterable<String> experiments;

  DevCompilerBuilder(
      {bool useIncrementalCompiler,
      bool trackUnusedInputs,
      @required this.platform,
      this.sdkKernelPath,
      String librariesPath,
      String platformSdk,
      Map<String, String> environment,
      Iterable<String> experiments})
      : useIncrementalCompiler = useIncrementalCompiler ?? true,
        platformSdk = platformSdk ?? sdkDir,
        librariesPath = librariesPath ??
            p.join(platformSdk ?? sdkDir, 'lib', 'libraries.json'),
        trackUnusedInputs = trackUnusedInputs ?? false,
        buildExtensions = {
          moduleExtension(platform): [
            jsModuleExtension,
            jsModuleErrorsExtension,
            jsSourceMapExtension
          ],
        },
        environment = environment ?? {},
        experiments = experiments ?? {};

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
          module.primarySource.changeExtension(jsModuleErrorsExtension), '$e');
      log.severe('$e');
    }

    try {
      await _createDevCompilerModule(
          module,
          buildStep,
          useIncrementalCompiler,
          trackUnusedInputs,
          platformSdk,
          sdkKernelPath,
          librariesPath,
          environment,
          experiments);
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
    bool trackUnusedInputs,
    String dartSdk,
    String sdkKernelPath,
    String librariesPath,
    Map<String, String> environment,
    Iterable<String> experiments,
    {bool debugMode = true}) async {
  var transitiveDeps = await buildStep.trackStage('CollectTransitiveDeps',
      () => module.computeTransitiveDependencies(buildStep));
  var transitiveKernelDeps = [
    for (var dep in transitiveDeps)
      dep.primarySource.changeExtension(ddcKernelExtension)
  ];
  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);

  var allAssetIds = <AssetId>{...module.sources, ...transitiveKernelDeps};
  await buildStep.trackStage(
      'EnsureAssets', () => scratchSpace.ensureAssets(allAssetIds, buildStep));
  var jsId = module.primarySource.changeExtension(jsModuleExtension);
  var jsOutputFile = scratchSpace.fileFor(jsId);
  var sdkSummary =
      p.url.join(dartSdk, sdkKernelPath ?? 'lib/_internal/ddc_sdk.dill');

  // Maps the inputs paths we provide to the ddc worker to asset ids, if
  // `trackUnusedInputs` is `true`.
  Map<String, AssetId> kernelInputPathToId;
  // If `trackUnusedInputs` is `true`, this is the file we will use to
  // communicate the used inputs with the ddc worker.
  File usedInputsFile;

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
      '-o',
      jsOutputFile.path,
      debugMode ? '--source-map' : '--no-source-map',
      for (var dep in transitiveDeps) _summaryArg(dep),
      '--packages=${p.join('.dart_tool', 'package_config.json')}',
      '--module-name=${ddcModuleName(jsId)}',
      '--multi-root-scheme=$multiRootScheme',
      '--multi-root=.',
      '--track-widget-creation',
      '--inline-source-map',
      '--libraries-file=${p.toUri(librariesPath)}',
      if (useIncrementalCompiler) ...[
        '--reuse-compiler-result',
        '--use-incremental-compiler',
      ],
      if (usedInputsFile != null)
        '--used-inputs-file=${usedInputsFile.uri.toFilePath()}',
      for (var source in module.sources) _sourceArg(source),
      for (var define in environment.entries) '-D${define.key}=${define.value}',
      for (var experiment in experiments) '--enable-experiment=$experiment',
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
    if (debugMode) {
      // We need to modify the sources in the sourcemap to remove the custom
      // `multiRootScheme` that we use.
      var sourceMapId =
          module.primarySource.changeExtension(jsSourceMapExtension);
      var file = scratchSpace.fileFor(sourceMapId);
      var content = await file.readAsString();
      var json = jsonDecode(content);
      json['sources'] = fixSourceMapSources((json['sources'] as List).cast());
      await buildStep.writeAsString(sourceMapId, jsonEncode(json));
    }

    // Note that we only want to do this on success, we can't trust the unused
    // inputs if there is a failure.
    if (usedInputsFile != null) {
      await reportUnusedKernelInputs(
          usedInputsFile, transitiveKernelDeps, kernelInputPathToId, buildStep);
    }
  } finally {
    await usedInputsFile?.parent?.delete(recursive: true);
  }
}

/// Returns the `--summary=` argument for a dependency.
String _summaryArg(Module module) {
  final kernelAsset = module.primarySource.changeExtension(ddcKernelExtension);
  final moduleName =
      ddcModuleName(module.primarySource.changeExtension(jsModuleExtension));
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

/// Copied to `web/stack_trace_mapper.dart`, these need to be kept in sync.
///
/// Given a list of [uris] as [String]s from a sourcemap, fixes them up so that
/// they make sense in a browser context.
///
/// - Strips the scheme from the uri
/// - Strips the top level directory if its not `packages`
List<String> fixSourceMapSources(List<String> uris) {
  return uris.map((source) {
    var uri = Uri.parse(source);
    // We only want to rewrite multi-root scheme uris.
    if (uri.scheme.isEmpty) return source;
    var newSegments = uri.pathSegments.first == 'packages'
        ? uri.pathSegments
        : uri.pathSegments.skip(1);
    return Uri(path: p.url.joinAll(['/'].followedBy(newSegments))).toString();
  }).toList();
}

/// The module name according to ddc for [jsId] which represents the real js
/// module file.
String ddcModuleName(AssetId jsId) {
  var jsPath = jsId.path.startsWith('lib/')
      ? jsId.path.replaceFirst('lib/', 'packages/${jsId.package}/')
      : jsId.path;
  return jsPath.substring(0, jsPath.length - jsModuleExtension.length);
}
