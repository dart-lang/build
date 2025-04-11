// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'config.dart';

/// A temporary workspace for benchmarking `build_runner`.
class Workspace {
  final Config config;
  final String name;

  Directory get directory =>
      Directory.fromUri(config.rootDirectory.uri.resolve(name));

  Workspace({required this.config, required this.name, bool clean = true}) {
    if (clean) {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
      directory.createSync(recursive: true);
    }
  }

  /// Writes [source] to [path].
  void write(String path, {required String source}) {
    final file = File.fromUri(directory.uri.resolve(path));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(source);
  }

  /// Edits the file at [path] to replace `CACHEBUSTER` with a timestamp.
  ///
  /// Throws `StateError` if the string is not present to replace.
  void edit(String path) {
    final file = File.fromUri(directory.uri.resolve(path));
    final source = file.readAsStringSync();
    final edited = source.replaceAll(
      'CACHEBUSTER',
      'CACHEBUSTER${DateTime.now().microsecondsSinceEpoch.toString()}',
    );
    if (source == edited) {
      throw StateError('Edit of "$path" failed: no CACHEBUSTER in source.');
    }
    file.writeAsStringSync(edited);
  }

  /// Builds and measures performance.
  PendingResult measure() {
    final result = PendingResult();
    _measure(result);
    return result;
  }

  Future<void> _measure(PendingResult result) async {
    // Clean build.
    final stopwatch = Stopwatch()..start();
    var process = await Process.start('dart', [
      'run',
      'build_runner',
      'build',
      '-d',
      if (config.useExperimentalResolver) '--use-experimental-resolver',
    ], workingDirectory: directory.path);
    var exitCode = await process.exitCode;
    if (exitCode == 0) {
      result.cleanBuildTime = stopwatch.elapsed;
    } else {
      final stdout = await process.stdout.transform(utf8.decoder).join();
      final stderr = await process.stderr.transform(utf8.decoder).join();
      result.failure = 'Initial build failed:\n$stdout\n$stderr';
      return;
    }

    result.graphSize = _readGraphSize();

    // Build with no changes.
    stopwatch.reset();
    process = await Process.start('dart', [
      'run',
      'build_runner',
      'build',
      '-d',
      if (config.useExperimentalResolver) '--use-experimental-resolver',
    ], workingDirectory: directory.path);
    exitCode = await process.exitCode;
    if (exitCode == 0) {
      result.noChangesBuildTime = stopwatch.elapsed;
    } else {
      final stdout = await process.stdout.transform(utf8.decoder).join();
      final stderr = await process.stderr.transform(utf8.decoder).join();
      result.failure = 'No changes build failed:\n$stdout\n$stderr';
      return;
    }

    // Incremental build after a change.
    edit('lib/app.dart');
    stopwatch.reset();
    process = await Process.start('dart', [
      'run',
      'build_runner',
      'build',
      '-d',
      if (config.useExperimentalResolver) '--use-experimental-resolver',
    ], workingDirectory: directory.path);
    exitCode = await process.exitCode;
    if (exitCode == 0) {
      result.incrementalBuildTime = stopwatch.elapsed;
    } else {
      final stdout = await process.stdout.transform(utf8.decoder).join();
      final stderr = await process.stderr.transform(utf8.decoder).join();
      result.failure = 'Incremental build failed:\n$stdout\n$stderr';
      return;
    }
  }

  /// Returns the `build_runner` asset graph size, or `null` if not found.
  int? _readGraphSize() {
    for (final entry in Directory.fromUri(
      directory.uri.resolve('.dart_tool/build'),
    ).listSync(recursive: true)) {
      if (entry is! File) continue;
      if (entry.path.endsWith('asset_graph.json')) return entry.lengthSync();
    }
    return null;
  }
}

/// Benchmark results.
///
/// May be partial if the benchmark is still running.
class PendingResult {
  Duration? cleanBuildTime;
  Duration? noChangesBuildTime;
  Duration? incrementalBuildTime;
  int? graphSize;
  String? failure;

  bool get isFailure => failure != null;

  bool get isSuccess =>
      !isFailure &&
      cleanBuildTime != null &&
      noChangesBuildTime != null &&
      incrementalBuildTime != null;
  bool get isFinished => isSuccess || isFailure;
}
