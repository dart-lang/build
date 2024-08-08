// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_modules/build_modules.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

import 'common.dart';
import 'platforms.dart';
import 'web_entrypoint_builder.dart';

final _resourcePool = Pool(maxWorkersPerTask);

/// Invokes `dart compile wasm` to compile the primary input of [buildStep].
///
/// Additionally, generates a `.js` entrypoint file invoking the entrypoint.
Future<void> bootstrapDart2Wasm(
    BuildStep buildStep, List<String> additionalArguments) async {
  await _resourcePool
      .withResource(() => _bootstrapDart2Wasm(buildStep, additionalArguments));
}

Future<void> _bootstrapDart2Wasm(
    BuildStep buildStep, List<String> additionalArguments) async {
  var dartEntrypointId = buildStep.inputId;
  var moduleId =
      dartEntrypointId.changeExtension(moduleExtension(dart2wasmPlatform));
  var args = <String>[];
  {
    var module = Module.fromJson(
        json.decode(await buildStep.readAsString(moduleId))
            as Map<String, dynamic>);
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
Skipping compiling ${buildStep.inputId} with dart2wasm because some of its
transitive libraries have sdk dependencies that are not supported on this platform:

$librariesString

https://github.com/dart-lang/build/blob/master/docs/faq.md#how-can-i-resolve-skipped-compiling-warnings
''');
      return;
    }

    var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
    var allSrcs = allDeps.expand((module) => module.sources);
    await scratchSpace.ensureAssets(allSrcs, buildStep);

    var dartUri = dartEntrypointId.path.startsWith('lib/')
        ? Uri.parse('package:${dartEntrypointId.package}/'
            '${dartEntrypointId.path.substring('lib/'.length)}')
        : Uri.parse('$multiRootScheme:///${dartEntrypointId.path}');
    var wasmOutputPath = p.withoutExtension(dartUri.scheme == 'package'
            ? 'packages/${dartUri.path}'
            : dartUri.path.substring(1)) +
        wasmExtension;

    args = [
      '--packages=$multiRootScheme:///.dart_tool/package_config.json',
      // The -E prefix is removed by dartdev when starting the actual dart2wasm
      // process.
      '-E--multi-root-scheme=$multiRootScheme',
      '-E--multi-root=${scratchSpace.tempDir.uri.toFilePath()}',
      for (var experiment in enabledExperiments)
        '--enable-experiment=$experiment',
      ...additionalArguments,
      '-o',
      wasmOutputPath,
      '$dartUri',
    ];
  }

  log.info('Running `dart compile wasm` with ${args.join(' ')}\n');
  var result = await Process.run(
      p.join(sdkDir, 'bin', 'dart'),
      [
        'compile',
        'wasm',
        ...args,
      ],
      workingDirectory: scratchSpace.tempDir.path);

  var wasmOutputId = dartEntrypointId.changeExtension(wasmExtension);
  var wasmOutputFile = scratchSpace.fileFor(wasmOutputId);
  if (result.exitCode == 0 && await wasmOutputFile.exists()) {
    log.info('${result.stdout}\n${result.stderr}');

    for (final extension in [wasmExtension, moduleJsExtension]) {
      await scratchSpace.copyOutput(
          dartEntrypointId.changeExtension(extension), buildStep);
    }

    final entrypoint = _entrypointRunner(buildStep.inputId);
    await buildStep.writeAsString(entrypoint.$1, entrypoint.$2);
  } else {
    log.severe('ExitCode:${result.exitCode}\nStdOut:\n${result.stdout}\n'
        'StdErr:\n${result.stderr}');
  }
}

(AssetId, String) _entrypointRunner(AssetId wasmSource) {
  final id = wasmSource.changeExtension('.dart.js');
  final basename = p.url.basenameWithoutExtension(wasmSource.path);

  return (
    id,
    '''
(async () => {
  let { instantiate, invoke } = await import("./$basename.mjs");

  let modulePromise = WebAssembly.compileStreaming(fetch("$basename.wasm"));
  let instantiated = await instantiate(modulePromise, {});
  invoke(instantiated, []);
})();
'''
  );
}
