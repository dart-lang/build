// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

import '../builders.dart';
import 'common.dart';
import 'errors.dart';

final _sdkDir = p.dirname(p.dirname(Platform.resolvedExecutable));

const jsModuleErrorsExtension = '.ddc.js.errors';
const jsModuleExtension = '.ddc.js';
const jsSourceMapExtension = '.ddc.js.map';

/// A builder which can output ddc modules!
class DevCompilerBuilder implements Builder {
  final bool useKernel;

  DevCompilerBuilder({bool useKernel}) : useKernel = useKernel ?? false;

  @override
  final buildExtensions = {
    moduleExtension(DartPlatform.dartdevc): [
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

    Future<Null> handleError(e) async {
      await buildStep.writeAsString(
          module.primarySource.changeExtension(jsModuleErrorsExtension), '$e');
      log.severe('$e');
    }

    try {
      await _createDevCompilerModule(module, buildStep, useKernel);
    } on DartDevcCompilationException catch (e) {
      await handleError(e);
    } on MissingModulesException catch (e) {
      await handleError(e);
    }
  }
}

/// Compile [module] with the dev compiler.
Future _createDevCompilerModule(
    Module module, BuildStep buildStep, bool useKernel,
    {bool debugMode = true}) async {
  var transitiveDeps = await buildStep.trackStage('CollectTransitiveDeps',
      () => module.computeTransitiveDependencies(buildStep));
  var transitiveSummaryDeps = transitiveDeps.map((module) => useKernel
      ? module.primarySource.changeExtension(ddcKernelExtension)
      : module.linkedSummaryId);
  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);

  var allAssetIds = Set<AssetId>()
    ..addAll(module.sources)
    ..addAll(transitiveSummaryDeps);
  await buildStep.trackStage(
      'EnsureAssets', () => scratchSpace.ensureAssets(allAssetIds, buildStep));
  var jsId = module.jsId(jsModuleExtension);
  var jsOutputFile = scratchSpace.fileFor(jsId);
  var sdkSummary = p.url
      .join(_sdkDir, 'lib/_internal/ddc_sdk.${useKernel ? 'dill' : 'sum'}');
  var request = WorkRequest();

  request.arguments.addAll([
    '--dart-sdk-summary=$sdkSummary',
    '--modules=amd',
    '--no-summarize',
    '-o',
    jsOutputFile.path,
  ]);
  request.inputs.add(Input()
    ..path = sdkSummary
    ..digest = [0]);

  if (!useKernel) {
    // Add the default analysis_options.
    await scratchSpace.ensureAssets([defaultAnalysisOptionsId], buildStep);
    var libraryRoot = '/${p.split(p.dirname(jsId.path)).first}';
    var summaryExtension =
        linkedSummaryExtension(DartPlatform.dartdevc).substring(1);
    request.arguments.addAll([
      '--module-root=.',
      '--library-root=$libraryRoot',
      '--summary-extension=$summaryExtension',
      defaultAnalysisOptionsArg(scratchSpace),
    ]);
  }

  if (debugMode) {
    request.arguments.addAll([
      '--source-map',
    ]);
    if (!useKernel) {
      request.arguments.addAll([
        '--source-map-comment',
        '--inline-source-map',
      ]);
    }
  } else {
    request.arguments.add('--no-source-map');
  }

  // Add linked summaries as summary inputs.
  //
  // Also request the digests for each and add those to the inputs.
  //
  // This runs synchronously and the digest futures will be awaited later on.
  var digestFutures = <Future>[];
  for (var depModule in transitiveDeps) {
    var summaryId = useKernel
        ? depModule.primarySource.changeExtension(ddcKernelExtension)
        : depModule.linkedSummaryId;
    var summaryPath =
        /*useKernel
        ? p.url.relative(scratchSpace.fileFor(summaryId).path,
            from: scratchSpace.tempDir.path)
        :*/
        scratchSpace.fileFor(summaryId).path;

    if (useKernel) {
      var input = Input()..path = summaryPath;
      request.inputs.add(input);
      digestFutures.add(buildStep.digest(summaryId).then((digest) {
        input.digest = digest.bytes;
      }));
      summaryPath += '=${ddcModuleName(depModule.jsId(jsModuleExtension))}';
    }

    request.arguments.addAll(['-s', summaryPath]);
  }

  // Wait for all the digests to complete.
  await Future.wait(digestFutures);

  // Add URL mappings for all the package: files to tell DartDevc where to
  // find them.
  //
  // For non-lib files we use "fake" absolute file uris, using `id.path`.
  if (!useKernel) {
    for (var id in module.sources) {
      var uri = canonicalUriFor(id);
      if (uri.startsWith('package:')) {
        request.arguments
            .add('--url-mapping=$uri,${scratchSpace.fileFor(id).path}');
      } else {
        var absoluteFileUri = Uri.file('/${id.path}');
        request.arguments.add('--url-mapping=$absoluteFileUri,${id.path}');
      }
    }
  }

  File packagesFile;
  if (useKernel) {
    var allDeps = <AssetId>[]
      ..addAll(module.sources)
      ..addAll(transitiveSummaryDeps);
    packagesFile = await createPackagesFile(allDeps);
    request.arguments.addAll([
      '--packages',
      packagesFile.absolute.uri.toString(),
      '--module-name',
      ddcModuleName(module.jsId(jsModuleExtension)),
      '--multi-root-scheme',
      multiRootScheme,
      '--multi-root',
      '.',
    ]);
  }

  // And finally add all the urls to compile, using the package: path for
  // files under lib and the full absolute path for other files.
  request.arguments.addAll(module.sources.map((id) {
    var uri = canonicalUriFor(id);
    if (uri.startsWith('package:')) {
      return uri;
    }
    return useKernel
        ? '$multiRootScheme:///${id.path}'
        : Uri.file('/${id.path}').toString();
  }));

  WorkResponse response;
  try {
    var driverResource =
        useKernel ? dartdevkDriverResource : dartdevcDriverResource;
    var driver = await buildStep.fetchResource(driverResource);
    response = await buildStep
        .trackStage('Compile', () => driver.doWork(request), isExternal: true);
  } finally {
    if (useKernel) await packagesFile.parent.delete(recursive: true);
  }

  // TODO(jakemac53): Fix the ddc worker mode so it always sends back a bad
  // status code if something failed. Today we just make sure there is an output
  // JS file to verify it was successful.
  var message = response.output.replaceAll('${scratchSpace.tempDir.path}/', '');
  if (response.exitCode != EXIT_CODE_OK || !jsOutputFile.existsSync()) {
    throw DartDevcCompilationException(jsId, '$message}');
  } else {
    if (message.isNotEmpty) {
      log.info(message);
    }
    // Copy the output back using the buildStep.
    await scratchSpace.copyOutput(jsId, buildStep);
    if (debugMode) {
      await scratchSpace.copyOutput(
          module.jsSourceMapId(jsSourceMapExtension), buildStep);
    }
  }
}

/// The module name according to ddc for [jsId] which represents the real js
/// module file.
String ddcModuleName(AssetId jsId) {
  var jsPath = jsId.path.startsWith('lib/')
      ? jsId.path.replaceFirst('lib/', 'packages/${jsId.package}/')
      : jsId.path;
  return jsPath.substring(0, jsPath.length - jsModuleExtension.length);
}
