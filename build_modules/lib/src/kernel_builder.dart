// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:graphs/graphs.dart' show crawlAsync;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

import 'common.dart';
import 'errors.dart';
import 'module_builder.dart';
import 'module_cache.dart';
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

  final bool useIncrementalCompiler;

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

  /// The absolute path to the libraries file for the current platform.
  ///
  /// If not provided, defaults to "lib/libraries.json" in the sdk directory.
  final String librariesPath;

  /// The `--target` argument passed to the kernel worker.
  ///
  /// Optional. When omitted the [platform] name is used.
  final String kernelTargetName;

  KernelBuilder(
      {@required this.platform,
      @required this.summaryOnly,
      @required this.sdkKernelPath,
      @required this.outputExtension,
      String librariesPath,
      bool useIncrementalCompiler,
      String platformSdk,
      String kernelTargetName})
      : platformSdk = platformSdk ?? sdkDir,
        kernelTargetName = kernelTargetName ?? platform.name,
        librariesPath = librariesPath ??
            p.join(platformSdk ?? sdkDir, 'lib', 'libraries.json'),
        useIncrementalCompiler = useIncrementalCompiler ?? false,
        buildExtensions = {
          moduleExtension(platform): [outputExtension]
        };

  @override
  Future build(BuildStep buildStep) async {
    var module = Module.fromJson(
        json.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    // Entrypoints always have a `.module` file for ease of looking them up,
    // but they might not be the primary source.
    if (module.primarySource.changeExtension(moduleExtension(platform)) !=
        buildStep.inputId) {
      return;
    }

    try {
      await _createKernel(
          module: module,
          buildStep: buildStep,
          summaryOnly: summaryOnly,
          outputExtension: outputExtension,
          targetName: kernelTargetName,
          dartSdkDir: platformSdk,
          sdkKernelPath: sdkKernelPath,
          librariesPath: librariesPath,
          useIncrementalCompiler: useIncrementalCompiler);
    } on MissingModulesException catch (e) {
      log.severe(e.toString());
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
    @required String targetName,
    @required String dartSdkDir,
    @required String sdkKernelPath,
    @required String librariesPath,
    @required bool useIncrementalCompiler}) async {
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

    var allAssetIds = <AssetId>{
      ...module.sources,
      ...kernelDeps,
      ...sourceDeps,
    };
    await scratchSpace.ensureAssets(allAssetIds, buildStep);

    packagesFile = await createPackagesFile(allAssetIds);

    await _addRequestArguments(
        request,
        module,
        kernelDeps,
        targetName,
        dartSdkDir,
        sdkKernelPath,
        librariesPath,
        outputFile,
        packagesFile,
        summaryOnly,
        useIncrementalCompiler,
        buildStep);
  });

  // We need to make sure and clean up the temp dir, even if we fail to compile.
  try {
    var frontendWorker = await buildStep.fetchResource(frontendDriverResource);
    var response = await frontendWorker.doWork(request,
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
    await scratchSpace.copyOutput(outputId, buildStep, requireContent: true);
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

/// The transitive dependencies of [root], not including [root] itself.
Future<List<Module>> _resolveTransitiveModules(
    Module root, BuildStep buildStep) async {
  var missing = Set<AssetId>();
  var modules = await crawlAsync<AssetId, Module>(
          [root.primarySource],
          (id) => buildStep.fetchResource(moduleCache).then((c) async {
                var moduleId =
                    id.changeExtension(moduleExtension(root.platform));
                var module = await c.find(moduleId, buildStep);
                if (module == null) {
                  missing.add(moduleId);
                } else if (module.isMissing) {
                  missing.add(module.primarySource);
                }
                return module;
              }),
          (id, module) => module.directDependencies)
      .skip(1) // Skip the root.
      .toList();

  if (missing.isNotEmpty) {
    throw await MissingModulesException.create(
        missing, [...modules, root], buildStep);
  }

  return modules;
}

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
Future<void> _addRequestArguments(
    WorkRequest request,
    Module module,
    Iterable<AssetId> transitiveKernelDeps,
    String targetName,
    String sdkDir,
    String sdkKernelPath,
    String librariesPath,
    File outputFile,
    File packagesFile,
    bool summaryOnly,
    bool useIncrementalCompiler,
    AssetReader reader) async {
  // Add all kernel outlines as summary inputs, with digests.
  var inputs = await Future.wait(transitiveKernelDeps.map((id) async {
    var relativePath = p.url.relative(scratchSpace.fileFor(id).uri.path,
        from: scratchSpace.tempDir.uri.path);

    return Input()
      ..path = '$multiRootScheme:///$relativePath'
      ..digest = (await reader.digest(id)).bytes;
  }));
  request.arguments.addAll([
    '--dart-sdk-summary=${Uri.file(p.join(sdkDir, sdkKernelPath))}',
    '--output=${outputFile.path}',
    '--packages-file=${packagesFile.uri}',
    '--multi-root-scheme=$multiRootScheme',
    '--exclude-non-sources',
    summaryOnly ? '--summary-only' : '--no-summary-only',
    '--target=$targetName',
    '--libraries-file=${p.toUri(librariesPath)}',
    if (useIncrementalCompiler) ...[
      '--reuse-compiler-result',
      '--use-incremental-compiler',
    ],
    for (var input in inputs)
      '--input-${summaryOnly ? 'summary' : 'linked'}=${input.path}',
    for (var source in module.sources) _sourceArg(source),
  ]);

  request.inputs.addAll([
    ...inputs,
    Input()
      ..path = '${Uri.file(p.join(sdkDir, sdkKernelPath))}'
      // Sdk updates fully invalidate the build anyways.
      ..digest = md5.convert(utf8.encode(targetName)).bytes,
  ]);
}

String _sourceArg(AssetId id) {
  var uri = id.path.startsWith('lib')
      ? canonicalUriFor(id)
      : '$multiRootScheme:///${id.path}';
  return '--source=$uri';
}
