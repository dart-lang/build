// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:build_runner/src/logging/build_log.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../common/common.dart';

void main() {
  setUpAll(() async {
    await d.dir('a', [
      await pubspec(
        'a',
        currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_modules',
          'build_runner',
          'build_test',
          'build_web_compilers',
          'code_builder',
          'test',
        ],
      ),
      d.dir('test', [
        d.file('hello_test.dart', '''
import 'package:test/test.dart';
main() {
  test('hello', () {});
}'''),
      ]),
      d.dir('web', [
        d.file('main.dart', '''
main() {
  print('hello world');
}'''),
      ]),
    ]).create();

    await pubGet('a', offline: false);
  });

  tearDown(() async {
    for (final file
        in Directory(
          p.join(d.sandbox, 'a'),
        ).listSync(recursive: true).whereType<File>()) {
      if (file.path.endsWith('.dart') ||
          file.path.endsWith('.yaml') ||
          file.path.endsWith('.lock')) {
        continue;
      }
      file.deleteSync();
    }
  });

  void expectOutput(String path, {required bool exists}) {
    path = p.join(
      d.sandbox,
      'a',
      '.dart_tool',
      'build',
      'generated',
      'a',
      path,
    );
    expect(File(path).existsSync(), exists);
  }

  Future<int> runSingleBuild(
    String command,
    List<String> args, {
    StreamSink<String>? stdoutSink,
  }) async {
    final process = await startPub('a', 'run', args: args);
    final stdoutLines =
        process.stdout
            .transform(const Utf8Decoder())
            .transform(const LineSplitter())
            .asBroadcastStream()
          ..listen((line) {
            stdoutSink?.add(line);
            printOnFailure(line);
          });
    final queue = StreamQueue(stdoutLines);
    if (command == 'serve' || command == 'watch') {
      while (await queue.hasNext) {
        final nextLine = await queue.next;
        if (nextLine.contains(BuildLog.successPattern)) {
          process.kill();
          await process.exitCode;
          return ExitCode.success.code;
        } else if (nextLine.contains(BuildLog.failurePattern)) {
          process.kill();
          await process.exitCode;
          return 1;
        }
      }
      throw StateError('Build process exited without success or failure.');
    }
    final result = await process.exitCode;
    return result;
  }

  group('Building explicit output directories', () {
    void testBasicBuildCommand(String command) {
      test('is supported by the $command command', () async {
        final args = ['build_runner', command, 'web'];
        expect(await runSingleBuild(command, args), ExitCode.success.code);
        expectOutput('web/main.dart.js', exists: true);
        expectOutput(
          'test/hello_test.dart.browser_test.dart.js',
          exists: false,
        );
      });
    }

    void testBuildCommandWithOutput(String command) {
      test('works with -o and the $command command', () async {
        final outputDirName = 'foo';
        final args = [
          'build_runner',
          command,
          'web',
          '-o',
          'test:$outputDirName',
        ];
        expect(await runSingleBuild(command, args), ExitCode.success.code);
        expectOutput('web/main.dart.js', exists: true);
        expectOutput('test/hello_test.dart.browser_test.dart.js', exists: true);

        final outputDir = Directory(p.join(d.sandbox, 'a', 'foo'));
        await outputDir.delete(recursive: true);
      });
    }

    for (final command in ['build', 'serve', 'watch']) {
      testBasicBuildCommand(command);
      testBuildCommandWithOutput(command);
    }

    test('is not supported for the test command', () async {
      final command = 'test';
      final args = ['build_runner', command, 'web'];
      expect(await runSingleBuild(command, args), ExitCode.usage.code);

      args.addAll(['--', '-p chrome']);
      expect(await runSingleBuild(command, args), ExitCode.usage.code);
    });
  });

  test('test builds only the test directory by default', () async {
    final command = 'test';
    final args = ['build_runner', command];
    expect(await runSingleBuild(command, args), ExitCode.success.code);
    expectOutput('web/main.dart.js', exists: false);
    expectOutput('test/hello_test.dart.browser_test.dart.js', exists: true);
  });

  test('hoists output correctly even with --symlink', () async {
    final command = 'build';
    final outputDirName = 'foo';
    final args = [
      'build_runner',
      command,
      '-o',
      'web:$outputDirName',
      '--symlink',
    ];
    expect(await runSingleBuild(command, args), ExitCode.success.code);
    final outputDir = Directory(p.join(d.sandbox, 'a', 'foo'));
    expect(
      File(p.join(outputDir.path, 'web', 'main.dart.js')).existsSync(),
      isFalse,
    );
    expect(File(p.join(outputDir.path, 'main.dart.js')).existsSync(), isTrue);

    await outputDir.delete(recursive: true);
  });

  test('Duplicate output directories give a nice error', () async {
    final command = 'build';
    final args = [
      'build_runner',
      command,
      '-o',
      'web:build',
      '-o',
      'test:build',
    ];
    final stdoutController = StreamController<String>();
    expect(
      await runSingleBuild(command, args, stdoutSink: stdoutController.sink),
      ExitCode.usage.code,
    );
    expect(
      stdoutController.stream,
      emitsThrough(
        contains(
          'Invalid argument (--output): Duplicate output directories are not '
          'allowed, got: "web:build test:build"',
        ),
      ),
    );
    await stdoutController.close();
  });

  test('Build directories have to be top level dirs', () async {
    final command = 'build';
    final args = ['build_runner', command, '-o', 'foo/bar:build'];
    final stdoutController = StreamController<String>();
    expect(
      await runSingleBuild(command, args, stdoutSink: stdoutController.sink),
      ExitCode.usage.code,
    );
    expect(
      stdoutController.stream,
      emitsThrough(
        contains(
          'Invalid argument (--output): Input root can not be nested: '
          '"foo/bar:build"',
        ),
      ),
    );
    await stdoutController.close();
  });

  test('Handles socket errors gracefully', () async {
    final server = await HttpServer.bind('localhost', 8080);
    addTearDown(server.close);

    final process = await runPub(
      'a',
      'run',
      args: ['build_runner', 'serve', 'web:8080'],
    );
    expect(process.exitCode, ExitCode.osError.code);
    expect(
      process.stdout,
      allOf(
        contains('Error starting server'),
        contains('8080'),
        contains('address is already in use'),
      ),
    );
  });
}
