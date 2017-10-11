// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

import 'errors.dart';
import 'module_builder.dart';
import 'modules.dart';
import 'scratch_space.dart';
import 'summary_builder.dart';
import 'workers.dart';

final String jsModuleErrorsExtension = '.errors';
final String jsModuleExtension = '.js';
final String jsSourceMapExtension = '.js.map';

/// A builder which can output ddc modules!
class DevCompilerBuilder implements Builder {
  @override
  final buildExtensions = {
    moduleExtension: [
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
      await createDevCompilerModule(module, buildStep);
    } on DartDevcCompilationException catch (e, s) {
      log.warning('Error compiling ${module.jsId}:\n$e\n$s');
      await buildStep.writeAsString(
          buildStep.inputId.changeExtension(jsModuleErrorsExtension),
          e.message);
    }
  }
}

/// Compile [module] with the dev compiler.
Future createDevCompilerModule(Module module, BuildStep buildStep,
    {bool isRoot = false, bool debugMode = false}) async {
  var transitiveDeps = await module.computeTransitiveDependencies(buildStep);
  var transitiveSummaryDeps =
      transitiveDeps.map((id) => id.changeExtension(linkedSummaryExtension));
  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);

  var allAssetIds = new Set<AssetId>()
    ..addAll(module.sources)
    ..addAll(transitiveSummaryDeps);
  await scratchSpace.ensureAssets(allAssetIds, buildStep);
  var jsOutputFile = scratchSpace.fileFor(module.jsId);
  var sdkSummary = p.url.join(sdkDir, 'lib/_internal/ddc_sdk.sum');
  var request = new WorkRequest();

  request.arguments.addAll([
    '--dart-sdk-summary=$sdkSummary',
    '--modules=amd',
    '--dart-sdk=${sdkDir}',
    '--module-root=${scratchSpace.tempDir.path}',
    '--library-root=${p.dirname(jsOutputFile.path)}',
    '--summary-extension=${linkedSummaryExtension.substring(1)}',
    '--no-summarize',
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

  // Add all the linked summaries as summary inputs.
  for (var id in transitiveSummaryDeps) {
    request.arguments.addAll(['-s', scratchSpace.fileFor(id).path]);
  }

  // Add URL mappings for all the package: files to tell DartDevc where to
  // find them.
  for (var id in module.sources) {
    var uri = canonicalUriFor(id);
    if (uri.startsWith('package:')) {
      request.arguments
          .add('--url-mapping=$uri,${scratchSpace.fileFor(id).path}');
    }
  }

  // And finally add all the urls to compile, using the package: path for
  // files under lib and the full absolute path for other files.
  request.arguments.addAll(module.sources.map((id) {
    var uri = canonicalUriFor(id);
    if (uri.startsWith('package:')) {
      return uri;
    }
    return scratchSpace.fileFor(id).path;
  }));

  var response = await dartdevcDriver.doWork(request);
  // TODO(jakemac53): Fix the ddc worker mode so it always sends back a bad
  // status code if something failed. Today we just make sure there is an output
  // JS file to verify it was successful.
  if (response.exitCode != EXIT_CODE_OK || !jsOutputFile.existsSync()) {
    throw new DartDevcCompilationException(module.jsId, response.output);
  } else {
    // Copy the output back using the buildStep.
    await scratchSpace.copyOutput(module.jsId, buildStep);
    if (debugMode) {
      await scratchSpace.copyOutput(module.jsSourceMapId, buildStep);
    }
  }
}
