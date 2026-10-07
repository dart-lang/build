// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'weaver_exception.dart';

/// Runs `dart` commands on a staged, woven copy of a package.
class WovenPackageRunner {
  WovenPackageRunner({required this.stageDir, required this.stagedPackage});

  /// The root of the staged tree, where dependencies are resolved.
  final Directory stageDir;

  /// The staged copy of the woven package.
  final Directory stagedPackage;

  /// Resolves dependencies in the staged tree.
  ///
  /// Always resolve: the original pubspec may have changed since the last run.
  /// Offline first, because it is fast and usually enough.
  ///
  /// Throws [WeaverException] if resolution fails.
  Future<void> resolve() async {
    var result = await Process.run(Platform.resolvedExecutable, [
      'pub',
      'get',
      '--offline',
    ], workingDirectory: stageDir.path);
    if (result.exitCode != 0) {
      result = await Process.run(Platform.resolvedExecutable, [
        'pub',
        'get',
      ], workingDirectory: stageDir.path);
    }
    if (result.exitCode != 0) {
      throw WeaverException(
        '`dart pub get` failed in ${stageDir.path}.\n'
        '${result.stdout}${result.stderr}',
      );
    }
  }

  /// Analyzes the woven `lib`, returning the errors found, formatted for
  /// display.
  ///
  /// Clause text is invisible to the analyzer until it is woven in, so a
  /// clause naming something that has been renamed rots silently. Analyzing
  /// the woven copy catches that.
  ///
  /// Only errors count. A rotten clause names something that does not exist,
  /// which is an error. Warnings and lints report on generated code that no
  /// one reads, for example a `return` of a future inside the generated try
  /// that wraps a body in an invariant check.
  Future<List<String>> analyze() async {
    final result = await Process.run(Platform.resolvedExecutable, [
      'analyze',
      '--format=machine',
      'lib',
    ], workingDirectory: stagedPackage.path);
    return [
      for (final line in LineSplitter.split(result.stdout as String))
        if (line.startsWith('ERROR|')) _formatError(line),
    ];
  }

  /// Runs the tests of the woven package with [args], returning the exit code.
  ///
  /// Contract checks slow tests down, so the default timeout is raised and
  /// concurrency is limited unless [args] say otherwise.
  Future<int> test(Iterable<String> args) async {
    final hasTimeout = args.any(
      (a) => a == '--timeout' || a.startsWith('--timeout='),
    );
    final hasConcurrency = args.any(
      (a) =>
          a.startsWith('-j') ||
          a == '--concurrency' ||
          a.startsWith('--concurrency='),
    );
    final process = await Process.start(
      Platform.resolvedExecutable,
      [
        'test',
        if (!hasTimeout) '--timeout=4x',
        if (!hasConcurrency) '-j4',
        ...args,
      ],
      workingDirectory: stagedPackage.path,
      mode: ProcessStartMode.inheritStdio,
    );
    return process.exitCode;
  }

  /// [line] of `dart analyze --format=machine` output, as `file:line:column
  /// message - code`.
  static String _formatError(String line) {
    // SEVERITY|TYPE|CODE|FILE|LINE|COLUMN|LENGTH|MESSAGE
    final fields = line.split('|');
    return '${fields[3]}:${fields[4]}:${fields[5]} ${fields.last} '
        '- ${fields[2].toLowerCase()}';
  }
}
