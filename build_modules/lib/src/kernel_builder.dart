// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

import 'common.dart';
import 'errors.dart';
import 'module_builder.dart';
import 'modules.dart';
import 'scratch_space.dart';
import 'workers.dart';

const kernelModuleExtension = '.full.dill';
const kernelSummaryExtension = '.sum.dill';
const multiRootScheme = 'org-dartlang-app';

/// A builder which can output kernel summaries.
class KernelSummaryBuilder implements Builder {
  const KernelSummaryBuilder();

  @override
  final buildExtensions = const {
    moduleExtension: const [kernelSummaryExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    var module = new Module.fromJson(
        json.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    try {
      await _createKernel(module, buildStep, summaryOnly: true);
    } on KernelException catch (e, s) {
      log.warning('Error creating ${module.kernelSummaryId}:\n', e, s);
    }
  }
}

/// A builder which can output a full kernel module.
class KernelModuleBuilder implements Builder {
  const KernelModuleBuilder();

  @override
  final buildExtensions = const {
    moduleExtension: const [kernelModuleExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    var module = new Module.fromJson(
        json.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    try {
      await _createKernel(module, buildStep, summaryOnly: false);
    } on KernelException catch (e, s) {
      log.warning('Error creating ${module.kernelModuleId}:\n$e\n$s');
    }
  }
}

/// Creates a kernel file for [module].
Future _createKernel(Module module, BuildStep buildStep,
    {bool isRoot = false, @required bool summaryOnly}) async {
  var transitiveDeps = await module.computeTransitiveDependencies(buildStep);
  var transitiveKernelDeps = <AssetId>[];
  var transitiveSourceDeps = <AssetId>[];

  // Provide kernel summaries where possible (if created in a previous phase),
  // otherwise provide dart sources.
  await Future.wait(transitiveDeps.map((dep) async {
    var kernelId = summaryOnly ? dep.kernelSummaryId : dep.kernelModuleId;
    if (await buildStep.canRead(kernelId)) {
      transitiveKernelDeps.add(kernelId);
    } else {
      transitiveSourceDeps.addAll(dep.sources);
    }
  }));

  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);

  var allAssetIds = new Set<AssetId>()
    ..addAll(module.sources)
    ..addAll(transitiveKernelDeps)
    ..addAll(transitiveSourceDeps);
  await scratchSpace.ensureAssets(allAssetIds, buildStep);
  var outputId = summaryOnly ? module.kernelSummaryId : module.kernelModuleId;
  var outputFile = scratchSpace.fileFor(outputId);
  var request = new WorkRequest();

  var allDeps = <AssetId>[]
    ..addAll(transitiveKernelDeps)
    ..addAll(module.sources);
  var packagesFile = await createPackagesFile(allDeps, scratchSpace);

  // We need to make sure and clean up the temp dir, even if we fail to compile.
  try {
    // var sdkSummary = p.url.join(sdkDir, 'lib', '_internal', 'ddc_sdk.dill');
    var sdkSummary =
        p.url.join(sdkDir, 'lib', '_internal', 'vm_platform_strong.dill');
    request.arguments.addAll([
      '--dart-sdk-summary',
      sdkSummary,
      '--output',
      outputFile.path,
      '--packages-file',
      packagesFile.path,
      '--multi-root-scheme',
      multiRootScheme,
      '--exclude-non-sources',
      summaryOnly ? '--summary-only' : '--no-summary-only',
    ]);

    // Add all summaries as summary inputs.
    request.arguments.addAll(transitiveKernelDeps.map((id) {
      var relativePath = p.url.relative(scratchSpace.fileFor(id).path,
          from: scratchSpace.tempDir.path);
      if (summaryOnly) {
        return '--input-summary=$multiRootScheme:///$relativePath';
      } else {
        return '--input-linked=$multiRootScheme:///$relativePath';
      }
    }));
    request.arguments.addAll(module.sources.map((id) {
      var uri = id.path.startsWith('lib')
          ? canonicalUriFor(id)
          : '$multiRootScheme:///${id.path}';
      return '--source=$uri';
    }));

    var analyzer = await buildStep.fetchResource(frontendDriverResource);
    var response = await analyzer.doWork(request);
    log.warning(response.output);
    if (response.exitCode != EXIT_CODE_OK || !await outputFile.exists()) {
      throw new KernelException(outputId, response.output);
    }

    // Copy the output back using the buildStep.
    await scratchSpace.copyOutput(outputId, buildStep);
  } finally {
    await packagesFile.parent.delete(recursive: true);
  }
}
