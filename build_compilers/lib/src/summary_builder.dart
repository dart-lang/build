// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:scratch_space/scratch_space.dart';

import 'common.dart';
import 'errors.dart';
import 'module_builder.dart';
import 'modules.dart';
import 'scratch_space.dart';
import 'workers.dart';

const linkedSummaryExtension = '.linked.sum';
const unlinkedSummaryExtension = '.unlinked.sum';

/// A builder which can output unlinked summaries!
class UnlinkedSummaryBuilder implements Builder {
  const UnlinkedSummaryBuilder();

  @override
  final buildExtensions = const {
    moduleExtension: const [unlinkedSummaryExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    var module = new Module.fromJson(
        JSON.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    try {
      await createUnlinkedSummary(module, buildStep);
    } on AnalyzerSummaryException catch (e, s) {
      log.warning('Error creating ${module.unlinkedSummaryId}:\n$e\n$s');
    }
  }
}

/// A builder which can output linked summaries!
class LinkedSummaryBuilder implements Builder {
  const LinkedSummaryBuilder();

  @override
  final buildExtensions = const {
    moduleExtension: const [linkedSummaryExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    var module = new Module.fromJson(
        JSON.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    try {
      await createLinkedSummary(module, buildStep);
    } on AnalyzerSummaryException catch (e, s) {
      log.warning('Error creating ${module.linkedSummaryId}:\n$e\n$s');
    }
  }
}

/// Creates an unlinked summary for [module].
Future createUnlinkedSummary(Module module, BuildStep buildStep,
    {bool isRoot = false}) async {
  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
  await scratchSpace.ensureAssets(module.sources, buildStep);

  var summaryOutputFile = scratchSpace.fileFor(module.unlinkedSummaryId);
  var request = new WorkRequest();
  request.arguments.addAll([
    '--build-summary-only',
    '--build-summary-only-unlinked',
    '--build-summary-output-semantic=${summaryOutputFile.path}',
    '--strong',
  ]);

  // Add the default analysis_options.
  await scratchSpace.ensureAssets([defaultAnalysisOptionsId], buildStep);
  request.arguments.add(defaultAnalysisOptionsArg(scratchSpace));

  // Add all the files to include in the unlinked summary bundle.
  request.arguments.addAll(_analyzerSourceArgsForModule(module, scratchSpace));
  var analyzer = await buildStep.fetchResource(analyzerDriverResource);
  var response = await analyzer.doWork(request);
  if (response.exitCode == EXIT_CODE_ERROR) {
    throw new AnalyzerSummaryException(
        module.unlinkedSummaryId, response.output);
  }

  // Copy the output back using the buildStep.
  await scratchSpace.copyOutput(module.unlinkedSummaryId, buildStep);
}

/// Creates a linked summary for [module].
Future createLinkedSummary(Module module, BuildStep buildStep,
    {bool isRoot = false}) async {
  var transitiveDeps = await module.computeTransitiveDependencies(buildStep);
  var transitiveUnlinkedSummaryDeps = <AssetId>[];
  var transitiveLinkedSummaryDeps = <AssetId>[];

  // Provide linked summaries where possible (if created in a previous phase),
  // otherwise provide unlinked summaries.
  await Future.wait(transitiveDeps.map((module) async {
    if (await buildStep.canRead(module.linkedSummaryId)) {
      transitiveLinkedSummaryDeps.add(module.linkedSummaryId);
    } else {
      transitiveUnlinkedSummaryDeps.add(module.unlinkedSummaryId);
    }
  }));

  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);

  var allAssetIds = new Set<AssetId>()
    // TODO: Why can't we just add the unlinked summary?
    // That would help invalidation.
    ..addAll(module.sources)
    ..addAll(transitiveLinkedSummaryDeps)
    ..addAll(transitiveUnlinkedSummaryDeps);
  await scratchSpace.ensureAssets(allAssetIds, buildStep);
  var summaryOutputFile = scratchSpace.fileFor(module.linkedSummaryId);
  var request = new WorkRequest();
  request.arguments.addAll([
    '--build-summary-only',
    '--build-summary-output-semantic=${summaryOutputFile.path}',
    '--strong',
  ]);

  // Add the default analysis_options.
  await scratchSpace.ensureAssets([defaultAnalysisOptionsId], buildStep);
  request.arguments.add(defaultAnalysisOptionsArg(scratchSpace));

  // Add all the unlinked and linked summaries as build summary inputs.
  request.arguments.addAll(transitiveUnlinkedSummaryDeps.map((id) =>
      '--build-summary-unlinked-input=${scratchSpace.fileFor(id).path}'));
  request.arguments.addAll(transitiveLinkedSummaryDeps
      .map((id) => '--build-summary-input=${scratchSpace.fileFor(id).path}'));

  // Add all the files to include in the linked summary bundle.
  request.arguments.addAll(_analyzerSourceArgsForModule(module, scratchSpace));
  var analyzer = await buildStep.fetchResource(analyzerDriverResource);
  var response = await analyzer.doWork(request);
  var summaryFile = scratchSpace.fileFor(module.linkedSummaryId);
  if (response.exitCode == EXIT_CODE_ERROR || !await summaryFile.exists()) {
    throw new AnalyzerSummaryException(module.linkedSummaryId, response.output);
  }

  // Copy the output back using the buildStep.
  await scratchSpace.copyOutput(module.linkedSummaryId, buildStep);
}

Iterable<String> _analyzerSourceArgsForModule(
    Module module, ScratchSpace scratchSpace) {
  return module.sources.map((id) {
    var uri = canonicalUriFor(id);
    var file = scratchSpace.fileFor(id);
    if (!uri.startsWith('package:')) {
      uri = new Uri.file('/${id.path}').toString();
    }
    return '$uri|${file.path}';
  });
}
