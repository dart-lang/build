// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:io/io.dart';
import 'package:package_config/package_config.dart';

import '../internal.dart';
import 'compiler.dart';
import 'depfiles.dart';
import 'runner.dart';

// DO NOT SUBMIT
// ignore_for_file: deprecated_member_use
// ignore_for_file: only_throw_errors
//

class Bootstrapper {
  final Depfile buildRunnerDepfile = Depfile(
    depfilePath: '.dart_tool/build/entrypoint/build_runner.deps',
    digestPath: '.dart_tool/build/entrypoint/build_runner.digest',
    output: null,
    inputs: [],
  );
  final Depfile buildSourceDepfile = Depfile(
    depfilePath: '.dart_tool/build/entrypoint/build.dart.deps',
    digestPath: '.dart_tool/build/entrypoint/build.dart.digest',
    output: '.dart_tool/build/entrypoint/build.dart',
    inputs: [],
  );
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

  bool runningFromBuildScript() {
    return StackTrace.current.toString().contains(
      '.dart_tool/build/entrypoint/build.dart',
    );
  }

  Future<bool> needsRebuild() async {
    if (!runningFromBuildScript()) return false;
    buildLog.debug(Platform.script.toString());
    // TODO(davidmorgan): fix for workspace, error handling.
    config ??= (await findPackageConfig(Directory.current, recurse: true))!;

    // TODO(davidmorgan): is this the right thing to check?
    buildLog.debug('needsRebuild?');
    final r1 = buildRunnerDepfile.outputIsUpToDate();
    final r2 = buildSourceDepfile.outputIsUpToDate();
    final r3 = dillDepfile.outputIsUpToDate();
    final result = !r1 || !r2 || !r3;
    buildLog.debug('needsRebuild? $r1 $r2 $r3 --> $result');
    return result;
  }

  Future<int> run(
    BuiltList<String> arguments, {
    BuiltList<String>? experiments,
  }) async {
    buildRunnerDepfile.output = Platform.script.path;
    while (true) {
      // TODO(davidmorgan): fix for workspace, error handling.
      config = (await findPackageConfig(Directory.current, recurse: true))!;

      _checkBuildRunner();
      await _checkBuildSource(force: buildRunnerHasChanged!);
      await _checkBuildDill();

      if (buildRunnerHasChanged! ||
          buildYamlHasChanged! ||
          buildDillHasChanged!) {
        // TODO separate script changes from yaml changes?
        if (buildYamlHasChanged!) {
          buildLog.fullBuildBecause(FullBuildReason.incompatibleScript);
        } else {
          buildLog.fullBuildBecause(FullBuildReason.incompatibleBuild);
        }
        buildProcessState.outputsAreFromStaleBuildScript = true;
      }

      final exitCode = await Runner().run(arguments);
      if (exitCode != ExitCode.tempFail.code) {
        return exitCode;
      }
    }
  }

  void _checkBuildRunner() {
    buildLog.debug('Check build_runner.');
    final package = config!['build_runner']!.packageUriRoot;
    final script = package.resolve('../bin/build_runner.dart');
    if (buildRunnerDepfile.outputIsUpToDate()) {
      buildLog.debug('build runner is up to date');
      buildRunnerHasChanged = false;
    } else {
      buildLog.debug('build runner update');
      buildRunnerHasChanged = true;
      buildRunnerDepfile.clear();
      buildRunnerDepfile.addScriptDeps(
        scriptPath: script.path,
        packageConfig: config!,
      );
      buildRunnerDepfile.write();
    }
  }

  Future<void> _checkBuildSource({required bool force}) async {
    if (!force && buildSourceDepfile.outputIsUpToDate()) {
      buildLog.debug('build script up to date');
      buildYamlHasChanged = false;
    } else {
      buildLog.debug('build script update (force: $force)');
      buildYamlHasChanged = true;
      final buildScript = await generateBuildScript();
      File(buildSourceDepfile.output!).writeAsStringSync(buildScript.content);
      buildSourceDepfile.clear();
      buildSourceDepfile.addDeps(buildScript.inputs);
      buildSourceDepfile.addScriptDeps(
        scriptPath: buildSourceDepfile.output!,
        packageConfig: config!,
      );
      buildSourceDepfile.write();
    }
  }

  Future<void> _checkBuildDill() async {
    final compiler = Compiler();
    if (dillDepfile.outputIsUpToDate()) {
      buildLog.debug('dill up to date');
      buildDillHasChanged = false;
    } else {
      buildLog.debug('dill update');
      buildDillHasChanged = true;

      final result = await compiler.compile();
      if (!result.succeeded) throw 'failed';
      // TODO(davidmorgan): this is weird.
      dillDepfile.loadDeps();
      dillDepfile.write();
    }
  }
}
