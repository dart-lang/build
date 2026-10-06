// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../contract_weaver.dart';
import 'package_layout_finder.dart';
import 'stager.dart';
import 'weaver_exception.dart';
import 'weaver_options.dart';
import 'woven_package_runner.dart';

/// `dart run _contract_weaver`: weaves contracts into a copy of a package and
/// runs its tests, or analyzes it, against that copy.
class ContractWeaverCommand {
  /// Runs the command with [args], returning the exit code.
  Future<int> run(List<String> args) async {
    try {
      return await _run(WeaverOptions.parse(args));
    } on WeaverException catch (e) {
      stderr.writeln('Error: ${e.message}');
      return 1;
    }
  }

  Future<int> _run(WeaverOptions options) async {
    if (options.help) {
      stdout.writeln(WeaverOptions.usage);
      return 0;
    }

    final stager = _stage(options);
    final runner = WovenPackageRunner(
      stageDir: stager.stageDir,
      stagedPackage: stager.stagedPackage,
    );
    stdout.writeln('Resolving dependencies in the woven copy...');
    await runner.resolve();

    if (options.analyzeOnly) return _analyze(runner);
    stdout.writeln('Running tests against woven sources...');
    return runner.test(options.testArgs);
  }

  /// Weaves the package that [options] names into its stage directory.
  Stager _stage(WeaverOptions options) {
    final layout = PackageLayoutFinder(Directory.current).find(options.package);
    final stager = Stager(
      layout: layout,
      stagePath: options.stageDir ?? Stager.defaultStagePath(layout.root),
      weaver: ContractWeaver(),
    );
    final stagePath = stager.stageDir.path;

    if (options.clean) {
      stdout.writeln('Cleaning stage directory $stagePath ...');
      stager.clean();
    }
    stdout.writeln('Staging woven copy at $stagePath ...');
    final staged = stager.stage();
    stdout.writeln(
      'Staged ${layout.displayName}/lib: ${staged.transformedCount} '
      'transformed, ${staged.symlinkCount} symlinked.',
    );
    return stager;
  }

  /// Analyzes the woven copy, returning the exit code.
  Future<int> _analyze(WovenPackageRunner runner) async {
    stdout.writeln('Analyzing woven sources...');
    final errors = await runner.analyze();
    if (errors.isEmpty) {
      stdout.writeln('Contract clauses analyze clean.');
      return 0;
    }
    errors.forEach(stderr.writeln);
    final noun = errors.length == 1 ? 'error' : 'errors';
    stderr.writeln('${errors.length} $noun in woven sources.');
    return 1;
  }
}
