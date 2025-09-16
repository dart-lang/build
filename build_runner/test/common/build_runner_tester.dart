// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS floadF
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:build_runner/src/logging/build_log.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart' as test;
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'fixture_packages.dart';

/// End to end tester for `build_runner`.
///
/// Creates a workspace under system temp, fills it with Dart packages, and runs
/// commands in it.
class BuildRunnerTester {
  final Pubspecs pubspecs;
  final Directory tempDirectory;

  BuildRunnerTester(this.pubspecs)
    : tempDirectory = Directory.systemTemp.createTempSync(
        'BuildRunnerTester-',
      ) {
    addTearDown(() => tempDirectory.deleteSync(recursive: true));
  }

  /// Writes a Dart package to the workspace.
  ///
  /// The package is written to the directory `$workspace/$name`.
  ///
  /// A `pubspec.yaml` is also written, see [Pubspecs.pubspec].
  void writePackage({
    required String name,
    required Map<String, String> files,
    List<String>? dependencies,
    List<String>? pathDependencies,
  }) {
    _writeDirectory(
      name: name,
      files: {
        'pubspec.yaml': pubspecs.pubspec(
          name: name,
          dependencies: dependencies,
          pathDependencies: pathDependencies,
        ),
        ...files,
      },
    );
  }

  void writeFixturePackage(FixturePackage fixturePackage) => writePackage(
    name: fixturePackage.name,
    files: fixturePackage.files,
    dependencies: fixturePackage.dependencies,
    pathDependencies: fixturePackage.pathDependencies,
  );

