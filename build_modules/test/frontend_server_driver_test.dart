// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build_modules/src/common.dart';
import 'package:build_modules/src/frontend_server_driver.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Frontend Server', () {
    late PersistentFrontendServer server;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fes-test');
      final packageConfig = tempDir.uri.resolve(
        '.dart_tool/package_config.json',
      );
      File(packageConfig.toFilePath())
        ..createSync(recursive: true)
        ..writeAsStringSync(
          jsonEncode({'configVersion': 2, 'packages': <String>[]}),
        );
      server = await PersistentFrontendServer.start(
        sdkRoot: sdkDir,
        fileSystemRoot: tempDir.uri,
        packagesFile: packageConfig,
      );
    });

    tearDown(() async {
      await server.shutdown();
      await tempDir.delete(recursive: true);
    });

    test('can compile a simple dart file', () async {
      final entrypoint = tempDir.uri.resolve('entry.dart');
      File(entrypoint.toFilePath()).writeAsStringSync('void main() {}');

      final output = await server.compile(entrypoint.toString());
      expect(output, isNotNull);
      expect(output!.errorCount, 0);
      expect(output.outputFilename, endsWith('output.dill'));
      expect(output.sources, contains(entrypoint));
      server.accept();
    });

    test('can recompile with an invalidated file', () async {
      final entrypoint = tempDir.uri.resolve('entry.dart');
      final dep = tempDir.uri.resolve('dep.dart');
      File(
        entrypoint.toFilePath(),
      ).writeAsStringSync("import 'dep.dart'; void main() {}");
      File(dep.toFilePath()).writeAsStringSync('// empty');

      var output = await server.compile(entrypoint.toString());
      expect(output, isNotNull);
      expect(output!.errorCount, 0);
      server.accept();

      File(dep.toFilePath()).writeAsStringSync('invalid dart code');
      output = await server.recompile(entrypoint.toString(), [dep]);
      expect(output, isNotNull);
      expect(output!.errorCount, greaterThan(0));
      expect(output.errorMessage, contains("Error: Expected ';' after this."));
      await server.reject();
    });

    test('can handle compilation errors', () async {
      final entrypoint = tempDir.uri.resolve('entry.dart');
      File(entrypoint.toFilePath()).writeAsStringSync('void main() {');

      final output = await server.compile(entrypoint.toString());
      expect(output, isNotNull);
      expect(output!.errorCount, greaterThan(0));
      expect(output.errorMessage, isNotNull);
      expect(
        output.errorMessage,
        contains("Error: Can't find '}' to match '{'"),
      );
      await server.reject();
    });
  });

  group('Frontend Server Proxy', () {
    late FrontendServerProxyDriver driver;
    late PersistentFrontendServer server;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fes-test');
      final packageConfig = tempDir.uri.resolve(
        '.dart_tool/package_config.json',
      );
      File(packageConfig.toFilePath())
        ..createSync(recursive: true)
        ..writeAsStringSync(
          jsonEncode({'configVersion': 2, 'packages': <String>[]}),
        );
      server = await PersistentFrontendServer.start(
        sdkRoot: sdkDir,
        fileSystemRoot: tempDir.uri,
        packagesFile: packageConfig,
      );
      driver = FrontendServerProxyDriver();
      driver.init(server);
    });

    tearDown(() async {
      await driver.terminate();
      await tempDir.delete(recursive: true);
    });

    test('can recompile after valid edits', () async {
      final file1 = tempDir.uri.resolve('file1.dart');
      File(file1.toFilePath()).writeAsStringSync('void main() {}');
      final file2 = tempDir.uri.resolve('file2.dart');
      File(file2.toFilePath()).writeAsStringSync('void main() {}');

      var future1 = driver.recompile(file1.toString(), []);
      var future2 = driver.recompile(file2.toString(), []);

      var results = await Future.wait([future1, future2]);
      expect(results[0], isNotNull);
      expect(results[0]!.errorCount, 0);
      expect(results[1], isNotNull);
      expect(results[1]!.errorCount, 0);

      File(
        file1.toFilePath(),
      ).writeAsStringSync("void main() { print('edit!'); }");
      File(
        file2.toFilePath(),
      ).writeAsStringSync("void main() { print('edit!'); }");

      future1 = driver.recompile(file1.toString(), [file1]);
      future2 = driver.recompile(file2.toString(), [file2]);

      results = await Future.wait([future1, future2]);
      expect(results[0], isNotNull);
      expect(results[0]!.errorCount, 0);
      expect(results[1], isNotNull);
      expect(results[1]!.errorCount, 0);
    });

    test('recompileAndRecord successfully records and writes files', () async {
      final entrypoint = tempDir.uri.resolve('entrypoint.dart');
      File(entrypoint.toFilePath()).writeAsStringSync('void main() {}');

      final jsFESOutputPath = p.join(tempDir.path, 'entrypoint.dart.lib.js');
      final output = await driver.recompileAndRecord(
        '$multiRootScheme:///entrypoint.dart',
        [entrypoint],
        ['entrypoint.dart.lib.js'],
      );

      expect(output, isNotNull);
      expect(output.errorCount, 0);

      final jsOutputFile = File(
        jsFESOutputPath.replaceFirst('.dart.lib.js', '.ddc.js'),
      );
      print(jsOutputFile.path);
      expect(jsOutputFile.existsSync(), isTrue);
      final content = jsOutputFile.readAsStringSync();
      expect(content, contains('function main()'));
    });
  });
}
