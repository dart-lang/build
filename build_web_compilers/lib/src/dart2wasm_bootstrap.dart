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

/// Result of invoking the `dart2wasm` compiler.
final class Dart2WasmBootstrapResult {
  /// Whether `dart2wasm` did compile the Dart program.
  ///
  /// This is typically false when the program transitively imports an
  /// unsupported library, or if the compiler fails for another reason.
  final bool didCompile;

  /// An optional JavaScript expression that might be emitted by `dart2wasm`.
  /// The expression evaluates to `true` if the current JavaScript environment
  /// supports all the features expected by the generated WebAssembly module.
  final String? supportExpression;

  const Dart2WasmBootstrapResult.didNotCompile()
    : didCompile = false,
      supportExpression = null;

  Dart2WasmBootstrapResult({required this.supportExpression})
    : didCompile = true;
}

/// Invokes `dart compile wasm` to compile the primary input of [buildStep].
///
/// This only emits the `.wasm` and `.mjs` files produced by `dart2wasm`. An
/// entrypoint loader needs to be emitted separately.
Future<Dart2WasmBootstrapResult> bootstrapDart2Wasm(
  BuildStep buildStep,
  List<String> additionalArguments,
  String javaScriptModuleExtension, {
  bool silenceUnsupportedModulesWarnings = false,
}) async {
  return await _resourcePool.withResource(
    () => _bootstrapDart2Wasm(
      buildStep,
      additionalArguments,
      javaScriptModuleExtension,
      silenceUnsupportedModulesWarnings: silenceUnsupportedModulesWarnings,
    ),
  );
}

Future<Dart2WasmBootstrapResult> _bootstrapDart2Wasm(
  BuildStep buildStep,
  List<String> additionalArguments,
  String javaScriptModuleExtension, {
  bool silenceUnsupportedModulesWarnings = false,
}) async {
  final dartEntrypointId = buildStep.inputId;
  final moduleId = dartEntrypointId.changeExtension(
    moduleExtension(dart2wasmPlatform),
  );
  var args = <String>[];
  {
    final module = Module.fromJson(
      json.decode(await buildStep.readAsString(moduleId))
          as Map<String, dynamic>,
    );
    List<Module> allDeps;
    try {
      allDeps = (await module.computeTransitiveDependencies(
        buildStep,
        throwIfUnsupported: !silenceUnsupportedModulesWarnings,
      ))..add(module);
    } on UnsupportedModules catch (e) {
      final librariesString = (await e.exactLibraries(buildStep).toList())
          .map(
            (lib) => AssetId(
              lib.id.package,
              lib.id.path.replaceFirst(moduleLibraryExtension, '.dart'),
            ),
          )
          .join('\n');
      log.warning('''
Skipping compiling ${buildStep.inputId} with dart2wasm because some of its
transitive libraries have sdk dependencies that are not supported on this platform:

$librariesString
''');
      return const Dart2WasmBootstrapResult.didNotCompile();
    }

    final scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
    final allSrcs = allDeps.expand((module) => module.sources);
    await scratchSpace.ensureAssets(allSrcs, buildStep);

    final dartUri =
        dartEntrypointId.path.startsWith('lib/')
            ? Uri.parse(
              'package:${dartEntrypointId.package}/'
              '${dartEntrypointId.path.substring('lib/'.length)}',
            )
            : Uri.parse('$multiRootScheme:///${dartEntrypointId.path}');
    final wasmOutputPath =
        p.withoutExtension(
          dartUri.scheme == 'package'
              ? 'packages/${dartUri.path}'
              : dartUri.path.substring(1),
        ) +
        wasmExtension;

    args = [
      '--packages=$multiRootScheme:///.dart_tool/package_config.json',
      // The -E prefix is removed by dartdev when starting the actual dart2wasm
      // process.
      '-E--multi-root-scheme=$multiRootScheme',
      '-E--multi-root=${scratchSpace.tempDir.uri.toFilePath()}',
      for (final experiment in enabledExperiments)
        '--enable-experiment=$experiment',
      ...additionalArguments,
      '-o',
      wasmOutputPath,
      '$dartUri',
    ];
  }

  log.info('Running `dart compile wasm` with ${args.join(' ')}\n');
  final result = await Process.run(p.join(sdkDir, 'bin', 'dart'), [
    'compile',
    'wasm',
    ...args,
  ], workingDirectory: scratchSpace.tempDir.path);

  final wasmOutputId = dartEntrypointId.changeExtension(wasmExtension);
  final wasmOutputFile = scratchSpace.fileFor(wasmOutputId);
  if (result.exitCode == 0 && await wasmOutputFile.exists()) {
    log.info('${result.stdout}\n${result.stderr}');

    await scratchSpace.copyOutput(wasmOutputId, buildStep);

    await fixAndCopySourceMap(
      dartEntrypointId.changeExtension(wasmSourceMapExtension),
      scratchSpace,
      buildStep,
    );

    final loaderContents =
        await scratchSpace
            .fileFor(dartEntrypointId.changeExtension(moduleJsExtension))
            .readAsBytes();
    await buildStep.writeAsBytes(
      dartEntrypointId.changeExtension(javaScriptModuleExtension),
      loaderContents,
    );
  } else {
    log.severe(
      'ExitCode:${result.exitCode}\nStdOut:\n${result.stdout}\n'
      'StdErr:\n${result.stderr}',
    );
    return const Dart2WasmBootstrapResult.didNotCompile();
  }

  final supportFile = scratchSpace.fileFor(
    dartEntrypointId.changeExtension('.support.js'),
  );
  String? supportExpression;
  if (await supportFile.exists()) {
    supportExpression = await supportFile.readAsString();
  }

  return Dart2WasmBootstrapResult(supportExpression: supportExpression);
}