  /// Reads workspace-relative [path], or returns `null` if it does not exist.
  String? read(String path) {
    final file = File(p.join(tempDirectory.path, path));
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  /// Writes [contents] to workspace-relative [path].
  void write(String path, String contents) {
    final file = File(p.join(tempDirectory.path, path));
    file
      ..createSync(recursive: true)
      ..writeAsStringSync(contents);
  }

  /// Updates the file at workspace-relative [path], which must exist.
  void update(String path, String Function(String) update) {
    final file = File(p.join(tempDirectory.path, path));
    final data = file.readAsStringSync();
    file.writeAsStringSync(update(data));
  }

  /// Deletes the workspace-relative [path].
  void delete(String path) {
    final file = File(p.join(tempDirectory.path, path));
    file.deleteSync();
  }

  /// Reads the tree of files at the workspace-relative [path].
  ///
  /// Returns a `Map` from relative paths under [path] to file contents.
  ///
  /// The file contents is a `String` if utf8 decoding succeeds or a `Uint8List`
  /// if not.
  Map<String, Object>? readFileTree(String path) {
    final absolutePath = p.join(tempDirectory.path, path);
    final directory = Directory(absolutePath);
    if (!directory.existsSync()) return null;

    final result = <String, Object>{};
    for (final file in directory.listSync(recursive: true).whereType<File>()) {
      final relativePath = file.path
          .substring(absolutePath.length + 1)
          .replaceAll(r'\', '/');
      try {
        result[relativePath] = file.readAsStringSync();
      } catch (_) {
        result[relativePath] = file.readAsBytesSync();
      }
    }

    return result;
  }

  /// Writes a directory to the '$workspace/$name'.
  ///
  /// [files] is a map from relative path to file contents to write.
  ///
  void _writeDirectory({
    required String name,
    required Map<String, String> files,
  }) {
    final directory = Directory(p.join(tempDirectory.path, name));
    for (final entry in files.entries) {
      final file = File(p.join(directory.path, entry.key));
      file.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
  }

  /// Runs [commandLine] in [directory].
  ///
  /// By default, expects exit code 0 and fails the test if any other exit code
  /// is reported.
  ///
  /// Specify [expectExitCode] to expect a different exit code.
  Future<String> run(
    String directory,
    String commandLine, {
    int expectExitCode = 0,
  }) async {
    final args = commandLine.split(' ');
    final command = args.removeAt(0);
    final result = await Process.run(
      command,
      args,
      workingDirectory: p.join(tempDirectory.path, directory),
    );
    final output = '''
=== $directory: $commandLine
${result.stdout}${result.stderr}===
''';
    printOnFailure(output);
    expect(result.exitCode, expectExitCode);
    return output;
  }

  /// Starts [commandLine] in [directory].
  ///
  /// Returns a [BuildRunnerProcess] which can be used to interact with it.
  Future<BuildRunnerProcess> start(String directory, String commandLine) async {
    final args = commandLine.split(' ');
    final command = args.removeAt(0);
    final process = await TestProcess.start(
      command,
      args,
      workingDirectory: p.join(tempDirectory.path, directory),
    );
    addTearDown(process.kill);
    return BuildRunnerProcess(process);
  }
}

/// A running `build_runner` process.
class BuildRunnerProcess {
  final TestProcess process;
  final StreamQueue<String> _outputs;
  late final HttpClient _client = HttpClient();
  int? _port;

  BuildRunnerProcess(this.process)
    : _outputs = StreamQueue(
        StreamGroup.merge([process.stdoutStream(), process.stderrStream()]),
      );

  /// Expects [pattern] to appear in the process's stdout or stderr.
  ///
  /// If [failOn] is encountered instead, the test fails immediately. It
  /// defaults to [BuildLog.failurePattern] so that `expect` will stop if the
  /// process reports a build failure.
  ///
  /// If the process exits instead, the test fails immediately.
  ///
  /// Otherwise, waits until [pattern] appears, returns the matching line.
  Future<String> expect(Pattern pattern, {Pattern? failOn}) async {
    failOn ??= BuildLog.failurePattern;
    while (true) {
      String? line;
      try {
        line = await _outputs.next;
      } catch (_) {
        throw fail('While expecting `$pattern`, process exited.');
      }
      printOnFailure(line);
      if (line.contains(failOn)) {
        fail('While expecting `$pattern`, got `$failOn`.');
      }
      if (line.contains(pattern)) return line;
    }
  }

  /// Kills the process.
  Future<void> kill() => process.kill();

  // Expects the server to log that it is serving, records the port.
  Future<void> expectServing() async {
    final regexp = RegExp('Serving `web` on http://localhost:([0-9]+)');
    final line = await expect(regexp);
    final port = int.parse(regexp.firstMatch(line)!.group(1)!);
    _port = port;
  }

  /// Requests [path] from the server and expects it returns a 404
  /// response.
  Future<void> expect404(String path) async {
    if (_port == null) throw StateError('Call expectServing first.');
    final request = await _client.get('localhost', _port!, path);
    final response = await request.close();
    test.expect(response.statusCode, 404);
    await response.drain<void>();
  }

  /// Requests [path] from the server and expects it returns a 200
  /// response with the body [content].
  Future<void> expectContent(String path, String content) async {
    if (_port == null) throw StateError('Call expectServing first.');
    final request = await _client.get('localhost', _port!, path);
    final response = await request.close();
    test.expect(response.statusCode, 200);
    test.expect(await utf8.decodeStream(response.cast<List<int>>()), content);
  }
}

/// Creates `pubspec.yaml` for tests.
class Pubspecs {
  final PackageConfig packageConfig;

  Pubspecs(this.packageConfig);

  /// Creates [Pubspecs] with package config from the current isolate.
  static Future<Pubspecs> load() async =>
      Pubspecs(await loadPackageConfigUri((await Isolate.packageConfig)!));

  /// Returns `pubspec.yaml` content for the package called [name].
  ///
  /// The specified [dependencies] are included as path dependencies with
  /// locations from the current isolate's package config. This is for real
  /// packages that are being tested, such as `build_runner`.
  ///
  /// The specified [pathDependencies] are included as path dependencies onto
  /// peer folders. This allows to add a dependency onto another package that
  /// will be written using `writePackage`.
  String pubspec({
    required String name,
    List<String>? dependencies,
    List<String>? pathDependencies,
  }) {
    dependencies ??= [];
    pathDependencies ??= [];

    final result = StringBuffer('''
name: $name
environment:
  sdk: '>=3.7.0 <4.0.0'
dependencies:
''');

    for (final package in [...dependencies, ...pathDependencies]) {
      result.writeln('  $package: any');
    }

    result.writeln('dependency_overrides:');
    for (final package in dependencies) {
      final path = packageConfig[package]!.root.toFilePath();
      result
        ..writeln('  $package:')
        ..writeln('    path: $path');
    }
    for (final package in pathDependencies) {
      result
        ..writeln('  $package:')
        ..writeln('    path: ../$package');
    }

    return result.toString();
  }
}
