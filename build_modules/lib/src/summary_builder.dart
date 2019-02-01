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
import 'platform.dart';
import 'scratch_space.dart';
import 'workers.dart';

String linkedSummaryExtension(DartPlatform platform) =>
    '.${platform.name}.linked.sum';
String unlinkedSummaryExtension(DartPlatform platform) =>
    '.${platform.name}.unlinked.sum';

/// A builder which can output unlinked summaries!
class UnlinkedSummaryBuilder implements Builder {
  UnlinkedSummaryBuilder(DartPlatform platform)
      : buildExtensions = {
          moduleExtension(platform): [unlinkedSummaryExtension(platform)]
        };

  @override
  final Map<String, List<String>> buildExtensions;

  @override
  Future build(BuildStep buildStep) async {
    var module = Module.fromJson(
        json.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    try {
      await _createUnlinkedSummary(module, buildStep);
    } on AnalyzerSummaryException catch (e) {
      log.severe('Error creating ${module.unlinkedSummaryId}:\n$e');
    }
  }
}

/// A builder which can output linked summaries!
class LinkedSummaryBuilder implements Builder {
  LinkedSummaryBuilder(DartPlatform platform)
      : buildExtensions = {
          moduleExtension(platform): [linkedSummaryExtension(platform)]
        };

  @override
  final Map<String, List<String>> buildExtensions;

  @override
  Future build(BuildStep buildStep) async {
    var module = Module.fromJson(
        json.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    try {
      await _createLinkedSummary(module, buildStep);
    } on AnalyzerSummaryException catch (e, s) {
      log.warning('Error creating ${module.linkedSummaryId}:\n$e\n$s');
    } on MissingModulesException catch (e) {
      log.severe('$e');
    }
  }
}

/// Creates an unlinked summary for [module].
Future _createUnlinkedSummary(Module module, BuildStep buildStep,
    {bool isRoot = false}) async {
  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
  await scratchSpace.ensureAssets(module.sources, buildStep);

  var summaryOutputFile = scratchSpace.fileFor(module.unlinkedSummaryId);
  var request = WorkRequest();
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
  var response = await analyzer.doWork(request,
      trackWork: (response) =>
          buildStep.trackStage('Summarize', () => response, isExternal: true));
  if (response.exitCode == EXIT_CODE_ERROR) {
    throw AnalyzerSummaryException(module.unlinkedSummaryId, response.output);
  }

  // Copy the output back using the buildStep.
  await scratchSpace.copyOutput(module.unlinkedSummaryId, buildStep);
}

/// Creates a linked summary for [module].
Future _createLinkedSummary(Module module, BuildStep buildStep,
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

  var allAssetIds = Set<AssetId>()
    // TODO: Why can't we just add the unlinked summary?
    // That would help invalidation.
    ..addAll(module.sources)
    ..addAll(transitiveLinkedSummaryDeps)
    ..addAll(transitiveUnlinkedSummaryDeps);
  await scratchSpace.ensureAssets(allAssetIds, buildStep);
  var summaryOutputFile = scratchSpace.fileFor(module.linkedSummaryId);
  var request = WorkRequest();
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

  // Add the [Input]s with `Digest`s.
  await Future.wait(allAssetIds.map((input) {
    return buildStep.digest(input).then((digest) {
      request.inputs.add(Input()
        ..digest = digest.bytes
        ..path = scratchSpace.fileFor(input).path);
    });
  }));

  var analyzer = await buildStep.fetchResource(analyzerDriverResource);
  var response = await analyzer.doWork(request);
  var summaryFile = scratchSpace.fileFor(module.linkedSummaryId);
  if (response.exitCode == EXIT_CODE_ERROR || !await summaryFile.exists()) {
    throw AnalyzerSummaryException(module.linkedSummaryId, response.output);
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
      uri = Uri.file('/${id.path}').toString();
    }
    return '$uri|${file.path}';
  });
}
