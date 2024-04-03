// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
// ignore: implementation_imports
import 'package:macros/src/bootstrap.dart';
// ignore: implementation_imports
import 'package:macros/src/executor/serialization.dart';

import '../build_modules.dart';
import 'module_cache.dart';
import 'module_library.dart';

class MacroBootstrapBuilder extends Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    var modules = await buildStep.fetchResource(moduleCache);
    var module = (await modules.find(buildStep.inputId, buildStep))!;

    // Entrypoints always have a `.module` file for ease of looking them up,
    // but they might not be the primary source.
    if (module.primarySource.changeExtension(moduleExtension(macroPlatform)) !=
        buildStep.inputId) {
      return;
    }

    // Only continue if we have some macros to build.
    if (!module.containsMacros) return;

    // Collect all transitive module deps
    List<Module> allDeps;
    try {
      allDeps = (await module.computeTransitiveDependencies(buildStep,
          throwIfUnsupported: true))
        ..add(module);
    } on UnsupportedModules catch (e) {
      var librariesString = (await e.exactLibraries(buildStep).toList())
          .map((lib) => AssetId(lib.id.package,
              lib.id.path.replaceFirst(moduleLibraryExtension, '.dart')))
          .join('\n');
      log.warning('''
Skipping compiling macros in ${module.primarySource} because some of it's
transitive libraries have sdk dependencies that are not supported for
macros:

$librariesString

https://github.com/dart-lang/build/blob/master/docs/faq.md#how-can-i-resolve-skipped-compiling-warnings
''');
      return;
    }

    // The bootstrap file has additional deps, add those too
    for (var bootstrapImport in [
      AssetId('_macros', 'lib/src/executor/client.dart'),
      AssetId('_macros', 'lib/src/executor/serialization.dart')
    ]) {
      var bootstrapModule = (await modules.find(
          bootstrapImport.changeExtension(moduleExtension(macroPlatform)),
          buildStep))!;
      allDeps
        ..addAll(await bootstrapModule.computeTransitiveDependencies(buildStep,
            throwIfUnsupported: true))
        ..add(bootstrapModule);
    }

    // Ensure all sources are available in the shared scratch space
    var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
    await scratchSpace.ensureAssets(
        allDeps.expand((module) => module.sources), buildStep);

    // Entrypoints always have a `.module` file for ease of looking them up,
    // but they might not be the primary source.
    if (module.primarySource.changeExtension(moduleExtension(macroPlatform)) !=
        buildStep.inputId) {
      return;
    }

    // Generate the bootstrap file, and add that to the scratch space as well.
    //
    // We could make this a separate builder and produce a real artifact, but
    // don't need to.
    var libraries = [
      for (var source in module.sources)
        ModuleLibrary.deserialize(
            source,
            await buildStep
                .readAsString(source.changeExtension(moduleLibraryExtension))),
    ];
    var bootstrapContent = bootstrapMacroIsolate({
      for (var library in libraries)
        if (library.macroConstructors.isNotEmpty)
          library.id.uri.toString(): library.macroConstructors,
    }, SerializationMode.byteData);
    var bootstrapId =
        module.primarySource.changeExtension('.macro.bootstrap.dart');
    var bootstrapFile = scratchSpace.fileFor(bootstrapId);
    await bootstrapFile.create(recursive: true);
    await bootstrapFile.writeAsString(bootstrapContent);

    // TODO: Support macros outside of `lib/`.
    if (bootstrapId.uri.scheme != 'package') {
      throw UnsupportedError(
          'Only macros under lib/ dirs are currently supported by '
          'build_runner');
    }

    // Compile the app, copy back the result.
    var outputId = module.primarySource.changeExtension(macroBinaryExtension);
    var result = await Process.run(
        Platform.resolvedExecutable,
        [
          'compile',
          'exe',
          bootstrapFile.path,
          '-o',
          scratchSpace.fileFor(outputId).path,
          for (var experiment in enabledExperiments)
            '--enable-experiment=$experiment',
          '--packages',
          '${scratchSpace.tempDir.path}/.dart_tool/package_config.json',
        ],
        workingDirectory: scratchSpace.tempDir.path);
    if (result.exitCode != 0 ||
        !(await scratchSpace.fileFor(outputId).exists())) {
      log.severe('''
Failed to generate macro program for ${module.primarySource}:

exitCode: ${result.exitCode}
stdout:
${result.stdout}
stderr:
${result.stderr}''');
    } else {
      await scratchSpace.copyOutput(outputId, buildStep);
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        moduleExtension(macroPlatform): [macroBinaryExtension]
      };
}

const macroBinaryExtension = '.macro.exe';

final macroPlatform = DartPlatform.register('macro', const [
  '_internal',
  'async',
  'collection',
  'convert',
  'core',
  'math',
  'typed_data',
  // TODO: These are required for the bootstrap script, but technically we
  // are not supposed to allow them for macros.
  'io',
  'isolate',
]);
