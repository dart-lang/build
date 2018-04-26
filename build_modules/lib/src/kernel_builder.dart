// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

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

const kernelSummaryExtension = '.dill';
const multiRootScheme = 'org-dartlang-app';

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
        json.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    try {
      await _createKernelSummary(module, buildStep);
    } on KernelSummaryException catch (e, s) {
      log.warning('Error creating ${module.unlinkedSummaryId}:\n$e\n$s');
    }
  }
}

/// Creates a kernel summary file for [module].
Future _createKernelSummary(Module module, BuildStep buildStep,
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

  var allDeps = <AssetId>[]
    ..addAll(transitiveSummaryDeps)
    ..addAll(module.sources);
  var packagesFile = await createPackagesFile(allDeps, scratchSpace);

  // We need to make sure and clean up the temp dir, even if we fail to compile.
  try {
    var sdkSummary = p.url.join(sdkDir, 'lib', '_internal', 'ddc_sdk.dill');
    request.arguments.addAll([
      '--dart-sdk-summary',
      sdkSummary,
      '--output',
      summaryOutputFile.path,
      '--packages-file',
      packagesFile.path,
      '--multi-root-scheme',
      multiRootScheme,
      '--exclude-non-sources',
    ]);

    // Add all summaries as summary inputs.
    request.arguments.addAll(transitiveSummaryDeps.map((id) {
      var relativePath = p.url.relative(scratchSpace.fileFor(id).path,
          from: scratchSpace.tempDir.path);
      return '--input-summary=$multiRootScheme:///$relativePath';
    }));
    request.arguments.addAll(module.sources.map((id) {
      var uri = id.path.startsWith('lib')
          ? canonicalUriFor(id)
          : '$multiRootScheme:///${id.path}';
      return '--source=$uri';
    }));

    var analyzer = await buildStep.fetchResource(frontendDriverResource);
    var response = await analyzer.doWork(request);
    var summaryFile = scratchSpace.fileFor(module.kernelSummaryId);
    if (response.exitCode == EXIT_CODE_ERROR || !await summaryFile.exists()) {
      throw new KernelSummaryException(module.kernelSummaryId, response.output);
    }

    // Copy the output back using the buildStep.
    await scratchSpace.copyOutput(module.kernelSummaryId, buildStep);
  } finally {
    await packagesFile.parent.delete(recursive: true);
  }
}
