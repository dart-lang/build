// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

import '../common/common.dart';

main() {
  group('serve integration tests', () {
    Process pubProcess;
    Stream<String> pubStdOutLines;

    setUp(() async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_resolvers',
          'build_runner',
          'build_test',
        ]),
        d.dir('lib', [
          d.file('example.dart', "String hello = 'hello'"),
        ]),
      ]).create();

      await pubGet('a');
      pubProcess = await startPub('a', 'run', args: ['build_runner', 'serve']);
      pubStdOutLines = pubProcess.stdout
          .transform(new Utf8Decoder())
          .transform(new LineSplitter())
          .asBroadcastStream();
    });

    tearDown(() async {
      pubProcess.kill();
      await pubProcess.exitCode;
    });

    test('warns if it didnt find a directory to serve', () async {
      expect(pubStdOutLines,
          emitsThrough(contains('Found no known web directories to serve')),
          reason: 'never saw the warning');
    });
  });

  group('with optional outputs', () {
    HttpClient client;

    setUp(() {
      client = new HttpClient();
    });

    tearDown(() {
      client.close();
    });
    final buildContent = '''
import 'package:build_runner/build_runner.dart';
import 'package:build_test/build_test.dart';

main(List<String> args) async {
  var buildApplications = [
    apply(
        'root|optional',
        [
          (_) => new TestBuilder(
                  buildExtensions: {
                    '.txt': ['.txt.copy', '.txt.extra']
                  },
                  build: (buildStep, _) async {
                    await buildStep.writeAsString(
                        buildStep.inputId.addExtension('.copy'),
                        await buildStep.readAsString(buildStep.inputId));
                    await buildStep.writeAsString(
                        buildStep.inputId.addExtension('.extra'), 'extra');
                  })
        ],
        toRoot(),
        isOptional: true),
    apply(
        'root|required',
        [
          (options) => new TestBuilder(
              buildExtensions: appendExtension('.other', from: '.txt'),
              extraWork: (buildStep, _) async {
                if ((await buildStep.readAsString(buildStep.inputId)) ==
                    'true') {
                  await buildStep
                      .readAsString(buildStep.inputId.addExtension('.copy'));
                }
              })
        ],
        toRoot(),
        isOptional: false),
  ];
  ;
  await run(args, buildApplications);
}
''';

    Future<TestProcess> startServer() =>
        TestProcess.start('dart', [p.join('tool', 'build.dart'), 'serve'],
            workingDirectory: p.join(d.sandbox, 'a'));

    Future<void> readThrough(StreamQueue<String> out, String message) async {
      while (await out.hasNext) {
        if ((await out.next).contains(message)) return;
      }
      throw 'Did not emit line containing [$message]';
    }

    Future<void> expect404(String path) async {
      final request = await client.get('localhost', 8080, path);
      final response = await request.close();
      expect(response.statusCode, 404);
    }

    Future<void> expectContent(String path, String content) async {
      final request = await client.get('localhost', 8080, path);
      final response = await request.close();
      expect(response.statusCode, 200);
      expect(await utf8.decodeStream(response), content);
    }

    test('only serves assets that were actually required', () async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_resolvers',
          'build_runner',
          'build_test',
        ]),
        d.dir('tool', [d.file('build.dart', buildContent)]),
        d.dir('web', [
          // Initialy the require build step won't read the optional output
          d.file('a.txt', 'false'),
        ]),
      ]).create();

      await pubGet('a');

      var server = await startServer();
      await readThrough(server.stdout, 'Serving `web`');

      await expect404('a.txt.copy');
      await expect404('a.txt.extra');

      await d.dir('a', [
        d.dir('web', [d.file('a.txt', 'true')])
      ]).create();

      await readThrough(server.stdout, 'Succeeded after');

      await expectContent('a.txt.copy', 'true');
      await expectContent('a.txt.extra', 'extra');

      await d.dir('a', [
        d.dir('web', [d.file('a.txt', 'false')])
      ]).create();

      await readThrough(server.stdout, 'Succeeded after');

      await expect404('a.txt.copy');
      await expect404('a.txt.extra');

      await server.kill();
    });
  });
}
