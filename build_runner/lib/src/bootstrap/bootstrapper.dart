// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:io/io.dart';
import 'package:package_config/package_config.dart';

import '../exceptions.dart';
import '../internal.dart';
import 'compiler.dart';
import 'depfiles.dart';
import 'runner.dart';

// DO NOT SUBMIT
// ignore_for_file: deprecated_member_use
// ignore_for_file: only_throw_errors
//

class Bootstrapper {
  static bool runningFromBuildScript = false;

  final Depfile dillDepfile = Depfile(
    depfilePath: '.dart_tool/build/entrypoint/build.dart.dill.deps',
    digestPath: '.dart_tool/build/entrypoint/build.dart.dill.digest',
    output: '.dart_tool/build/entrypoint/build.dart.dill',
    inputs: [],
  );

  PackageConfig? config;
  bool? buildRunnerHasChanged;
  bool? buildYamlHasChanged;
  bool? buildDillHasChanged;

  Future<bool> needsRebuild() async {
    if (!runningFromBuildScript) return false;
    // TODO(davidmorgan): fix for workspace, error handling.
    config ??= (await findPackageConfig(Directory.current, recurse: true))!;

    // TODO(davidmorgan): is this the right thing to check?
    await _regenerateBuildScript();
    final result = !dillDepfile.outputIsUpToDate();
    return result;
  }

  Future<int> run(
    BuiltList<String> arguments, {
    Iterable<String>? experiments,
  }) async {
    while (true) {
      // TODO(davidmorgan): fix for workspace, error handling.
      config = (await findPackageConfig(Directory.current, recurse: true))!;

      await _regenerateBuildScript();
      await _checkBuildDill(experiments: experiments);

      if (buildDillHasChanged!) {
        buildLog.fullBuildBecause(FullBuildReason.incompatibleScript);
        buildProcessState.outputsAreFromStaleBuildScript = true;
      }

      final exitCode = await Runner().run(arguments);
      if (exitCode != ExitCode.tempFail.code) {
        return exitCode;
      }
    }
  }

  Future<void> _regenerateBuildScript() async {
    final buildScript = await generateBuildScript(log: false);
    final path = '.dart_tool/build/entrypoint/build.dart';
    final existingBuildScript =
        File(path).existsSync() ? File(path).readAsStringSync() : '';
    if (buildScript != existingBuildScript) {
      File(path)
        ..createSync(recursive: true)
        ..writeAsStringSync(buildScript);
    }
  }

  Future<void> _checkBuildDill({Iterable<String>? experiments}) async {
    final compiler = Compiler();
    if (dillDepfile.outputIsUpToDate()) {
      buildDillHasChanged = false;
    } else {
      buildDillHasChanged = true;

      final result = await compiler.compile(experiments: experiments);
      if (!result.succeeded) {
        if (result.messages != null) {
          buildLog.error(result.messages!);
        }
        buildLog.error(
          'Failed to compile build script. '
          'Check builder definitions and generated script $scriptLocation.',
        );
        throw const CannotBuildException();
      }
      // TODO(davidmorgan): this is weird.
      dillDepfile.loadDeps();
      dillDepfile.write();
    }
  }
}
