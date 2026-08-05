// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import '../build_plan/build_packages.dart';
import '../build_plan/build_paths.dart';
import '../constants.dart';
import 'build_script_generate.dart';
import 'compiler.dart';
import 'processes.dart';

/// Compiles the build script in an isolated temporary workspace containing
/// a minimal `pubspec.yaml` with only builder dependencies.
Future<CompileResult> compileInTemporaryWorkspace({
  required BuildPaths buildPaths,
  required String mode,
  required String outputPath,
  required String depfilePath,
  Iterable<String>? experiments,
}) async {
  final tmpDir = Directory.systemTemp.createTempSync('build_runner_compile_');
  try {
    final builderFactories = await loadBuilderFactories(buildPaths: buildPaths);
    final buildPackages = await BuildPackages.forPaths(buildPaths);

    final requiredPackages = <String>{'build_runner'};
    for (final uri in builderFactories.importPrefixes.keys) {
      if (uri.startsWith('package:')) {
        final slash = uri.indexOf('/');
        if (slash != -1) {
          requiredPackages.add(uri.substring(8, slash));
        } else {
          requiredPackages.add(uri.substring(8));
        }
      }
    }

    final pubspecBuf = StringBuffer();
    pubspecBuf.writeln('name: _build_runner_tmp');
    pubspecBuf.writeln('environment:');
    pubspecBuf.writeln('  sdk: ^${Platform.version.split(' ').first}');
    pubspecBuf.writeln('dependencies:');
    for (final pkgName in requiredPackages) {
      if (buildPackages[pkgName] != null) {
        pubspecBuf.writeln('  $pkgName: any');
      }
    }
    pubspecBuf.writeln('dependency_overrides:');
    for (final pkgName in requiredPackages) {
      final pkg = buildPackages[pkgName];
      if (pkg != null) {
        pubspecBuf.writeln('  $pkgName:');
        pubspecBuf.writeln('    path: ${pkg.path}');
      }
    }

    final pubspecPath = p.join(tmpDir.path, 'pubspec.yaml');
    File(pubspecPath).writeAsStringSync(pubspecBuf.toString());

    final dart = Platform.resolvedExecutable;
    final pubResult = await ParentProcess.run(dart, [
      'pub',
      'get',
    ], workingDirectory: tmpDir.path);
    if (pubResult.exitCode != 0) {
      return CompileResult(
        messages:
            'Failed to run `dart pub get` in temporary workspace:\n'
            '${pubResult.stderr}\n${pubResult.stdout}',
      );
    }

    final buildScriptContent = await generateBuildScript(
      buildPaths: buildPaths,
    );
    final scriptPath = p.join(tmpDir.path, 'build.dart');
    File(scriptPath).writeAsStringSync(buildScriptContent);

    final packageConfigPath = p.join(
      tmpDir.path,
      '.dart_tool',
      'package_config.json',
    );

    File(outputPath).parent.createSync(recursive: true);

    final compileResult = await ParentProcess.run(dart, [
      'compile',
      mode,
      '--packages',
      packageConfigPath,
      scriptPath,
      '--output',
      outputPath,
      '--depfile',
      depfilePath,
      if (experiments != null)
        for (final experiment in experiments) '--enable-experiment=$experiment',
    ], workingDirectory: tmpDir.path);

    if (compileResult.exitCode == 0) {
      final stdout = compileResult.stdout as String;
      if (stdout.contains('Unknown experiment:')) {
        final outFile = File(outputPath);
        if (outFile.existsSync()) {
          outFile.deleteSync();
        }
        final messages = stdout
            .split('\n')
            .where((String e) => e.startsWith('Unknown experiment'))
            .join('\n');
        return CompileResult(messages: messages);
      }

      // Rewrite depfile so references to tmpDir/build.dart point to the
      // workspace entrypointScriptPath and tmpDir paths are removed.
      final depfile = File(depfilePath);
      if (depfile.existsSync()) {
        final content = depfile.readAsStringSync();
        final colonIdx = content.indexOf(': ');
        if (colonIdx != -1) {
          final target = content.substring(0, colonIdx + 2);
          final deps = content.substring(colonIdx + 2).split(' ');
          final newDeps = <String>[];
          final realScriptPath = p.join(
            buildPaths.outputRootPath,
            entrypointScriptPath,
          );
          for (final dep in deps) {
            final trimmed = dep.trim();
            if (trimmed.isEmpty) continue;
            if (trimmed == scriptPath ||
                p.canonicalize(trimmed) == p.canonicalize(scriptPath)) {
              newDeps.add(realScriptPath);
            } else if (!trimmed.startsWith(tmpDir.path) &&
                !p
                    .canonicalize(trimmed)
                    .startsWith(p.canonicalize(tmpDir.path))) {
              newDeps.add(trimmed);
            }
          }
          depfile.writeAsStringSync('$target${newDeps.join(' ')}\n');
        }
      }

      return CompileResult(messages: null);
    }

    var stderr = compileResult.stderr as String;
    stderr = stderr
        .replaceAll('Bad state: Generating kernel failed!', '')
        .trim();
    return CompileResult(
      messages: stderr.isEmpty ? compileResult.stdout as String : stderr,
    );
  } finally {
    try {
      tmpDir.deleteSync(recursive: true);
    } catch (_) {}
  }
}
