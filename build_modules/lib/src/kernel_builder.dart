// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:crypto/crypto.dart';
import 'package:graphs/graphs.dart' show crawlAsync;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

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

  final bool trackUnusedInputs;

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

  /// Experiments to pass to kernel (as --enable-experiment=<experiment> args).
  final Iterable<String> experiments;

  KernelBuilder(
      {@required this.platform,
      @required this.summaryOnly,
      @required this.sdkKernelPath,
      @required this.outputExtension,
      String librariesPath,
      bool useIncrementalCompiler,
      bool trackUnusedInputs,
      String platformSdk,
      String kernelTargetName,
      Iterable<String> experiments})
      : platformSdk = platformSdk ?? sdkDir,
        kernelTargetName = kernelTargetName ?? platform.name,
        librariesPath = librariesPath ??
            p.join(platformSdk ?? sdkDir, 'lib', 'libraries.json'),
        useIncrementalCompiler = useIncrementalCompiler ?? false,
        trackUnusedInputs = trackUnusedInputs ?? false,
        buildExtensions = {
          moduleExtension(platform): [outputExtension]
        },
        experiments = experiments ?? [];

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
          useIncrementalCompiler: useIncrementalCompiler,
          trackUnusedInputs: trackUnusedInputs,
          experiments: experiments);
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
    @required bool useIncrementalCompiler,
    @required bool trackUnusedInputs,
    @required Iterable<String> experiments}) async {
  var request = WorkRequest();
  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
  var outputId = module.primarySource.changeExtension(outputExtension);
  var outputFile = scratchSpace.fileFor(outputId);
  var kernelDeps = <AssetId>[];

  // Maps the inputs paths we provide to the kernel worker to asset ids,
  // if `trackUnusedInputs` is `true`.
  Map<String, AssetId> kernelInputPathToId;
  // If `trackUnusedInputs` is `true`, this is the file we will use to
  // communicate the used inputs with the kernel worker.
  File usedInputsFile;

  await buildStep.trackStage('CollectDeps', () async {
    var sourceDeps = <AssetId>[];

    await _findModuleDeps(
        module, kernelDeps, sourceDeps, buildStep, outputExtension);

    var allAssetIds = <AssetId>{
      ...module.sources,
      ...kernelDeps,
      ...sourceDeps,
    };
    await scratchSpace.ensureAssets(allAssetIds, buildStep);

    if (trackUnusedInputs) {
      usedInputsFile = await File(p.join(
              (await Directory.systemTemp.createTemp('kernel_builder_')).path,
              'used_inputs.txt'))
          .create();
      kernelInputPathToId = {};
    }

    await _addRequestArguments(
        request,
        module,
        kernelDeps,
        targetName,
        dartSdkDir,
        sdkKernelPath,
        librariesPath,
        outputFile,
        summaryOnly,
        useIncrementalCompiler,
        buildStep,
        experiments,
        usedInputsFile: usedInputsFile,
        kernelInputPathToId: kernelInputPathToId);
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

    // Note that we only want to do this on success, we can't trust the unused
    // inputs if there is a failure.
    if (usedInputsFile != null) {
      await reportUnusedKernelInputs(
          usedInputsFile, kernelDeps, kernelInputPathToId, buildStep);
    }
  } finally {
    await usedInputsFile?.parent?.delete(recursive: true);
  }
}

/// Reports any unused kernel inputs based on the [usedInputsFile] we get
/// back from the kernel/ddk workers.
///
/// This file logs paths as they were given in the original [WorkRequest],
/// so [inputPathToId] is used to map those paths back to the kernel asset ids.
///
/// This function will not report any unused dependencies if:
///
/// - It isn't able to match all reported used dependencies to an asset id (it
///   would be unsafe to do so in that case).
/// - No used dependencies are reported (it is assumed something went wrong
///   or there were zero deps to begin with).
Future<void> reportUnusedKernelInputs(
    File usedInputsFile,
    Iterable<AssetId> transitiveKernelDeps,
    Map<String, AssetId> inputPathToId,
    BuildStep buildStep) async {
  var usedPaths = await usedInputsFile.readAsLines();
  if (usedPaths.isEmpty || usedPaths.first == '') return;

  String firstMissingInputPath;
  var usedIds = usedPaths.map((usedPath) {
    var id = inputPathToId[usedPath];
    if (id == null) firstMissingInputPath ??= usedPath;
    return id;
  }).toSet();

  if (firstMissingInputPath != null) {
    log.warning('Error reporting unused kernel deps, unable to map path: '
        '`$firstMissingInputPath` back to an asset id.\n\nPlease file an issue '
        'at https://github.com/dart-lang/build/issues/new.');
    return;
  }

  buildStep.reportUnusedAssets(
      transitiveKernelDeps.where((id) => !usedIds.contains(id)));
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
  var missing = <AssetId>{};
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
  final sourceOnly = <AssetId>{};
  final parents = <AssetId, Set<AssetId>>{};
  for (final module in modules) {
    for (final dep in module.directDependencies) {
      parents.putIfAbsent(dep, () => <AssetId>{}).add(module.primarySource);
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
  bool summaryOnly,
  bool useIncrementalCompiler,
  AssetReader reader,
  Iterable<String> experiments, {
  File usedInputsFile,
  Map<String, AssetId> kernelInputPathToId,
}) async {
  // Add all kernel outlines as summary inputs, with digests.
  var inputs = await Future.wait(transitiveKernelDeps.map((id) async {
    var relativePath = p.url.relative(scratchSpace.fileFor(id).uri.path,
        from: scratchSpace.tempDir.uri.path);
    var path = '$multiRootScheme:///$relativePath';
    if (kernelInputPathToId != null) {
      kernelInputPathToId[path] = id;
    }
    return Input()
      ..path = path
      ..digest = (await reader.digest(id)).bytes;
  }));
  request.arguments.addAll([
    '--dart-sdk-summary=${Uri.file(p.join(sdkDir, sdkKernelPath))}',
    '--output=${outputFile.path}',
    '--packages-file=$multiRootScheme:///${p.join('.dart_tool', 'package_config.json')}',
    '--multi-root-scheme=$multiRootScheme',
    '--exclude-non-sources',
    summaryOnly ? '--summary-only' : '--no-summary-only',
    '--target=$targetName',
    '--libraries-file=${p.toUri(librariesPath)}',
    if (useIncrementalCompiler) ...[
      '--reuse-compiler-result',
      '--use-incremental-compiler',
    ],
    if (usedInputsFile != null)
      '--used-inputs=${usedInputsFile.uri.toFilePath()}',
    for (var input in inputs)
      '--input-${summaryOnly ? 'summary' : 'linked'}=${input.path}',
    for (var experiment in experiments) '--enable-experiment=$experiment',
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
