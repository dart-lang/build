// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

import '../builders.dart';
import 'common.dart';
import 'errors.dart';
import 'platforms.dart';

const jsModuleErrorsExtension = '.ddc.js.errors';
const jsModuleExtension = '.ddc.js';
const jsSourceMapExtension = '.ddc.js.map';

/// A builder which can output ddc modules!
class DevCompilerBuilder implements Builder {
  final bool useIncrementalCompiler;

  DevCompilerBuilder({bool useIncrementalCompiler})
      : useIncrementalCompiler = useIncrementalCompiler ?? true;

  @override
  final buildExtensions = {
    moduleExtension(ddcPlatform): [
      jsModuleExtension,
      jsModuleErrorsExtension,
      jsSourceMapExtension
    ]
  };

  @override
  Future build(BuildStep buildStep) async {
    var module = Module.fromJson(
        json.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);

    Future<void> handleError(e) async {
      await buildStep.writeAsString(
          module.primarySource.changeExtension(jsModuleErrorsExtension), '$e');
      log.severe('$e');
    }

    try {
      await _createDevCompilerModule(module, buildStep, useIncrementalCompiler);
    } on DartDevcCompilationException catch (e) {
      await handleError(e);
    } on MissingModulesException catch (e) {
      await handleError(e);
    }
  }
}

/// Compile [module] with the dev compiler.
Future<void> _createDevCompilerModule(
    Module module, BuildStep buildStep, bool useIncrementalCompiler,
    {bool debugMode = true}) async {
  var transitiveDeps = await buildStep.trackStage('CollectTransitiveDeps',
      () => module.computeTransitiveDependencies(buildStep));
  var transitiveKernelDeps = transitiveDeps.map(
      (module) => module.primarySource.changeExtension(ddcKernelExtension));
  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);

  var allAssetIds = Set<AssetId>()
    ..addAll(module.sources)
    ..addAll(transitiveKernelDeps);
  await buildStep.trackStage(
      'EnsureAssets', () => scratchSpace.ensureAssets(allAssetIds, buildStep));
  var jsId = module.primarySource.changeExtension(jsModuleExtension);
  var jsOutputFile = scratchSpace.fileFor(jsId);
  var sdkSummary = p.url.join(sdkDir, 'lib/_internal/ddc_sdk.dill');

  var request = WorkRequest()
    ..arguments.addAll([
      '--dart-sdk-summary=$sdkSummary',
      '--modules=amd',
      '--no-summarize',
      '-o',
      jsOutputFile.path,
      debugMode ? '--source-map' : '--no-source-map',
    ])
    ..inputs.add(Input()
      ..path = sdkSummary
      ..digest = [0])
    ..inputs.addAll(await Future.wait(transitiveDeps.map((dep) async {
      final kernelAsset = dep.primarySource.changeExtension(ddcKernelExtension);
      return Input()
        ..path = scratchSpace.fileFor(kernelAsset).path
        ..digest = (await buildStep.digest(kernelAsset)).bytes;
    })))
    ..arguments.addAll(transitiveDeps.expand((dep) {
      final kernelAsset = dep.primarySource.changeExtension(ddcKernelExtension);
      var moduleName =
          ddcModuleName(dep.primarySource.changeExtension(jsModuleExtension));
      return ['-s', '${scratchSpace.fileFor(kernelAsset).path}=$moduleName'];
    }));

  var allDeps = <AssetId>[]
    ..addAll(module.sources)
    ..addAll(transitiveKernelDeps);
  var packagesFile = await createPackagesFile(allDeps);
  request.arguments.addAll([
    '--packages',
    packagesFile.absolute.uri.toString(),
    '--module-name',
    ddcModuleName(module.primarySource.changeExtension(jsModuleExtension)),
    '--multi-root-scheme',
    multiRootScheme,
    '--multi-root',
    '.',
    '--track-widget-creation',
    '--inline-source-map',
  ]);

  if (useIncrementalCompiler) {
    request.arguments.addAll([
      '--reuse-compiler-result',
      '--use-incremental-compiler',
    ]);
  }

  // And finally add all the urls to compile, using the package: path for
  // files under lib and the full absolute path for other files.
  request.arguments.addAll(module.sources.map((id) {
    var uri = canonicalUriFor(id);
    if (uri.startsWith('package:')) {
      return uri;
    }
    return '$multiRootScheme:///${id.path}';
  }));

  WorkResponse response;
  try {
    var driverResource = dartdevkDriverResource;
    var driver = await buildStep.fetchResource(driverResource);
    response = await driver.doWork(request,
        trackWork: (response) =>
            buildStep.trackStage('Compile', () => response, isExternal: true));
  } finally {
    await packagesFile.parent.delete(recursive: true);
  }

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
  } else {
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
  }
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
