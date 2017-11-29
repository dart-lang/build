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

import 'common.dart';
import 'errors.dart';
import 'module_builder.dart';
import 'modules.dart';
import 'scratch_space.dart';
import 'workers.dart';

const jsModuleErrorsExtension = '.js.errors';
const jsModuleExtension = '.js';
const jsSourceMapExtension = '.js.map';

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
  var jsOutputFile = scratchSpace.fileFor(module.jsId);
  // var libraryRoot = '/${p.split(p.dirname(module.jsId.path)).first}';
  var sdkSummary =
      p.url.join(sdkDir, 'lib/_internal/ddc_sdk.${useKernel ? 'dill' : 'sum'}');
  var request = new WorkRequest();

  request.arguments.addAll([
    '--dart-sdk-summary=$sdkSummary',
    '--modules=amd',
    // '--module-root=.',
    // '--library-root=$libraryRoot',
    // '--summary-extension=${(useKernel ? kernelSummaryExtension : linkedSummaryExtension).substring(1)}',
    // '--no-summarize',
    '-o',
    jsOutputFile.path,
  ]);

  if (debugMode) {
    request.arguments.addAll([
      '--source-map',
      '--source-map-comment',
      '--inline-source-map',
    ]);
  } else {
    request.arguments.add('--no-source-map');
  }

  // Add the default analysis_options.
  await scratchSpace.ensureAssets([defaultAnalysisOptionsId], buildStep);
  if (!useKernel) {
    request.arguments.add(defaultAnalysisOptionsArg(scratchSpace));
  }

  // Add all the linked summaries as summary inputs.
  for (var id in transitiveSummaryDeps) {
    request.arguments.addAll(['-s', scratchSpace.fileFor(id).path]);
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
      ..addAll(transitiveSummaryDeps)
      ..addAll(module.sources);
    packagesFile = await createPackagesFile(allDeps, scratchSpace);
    request.arguments.addAll([
      "--packages",
      packagesFile.path,
    ]);
  }

  // And finally add all the urls to compile, using the package: path for
  // files under lib and the full absolute path for other files.
  request.arguments.addAll(module.sources.map((id) {
    var uri = canonicalUriFor(id);
    if (uri.startsWith('package:')) {
      return uri;
    }
    if (useKernel) {
      return id.path;
    } else {
      return new Uri.file('/${id.path}').toString();
    }
  }));

  WorkResponse response;
  if (useKernel) {
    // Make sure to clean up the .packages file.
    try {
      var result = await Process.run(
          p.join(sdkDir, 'bin', 'dartdevk${Platform.isWindows ? '.bat' : ''}'),
          request.arguments,
          workingDirectory: scratchSpace.tempDir.path);
      response = new WorkResponse()
        ..exitCode = result.exitCode
        ..output = result.stdout as String;
    } finally {
      await packagesFile.parent.delete(recursive: true);
    }
  } else {
    var dartdevc = await buildStep.fetchResource(dartdevcDriverResource);
    response = await dartdevc.doWork(request);
  }

  // TODO(jakemac53): Fix the ddc worker mode so it always sends back a bad
  // status code if something failed. Today we just make sure there is an output
  // JS file to verify it was successful.
  if (response.exitCode != EXIT_CODE_OK || !jsOutputFile.existsSync()) {
    var message =
        response.output.replaceAll('${scratchSpace.tempDir.path}/', '');
    throw new DartDevcCompilationException(module.jsId, '$message\n$request}');
  } else {
    // Copy the output back using the buildStep.
    await scratchSpace.copyOutput(module.jsId, buildStep);
    if (debugMode) {
      await scratchSpace.copyOutput(module.jsSourceMapId, buildStep);
    }
  }
}
