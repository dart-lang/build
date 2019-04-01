// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';
import 'package:graphs/graphs.dart' show crawlAsync;

import 'common.dart';
import 'errors.dart';
import 'module_builder.dart';
import 'modules.dart';
import 'platform.dart';
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

  final DartPlatform platform;

  /// Whether this should create summary kernel files or full kernel files.
  ///
  /// Summary files only contain the "outline" of the module - you can think of
  /// this as everything but the method bodies.
  final bool summaryOnly;

  /// The sdk kernel file for the current platform.
  final String sdkKernelPath;

  /// The root directory of the platform's dart SDK.
  ///
  /// If not provided, defaults to the directory of
  /// [Platform.resolvedExecutable].
  ///
  /// On flutter this is the path to the root of the flutter_patched_sdk
  /// directory, which contains the platform kernel files.
  final String platformSdk;

  KernelBuilder(
      {@required this.platform,
      @required this.summaryOnly,
      @required this.sdkKernelPath,
      @required this.outputExtension,
      String platformSdk})
      : platformSdk = platformSdk ?? sdkDir,
        buildExtensions = {
          moduleExtension(platform): [outputExtension]
        };

  @override
  Future build(BuildStep buildStep) async {
    var module = Module.fromJson(
        json.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    try {
      await _createKernel(
          module: module,
          buildStep: buildStep,
          summaryOnly: summaryOnly,
          outputExtension: outputExtension,
          dartSdkDir: platformSdk,
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
Future<void> _createKernel(
    {@required Module module,
    @required BuildStep buildStep,
    @required bool summaryOnly,
    @required String outputExtension,
    @required String dartSdkDir,
    @required String sdkKernelPath}) async {
  var request = WorkRequest();
  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
  var outputId = module.primarySource.changeExtension(outputExtension);
  var outputFile = scratchSpace.fileFor(outputId);

  File packagesFile;

  await buildStep.trackStage('CollectDeps', () async {
    var kernelDeps = <AssetId>[];
    var sourceDeps = <AssetId>[];

    await _findModuleDeps(
        module, kernelDeps, sourceDeps, buildStep, outputExtension);

    var allAssetIds = Set<AssetId>()
      ..addAll(module.sources)
      ..addAll(kernelDeps)
      ..addAll(sourceDeps);
    await scratchSpace.ensureAssets(allAssetIds, buildStep);

    packagesFile = await createPackagesFile(allAssetIds);

    _addRequestArguments(request, module, kernelDeps, dartSdkDir, sdkKernelPath,
        outputFile, packagesFile, summaryOnly);
  });

  // We need to make sure and clean up the temp dir, even if we fail to compile.
  try {
    var analyzer = await buildStep.fetchResource(frontendDriverResource);
    var response = await analyzer.doWork(request,
        trackWork: (response) => buildStep
            .trackStage('Kernel Generate', () => response, isExternal: true));
    if (response.exitCode != EXIT_CODE_OK || !await outputFile.exists()) {
      throw KernelException(
          outputId, '${request.arguments.join(' ')}\n${response.output}');
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

/// Finds the transitive dependencies of [root] and categorizes them as
/// [kernelDeps] or [sourceDeps].
///
/// A module will have it's kernel file in [kernelDeps] if it and all of it's
/// transitive dependencies have readable kernel files. If any module has no
/// readable kernel file then it, and all of it's dependents will be categorized
/// as [sourceDeps] which will have all of their [Module.sources].
Future<void> _findModuleDeps(
    Module root,
    List<AssetId> kernelDeps,
    List<AssetId> sourceDeps,
    BuildStep buildStep,
    String outputExtension) async {
  final resolvedModules = await _resolveTransitiveModules(root, buildStep);

  final sourceOnly = await _parentsOfMissingKernelFiles(
      resolvedModules, buildStep, outputExtension);

  for (final module in resolvedModules) {
    if (sourceOnly.contains(module.primarySource)) {
      sourceDeps.addAll(module.sources);
    } else {
      kernelDeps.add(module.primarySource.changeExtension(outputExtension));
    }
  }
}

Future<List<Module>> _resolveTransitiveModules(
        Module root, BuildStep buildStep) =>
    crawlAsync<AssetId, Module>(
        [root.primarySource],
        (id) async => Module.fromJson(jsonDecode(await buildStep.readAsString(
                id.changeExtension(moduleExtension(root.platform))))
            as Map<String, dynamic>),
        (id, module) => module.directDependencies).toList();

/// Finds the primary source of all transitive parents of any module which does
/// not have a readable kernel file.
///
/// Inverts the direction of the graph and then crawls to all reachables nodes
/// from the modules which do not have a readable kernel file
Future<Set<AssetId>> _parentsOfMissingKernelFiles(
    List<Module> modules, BuildStep buildStep, String outputExtension) async {
  final sourceOnly = Set<AssetId>();
  final parents = <AssetId, Set<AssetId>>{};
  for (final module in modules) {
    for (final dep in module.directDependencies) {
      parents.putIfAbsent(dep, () => Set<AssetId>()).add(module.primarySource);
    }
    if (!await buildStep
        .canRead(module.primarySource.changeExtension(outputExtension))) {
      sourceOnly.add(module.primarySource);
    }
  }
  final toCrawl = Queue.of(sourceOnly);
  while (toCrawl.isNotEmpty) {
    final current = toCrawl.removeFirst();
    if (!parents.containsKey(current)) continue;
    for (final next in parents[current]) {
      if (!sourceOnly.add(next)) {
        toCrawl.add(next);
      }
    }
  }
  return sourceOnly;
}

/// Fills in all the required arguments for [request] in order to compile the
/// kernel file for [module].
void _addRequestArguments(
    WorkRequest request,
    Module module,
    Iterable<AssetId> transitiveKernelDeps,
    String sdkDir,
    String sdkKernelPath,
    File outputFile,
    File packagesFile,
    bool summaryOnly) {
  request.arguments.addAll([
    '--dart-sdk-summary',
    Uri.file(p.join(sdkDir, sdkKernelPath)).toString(),
    '--output',
    outputFile.path,
    '--packages-file',
    packagesFile.uri.toString(),
    '--multi-root-scheme',
    multiRootScheme,
    '--exclude-non-sources',
    summaryOnly ? '--summary-only' : '--no-summary-only',
  ]);

  // Add all summaries as summary inputs.
  request.arguments.addAll(transitiveKernelDeps.map((id) {
    var relativePath = p.url.relative(scratchSpace.fileFor(id).uri.path,
        from: scratchSpace.tempDir.uri.path);
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
}
