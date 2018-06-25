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

const multiRootScheme = 'org-dartlang-app';

/// A builder which can output kernel files for a given sdk.
///
/// This creates kernel files based on [moduleExtension] files, which are what
/// determine the module structure of an application.
class KernelBuilder implements Builder {
  @override
  final Map<String, List<String>> buildExtensions;

  final String outputExtension;

  /// Whether this should create summary kernel files or full kernel files.
  ///
  /// Summary files only contain the "outline" of the module - you can think of
  /// this as everything but the method bodies.
  final bool summaryOnly;

  /// The sdk kernel file for the current platform.
  final String sdkKernelPath;

  KernelBuilder(
      {@required this.summaryOnly,
      @required this.sdkKernelPath,
      @required this.outputExtension})
      : buildExtensions = {
          moduleExtension: [outputExtension]
        };

  @override
  Future build(BuildStep buildStep) async {
    var module = new Module.fromJson(
        json.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    try {
      await _createKernel(
          module: module,
          buildStep: buildStep,
          summaryOnly: summaryOnly,
          outputExtension: outputExtension,
          sdkKernelPath: sdkKernelPath);
    } on KernelException catch (e, s) {
      log.severe(
          'Error creating '
          '${module.primarySource.changeExtension(outputExtension)}',
          e,
          s);
    }
  }
}

/// Creates a kernel file for [module].
Future _createKernel(
    {@required Module module,
    @required BuildStep buildStep,
    @required bool summaryOnly,
    @required String outputExtension,
    @required String sdkKernelPath}) async {
  var transitiveDeps = await module.computeTransitiveDependencies(buildStep);
  var transitiveKernelDeps = <AssetId>[];
  var transitiveSourceDeps = <AssetId>[];

  // Provide kernel dependencies where possible (if created in a previous
  // phase), otherwise provide dart sources.
  await Future.wait(transitiveDeps.map((dep) async {
    var kernelId = dep.primarySource.changeExtension(outputExtension);
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
  var outputId = module.primarySource.changeExtension(outputExtension);
  var outputFile = scratchSpace.fileFor(outputId);
  var request = new WorkRequest();

  var allDeps = <AssetId>[]
    ..addAll(transitiveKernelDeps)
    ..addAll(module.sources);
  var packagesFile = await createPackagesFile(allDeps, scratchSpace);

  // We need to make sure and clean up the temp dir, even if we fail to compile.
  try {
    var sdkSummary = p.url.join(sdkDir, sdkKernelPath);
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
    if (response.exitCode != EXIT_CODE_OK || !await outputFile.exists()) {
      throw new KernelException(outputId, response.output);
    }

    if (response.output?.isEmpty == false) {
      log.info(response.output);
    }

    // Copy the output back using the buildStep.
    await scratchSpace.copyOutput(outputId, buildStep);
  } finally {
    await packagesFile.parent.delete(recursive: true);
  }
}
