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

import 'errors.dart';
import 'module_builder.dart';
import 'modules.dart';
import 'scratch_space.dart';
import 'workers.dart';

const kernelSummaryExtension = '.sum.dill';

/// A builder which can output unlinked summaries!
class KernelSummaryBuilder implements Builder {
  const KernelSummaryBuilder();

  @override
  final buildExtensions = const {
    moduleExtension: const [kernelSummaryExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    var module = new Module.fromJson(
        JSON.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    try {
      await createKernelSummary(module, buildStep);
    } on KernelSummaryException catch (e, s) {
      log.warning('Error creating ${module.unlinkedSummaryId}:\n$e\n$s');
    }
  }
}

/// Creates a kernel summary file for [module].
Future createKernelSummary(Module module, BuildStep buildStep,
    {bool isRoot = false}) async {
  var transitiveDeps = await module.computeTransitiveDependencies(buildStep);
  var transitiveSummaryDeps = <AssetId>[];
  var transitiveSourceDeps = <AssetId>[];

  // Provide kernel summaries where possible (if created in a previous phase),
  // otherwise provide dart sources.
  await Future.wait(transitiveDeps.map((module) async {
    if (await buildStep.canRead(module.kernelSummaryId)) {
      transitiveSummaryDeps.add(module.kernelSummaryId);
    } else {
      transitiveSourceDeps.addAll(module.sources);
    }
  }));

  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);

  var allAssetIds = new Set<AssetId>()
    ..addAll(module.sources)
    ..addAll(transitiveSummaryDeps)
    ..addAll(transitiveSourceDeps);
  await scratchSpace.ensureAssets(allAssetIds, buildStep);
  var summaryOutputFile = scratchSpace.fileFor(module.kernelSummaryId);
  var request = new WorkRequest();

  var allPackages =
      new Set<String>.from(transitiveSummaryDeps.map((id) => id.package))
        ..addAll(module.sources.map((id) => id.package));

  // TODO: better solution for a .packages file, today we just create a new one
  // for every kernel build action.
  var packagesFileDir =
      await Directory.systemTemp.createTemp('kernel_builder_');
  var packagesFile = new File(p.join(packagesFileDir.path, '.packages'));

  // We need to make sure and clean up the temp dir, even if we fail to compile.
  try {
    await packagesFile.create();
    await packagesFile.writeAsString(allPackages
        .map((pkg) =>
            '$pkg:file://${p.join(scratchSpace.tempDir.path, 'packages', pkg)}')
        .join('\r\n'));

    var sdkSummary = p.url.join(sdkDir, 'lib', '_internal', 'ddc_sdk.dill');
    request.arguments.addAll([
      "--dart-sdk-summary",
      sdkSummary,
      "--output",
      summaryOutputFile.path,
      "--packages-file",
      packagesFile.path,
    ]);

    // Add all summaries as summary inputs.
    request.arguments.addAll(transitiveSummaryDeps
        .map((id) => '--input-summary=${scratchSpace.fileFor(id).uri}'));
    request.arguments
        .addAll(module.sources.map((id) => '--source=${canonicalUriFor(id)}'));

    var analyzer = await buildStep.fetchResource(frontendDriverResource);
    var response = await analyzer.doWork(request);
    var summaryFile = scratchSpace.fileFor(module.kernelSummaryId);
    if (response.exitCode == EXIT_CODE_ERROR || !await summaryFile.exists()) {
      throw new KernelSummaryException(module.kernelSummaryId, response.output);
    }

    // Copy the output back using the buildStep.
    await scratchSpace.copyOutput(module.kernelSummaryId, buildStep);
  } finally {
    await packagesFileDir.delete(recursive: true);
  }
}
