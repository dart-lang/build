// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';
import 'package:build_modules/build_modules.dart';
import 'package:cli_util/cli_util.dart' as cli_util;

import 'common.dart';
import 'errors.dart';

final sdkDir = cli_util.getSdkPath();

const jsModuleErrorsExtension = '.ddc.js.errors';
const jsModuleExtension = '.ddc.js';
const jsSourceMapExtension = '.ddc.js.map';

/// A builder which can output ddc modules!
class DevCompilerBuilder implements Builder {
  final bool useKernel;

  const DevCompilerBuilder({bool useKernel})
      : this.useKernel = useKernel ?? false;

  @override
  final buildExtensions = const {
    moduleExtension: const [
      jsModuleExtension,
      jsModuleErrorsExtension,
      jsSourceMapExtension
    ]
  };

  @override
  Future build(BuildStep buildStep) async {
    var module = new Module.fromJson(
        JSON.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    try {
      await createDevCompilerModule(module, buildStep, useKernel,
          debugMode: !useKernel);
    } on DartDevcCompilationException catch (e) {
      await buildStep.writeAsString(
          buildStep.inputId.changeExtension(jsModuleErrorsExtension), '$e');
      log.severe('', e);
    }
  }
}

/// Compile [module] with the dev compiler.
Future createDevCompilerModule(
    Module module, BuildStep buildStep, bool useKernel,
    {bool debugMode = true}) async {
  var transitiveDeps = await module.computeTransitiveDependencies(buildStep);
  var transitiveSummaryDeps = transitiveDeps.map(
      (module) => useKernel ? module.kernelSummaryId : module.linkedSummaryId);
  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);

  var allAssetIds = new Set<AssetId>()
    ..addAll(module.sources)
    ..addAll(transitiveSummaryDeps);
  await scratchSpace.ensureAssets(allAssetIds, buildStep);
  var jsId = module.jsId(jsModuleExtension);
  var jsOutputFile = scratchSpace.fileFor(jsId);
  var sdkSummary =
      p.url.join(sdkDir, 'lib/_internal/ddc_sdk.${useKernel ? 'dill' : 'sum'}');
  var request = new WorkRequest();

  request.arguments.addAll([
    '--dart-sdk-summary=$sdkSummary',
    '--modules=amd',
    '-o',
    jsOutputFile.path,
  ]);

  if (!useKernel) {
    // Add the default analysis_options.
    await scratchSpace.ensureAssets([defaultAnalysisOptionsId], buildStep);
    var libraryRoot = '/${p.split(p.dirname(jsId.path)).first}';
    request.arguments.addAll([
      '--module-root=.',
      '--library-root=$libraryRoot',
      '--summary-extension=${linkedSummaryExtension.substring(1)}',
      '--no-summarize',
      defaultAnalysisOptionsArg(scratchSpace),
    ]);
  }

  if (debugMode) {
    request.arguments.addAll([
      '--source-map',
      '--source-map-comment',
      '--inline-source-map',
    ]);
  } else {
    request.arguments.add('--no-source-map');
  }

  // Add all the linked summaries as summary inputs.
  for (var id in transitiveSummaryDeps) {
    var summaryPath = useKernel
        ? p.url.relative(scratchSpace.fileFor(id).path,
            from: scratchSpace.tempDir.path)
        : scratchSpace.fileFor(id).path;
    request.arguments.addAll(['-s', summaryPath]);
  }

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
        var absoluteFileUri = new Uri.file('/${id.path}');
        request.arguments.add('--url-mapping=$absoluteFileUri,${id.path}');
      }
    }
  }

  File packagesFile;
  if (useKernel) {
    var allDeps = <AssetId>[]
      ..addAll(module.sources)
      ..addAll(transitiveSummaryDeps);
    packagesFile = await createPackagesFile(allDeps, scratchSpace);
    request.arguments.addAll([
      "--packages",
      packagesFile.absolute.uri.toString(),
    ]);
  }

  // And finally add all the urls to compile, using the package: path for
  // files under lib and the full absolute path for other files.
  request.arguments.addAll(module.sources.map((id) {
    var uri = canonicalUriFor(id);
    if (uri.startsWith('package:')) {
      return uri;
    }
    return useKernel ? id.path : new Uri.file('/${id.path}').toString();
  }));

  WorkResponse response;
  try {
    var driverResource =
        useKernel ? dartdevkDriverResource : dartdevcDriverResource;
    var driver = await buildStep.fetchResource(driverResource);
    response = await driver.doWork(request);
  } finally {
    if (useKernel) await packagesFile.parent.delete(recursive: true);
  }

  // TODO(jakemac53): Fix the ddc worker mode so it always sends back a bad
  // status code if something failed. Today we just make sure there is an output
  // JS file to verify it was successful.
  if (response.exitCode != EXIT_CODE_OK || !jsOutputFile.existsSync()) {
    var message =
        response.output.replaceAll('${scratchSpace.tempDir.path}/', '');
    throw new DartDevcCompilationException(jsId, '$message}');
  } else {
    // Copy the output back using the buildStep.
    await scratchSpace.copyOutput(jsId, buildStep);
    if (debugMode) {
      await scratchSpace.copyOutput(
          module.jsSourceMapId(jsSourceMapExtension), buildStep);
    }
  }
}
