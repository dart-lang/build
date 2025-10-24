// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS floadF
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:build_runner/src/logging/build_log.dart';
import 'package:io/io.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart' as test;
import 'package:test/test.dart';

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

  void copyPackage(String package) {
    final sourcePath = pubspecs.packageConfig[package]!.root.toFilePath();
    final destinationPath = p.join(tempDirectory.path, package);
    copyPathSync(sourcePath, destinationPath);
  }

  /// Reads workspace-relative [path], or returns `null` if it does not exist.
  String? read(String path) {
    final file = File(p.join(tempDirectory.path, path));
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  /// Reads workspace-relative [path], or returns `null` if it does not exist.
  Uint8List? readBytes(String path) {
    final file = File(p.join(tempDirectory.path, path));
    return file.existsSync() ? file.readAsBytesSync() : null;
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
    file.deleteSync(recursive: true);
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
    Map<String, String>? environment,
  }) async {
    final args = commandLine.split(' ');
    final command = args.removeAt(0);
    final result = await Process.run(
      command,
      args,
      workingDirectory: p.join(tempDirectory.path, directory),
      environment: environment,
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
    final process = await Process.start(
      command,
      args,
      workingDirectory: p.join(tempDirectory.path, directory),
    );
    final result = BuildRunnerProcess(process);
    addTearDown(result.kill);
    return result;
  }
}

/// A running `build_runner` process.
class BuildRunnerProcess {
  final Process process;
  final StreamQueue<String> _outputs;
  late final HttpClient _client = HttpClient();
  int? _port;
  Future<void>? _killResult;

  BuildRunnerProcess(this.process)
    : _outputs = StreamQueue(
        StreamGroup.merge([
          process.stdout
              .transform(utf8.decoder)
              .transform(const LineSplitter()),
          process.stderr
              .transform(utf8.decoder)
              .transform(const LineSplitter()),
        ]),
      );

  /// Expects nothing new on stdout or stderr for [duration].
  Future<void> expectNoOutput(Duration duration) async {
    printOnFailure('--- $_testLine expects no output');
    final output = <String>[];
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < duration) {
      try {
        output.add(await _outputs.next.timeout(duration - stopwatch.elapsed));
      } on TimeoutException catch (_) {
        // Expected.
      } catch (_) {
        fail('While expecting no output, process exited.');
      }
    }

    if (output.isNotEmpty) {
      fail(
        'While expecting no output, got:\n\n===\n${output.join('\n')}\n===\n',
      );
    }
  }

  /// Expects [pattern] to appear in the process's stdout or stderr.
  ///
  /// If [failOn] is encountered instead, the test fails immediately. It
  /// defaults to [BuildLog.failurePattern] so that `expect` will stop if the
  /// process reports a build failure.
  ///
  /// if [expectFailure] is set, then both [pattern] and [failOn] must be
  /// encountered for the test to pass.
  ///
  /// If the process exits instead, the test fails immediately.
  ///
  /// Otherwise, waits until [pattern] appears, returns the matching line.
  ///
  /// Throws if the process appears to be stuck or done: if it outputs nothing
  /// for 30s.
  Future<String> expect(
    Pattern pattern, {
    Pattern? failOn,
    bool expectFailure = false,
  }) async {
    printOnFailure(
      '--- $_testLine expects `$pattern`'
      '${failOn == null ? '' : ', failOn: `$failOn`'}'
      '${expectFailure ? ', expectFailure: true' : ''}',
    );
    failOn ??= BuildLog.failurePattern;

    final expectsMessage =
        expectFailure
            ? '`$pattern` with failure matching (`$failOn`)'
            : '`$pattern`';

    var failureSeen = false;
    var patternSeen = false;
    while (true) {
      String? line;
      try {
        line = await _outputs.next.timeout(const Duration(seconds: 30));
      } on TimeoutException catch (_) {
        throw fail('While expecting $expectsMessage, timed out after 30s.');
      } catch (_) {
        throw fail('While expecting $expectsMessage, process exited.');
      }
      printOnFailure(line);
      if (line.contains(failOn)) {
        failureSeen = true;
      }
      if (line.contains(pattern)) {
        patternSeen = true;
      }

      if (expectFailure) {
        if (patternSeen && failureSeen) {
          return line;
        }
      } else {
        if (failureSeen) {
          fail('While expecting $expectsMessage, got `$failOn`.');
        }
        if (patternSeen) {
          return line;
        }
      }
    }
  }

  String get _testLine {
    var result =
        StackTrace.current
            .toString()
            .split('\n')
            .where((l) => l.contains('_test.dart'))
            .first;
    result = result.substring(result.lastIndexOf('/') + 1);
    result = result.substring(0, result.lastIndexOf(':'));
    return result;
  }

  /// Kills the process.
  Future<void> kill() {
    return _killResult ??= _kill();
  }

  Future<void> _kill() async {
    process.kill();
    _outputs.rest.listen((line) => printOnFailure('Output after kill: $line'));
    await process.exitCode;
    // Wait a few seconds for child process cleanup.
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  Future<int> get exitCode => process.exitCode;

  // Expects the server to log that it is serving, records the port.
  Future<void> expectServing() async {
    final regexp = RegExp('Serving `web` on http://localhost:([0-9]+)');
    final line = await expect(regexp);
    final port = int.parse(regexp.firstMatch(line)!.group(1)!);
    _port = port;
  }

  /// Requests [path] from the server and expects it returns
  /// [expectResponseCode].
  ///
  /// Returns the response content.
  Future<String> fetchContent(
    String path, {
    int expectResponseCode = 200,
  }) async {
    final response = await fetch(path, expectResponseCode: expectResponseCode);
    return await utf8.decodeStream(response.cast<List<int>>());
  }

  /// Requests [path] from the server and expects it returns
  /// [expectResponseCode].
  ///
  /// Optionally, pass [headers] to set on the request.
  ///
  /// Returns the full response.
  Future<HttpClientResponse> fetch(
    String path, {
    Map<String, String>? headers,
    int expectResponseCode = 200,
  }) async {
    if (_port == null) throw StateError('Call expectServing first.');
    final request = await _client.get('localhost', _port!, path);
    if (headers != null) {
      for (final entry in headers.entries) {
        request.headers.add(entry.key, entry.value);
      }
    }
    final response = await request.close();
    test.expect(response.statusCode, expectResponseCode);
    return response;
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
