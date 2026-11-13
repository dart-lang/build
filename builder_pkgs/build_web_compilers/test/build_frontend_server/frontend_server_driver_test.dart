// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build_web_compilers/src/build_frontend_server/frontend_server_driver.dart';
import 'package:build_web_compilers/src/common.dart';
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
      final configFile = File(
        p.join(Directory.current.path, fesManagerConfigPath),
      );
      if (configFile.existsSync()) configFile.deleteSync();
      server = PersistentFrontendServer(
        sdkRoot: sdkDir,
        fileSystemRoot: tempDir.uri,
        packagesFile: packageConfig,
      );
      await server.ensureStarted();
    });

    tearDown(() async {
      await server.shutdown();
      await tempDir.delete(recursive: true);
    });

    test(
      'throws ArgumentError if ensureStarted is called with different options',
      () async {
        final localTempDir = await Directory.systemTemp.createTemp(
          'fes-test-local',
        );
        final packageConfig = localTempDir.uri.resolve(
          '.dart_tool/package_config.json',
        );
        File(packageConfig.toFilePath())
          ..createSync(recursive: true)
          ..writeAsStringSync(
            jsonEncode({'configVersion': 2, 'packages': <String>[]}),
          );
        final localServer = PersistentFrontendServer(
          sdkRoot: sdkDir,
          fileSystemRoot: localTempDir.uri,
          packagesFile: packageConfig,
        );
        try {
          await localServer.ensureStarted(librariesPath: 'foo');
          expect(
            () => localServer.ensureStarted(librariesPath: 'bar'),
            throwsArgumentError,
          );
          // Calling with the same options is fine
          await localServer.ensureStarted(librariesPath: 'foo');
        } finally {
          await localServer.shutdown();
          await localTempDir.delete(recursive: true);
        }
      },
    );

    test('can compile a simple dart file', () async {
      final entrypoint = tempDir.uri.resolve('entry.dart');
      File(entrypoint.toFilePath()).writeAsStringSync('void main() {}');

      final output = await server.compile(entrypoint.toString());
      expect(output, isNotNull);
      expect(output!.errorCount, 0);
      expect(output.outputFilename, endsWith('output.dill'));
      expect(output.sources, contains(entrypoint));
      await server.accept();
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

    test('can reject and recompile with an invalidated file', () async {
      final entrypoint = tempDir.uri.resolve('entrypoint.dart');
      final dep = tempDir.uri.resolve('dep.dart');
      File(entrypoint.toFilePath())
          .writeAsStringSync("import 'dep.dart'; void main() {}");
      File(dep.toFilePath()).writeAsStringSync('// empty');

      var output = await server.compile(entrypoint.toString());
      expect(output, isNotNull);
      expect(output!.errorCount, 0);
      await server.accept();

      File(dep.toFilePath()).writeAsStringSync('invalid dart code');
      output = await server.recompile(entrypoint.toString(), [dep]);
      expect(output, isNotNull);
      expect(output!.errorCount, greaterThan(0));
      expect(output.errorMessage, contains("Error: Expected ';' after this."));
      await server.reject();

      File(dep.toFilePath()).writeAsStringSync('// empty');
      output = await server.recompile(entrypoint.toString(), [dep]);
      expect(output, isNotNull);
      expect(output!.errorCount, 0);
      await server.accept();
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
      final configFile = File(
        p.join(Directory.current.path, fesManagerConfigPath),
      );
      if (configFile.existsSync()) configFile.deleteSync();
      server = PersistentFrontendServer(
        sdkRoot: sdkDir,
        fileSystemRoot: tempDir.uri,
        packagesFile: packageConfig,
      );
      await server.ensureStarted();
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

      File(file1.toFilePath())
          .writeAsStringSync("void main() { print('edit!'); }");
      File(file2.toFilePath())
          .writeAsStringSync("void main() { print('edit!'); }");

      future1 = driver.recompile(file1.toString(), [file1]);
      future2 = driver.recompile(file2.toString(), [file2]);

      results = await Future.wait([future1, future2]);
      expect(results[0], isNotNull);
      expect(results[0]!.errorCount, 0);
      expect(results[1], isNotNull);
      expect(results[1]!.errorCount, 0);
    });

    // A rejected recompile reverts the Frontend Server to the last accepted
    // state, which also drops the files it invalidated. The driver has to send
    // them again, or the next recompile keeps compiling against their old
    // content.
    group('resends files invalidated by a rejected recompile', () {
      late Uri entrypoint;
      late Uri dep;

      setUp(() async {
        entrypoint = tempDir.uri.resolve('entrypoint.dart');
        dep = tempDir.uri.resolve('dep.dart');
        File(dep.toFilePath()).writeAsStringSync("String get a => 'a';");
        File(entrypoint.toFilePath())
            .writeAsStringSync("import 'dep.dart'; void main() { print(a); }");
        final output = await driver.recompile(entrypoint.toString(), []);
        expect(output!.errorCount, 0);

        // `dep.dart` gains a getter that the entrypoint uses, but the
        // entrypoint also has an unrelated error, so the recompile is
        // rejected.
        File(dep.toFilePath())
            .writeAsStringSync("String get a => 'a'; String get b => 'b';");
        File(entrypoint.toFilePath()).writeAsStringSync(
          "import 'dep.dart'; void main() { print(a + b + typo); }",
        );
        final rejected = await driver.recompile(entrypoint.toString(), [
          entrypoint,
          dep,
        ]);
        expect(rejected!.errorMessage, contains("Undefined name 'typo'"));

        // Only the entrypoint changes after that.
        File(
          entrypoint.toFilePath(),
        ).writeAsStringSync("import 'dep.dart'; void main() { print(a + b); }");
      });

      test('on recompile', () async {
        final output = await driver.recompile(entrypoint.toString(), [
          entrypoint,
        ]);
        expect(output!.errorMessage, isNull);
        expect(output.errorCount, 0);
      });

      test('on recompile-restart', () async {
        final output = await driver.recompileRestart(entrypoint.toString(), [
          entrypoint,
        ]);
        expect(output!.errorMessage, isNull);
        expect(output.errorCount, 0);
      });
    });

    test(
      'recompileAndRecord resends files invalidated by a rejected recompile',
      () async {
        final entrypoint = tempDir.uri.resolve('entrypoint.dart');
        final dep = tempDir.uri.resolve('dep.dart');
        const entrypointArg = '$multiRootScheme:///entrypoint.dart';
        // The builder invalidates files with the same scheme it compiles with.
        final entrypointUri = Uri.parse(entrypointArg);
        final depUri = Uri.parse('$multiRootScheme:///dep.dart');
        File(dep.toFilePath()).writeAsStringSync("String get a => 'a';");
        File(entrypoint.toFilePath())
            .writeAsStringSync("import 'dep.dart'; void main() { print(a); }");
        var output = await driver.recompileAndRecord(entrypointArg, [], []);
        expect(output!.errorCount, 0);

        File(dep.toFilePath())
            .writeAsStringSync("String get a => 'a'; String get b => 'b';");
        File(entrypoint.toFilePath()).writeAsStringSync(
          "import 'dep.dart'; void main() { print(a + b + typo); }",
        );
        output = await driver.recompileAndRecord(entrypointArg, [
          entrypointUri,
          depUri,
        ], []);
        expect(output!.errorMessage, contains("Undefined name 'typo'"));

        // The builder recompiles with a restart after a failed build, and only
        // passes the files that changed in that build.
        File(
          entrypoint.toFilePath(),
        ).writeAsStringSync("import 'dep.dart'; void main() { print(a + b); }");
        output = await driver.recompileAndRecord(
          entrypointArg,
          [entrypointUri],
          [],
          recompileRestart: true,
        );
        expect(output!.errorMessage, isNull);
        expect(output.errorCount, 0);
      },
    );

    test('recompileAndRecord successfully records and writes files', () async {
      final entrypoint = tempDir.uri.resolve('entrypoint.dart');
      File(entrypoint.toFilePath()).writeAsStringSync('void main() {}');

      final jsFESOutputPath = p.join(tempDir.path, 'entrypoint.ddc.js');
      final output = await driver.recompileAndRecord(
        '$multiRootScheme:///entrypoint.dart',
        [entrypoint],
        ['entrypoint.ddc.js'],
      );

      expect(output, isNotNull);
      expect(output!.errorCount, 0);

      final jsOutputFile = File(jsFESOutputPath);
      expect(jsOutputFile.existsSync(), isTrue);
      final content = jsOutputFile.readAsStringSync();
      expect(content, contains('function main()'));
    });

    test('recompileAndRecord passes environment options to JS', () async {
      final packageConfig = tempDir.uri.resolve(
        '.dart_tool/package_config.json',
      );
      final envServer = PersistentFrontendServer(
        sdkRoot: sdkDir,
        fileSystemRoot: tempDir.uri,
        packagesFile: packageConfig,
        environment: const {'MY_DEFINE': 'hello_world'},
      );
      await envServer.ensureStarted();
      addTearDown(envServer.shutdown);

      final envDriver = FrontendServerProxyDriver()..init(envServer);

      final entrypoint = tempDir.uri.resolve('entrypoint_env.dart');
      File(entrypoint.toFilePath()).writeAsStringSync(
        "void main() { print(const String.fromEnvironment('MY_DEFINE')); }",
      );

      final jsFESOutputPath = p.join(tempDir.path, 'entrypoint_env.ddc.js');
      final output = await envDriver.recompileAndRecord(
        '$multiRootScheme:///entrypoint_env.dart',
        [entrypoint],
        ['entrypoint_env.ddc.js'],
      );

      expect(output, isNotNull);
      expect(output!.errorCount, 0);

      final jsOutputFile = File(jsFESOutputPath);
      expect(jsOutputFile.existsSync(), isTrue);
      final content = jsOutputFile.readAsStringSync();
      expect(content, contains('hello_world'));
    });
  });
}
