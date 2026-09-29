// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build_web_compilers/src/build_frontend_server/fes_server_info.dart';
import 'package:build_web_compilers/src/common.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('FES Manager', () {
    late Directory tempDir;
    late File packageConfig;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fes-manager-test');
      packageConfig = File(
        p.join(tempDir.path, '.dart_tool', 'package_config.json'),
      );
      packageConfig.createSync(recursive: true);
      packageConfig.writeAsStringSync(
        jsonEncode({'configVersion': 2, 'packages': <String>[]}),
      );
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('writes a config file and can receive messages', () async {
      final fileSystemRoot = tempDir.uri.resolve('fes_root/');
      await Directory.fromUri(fileSystemRoot).create(recursive: true);

      final scriptPath = _resolveFesManagerScriptPath();
      final process = await Process.start('dart', [
        scriptPath,
        sdkDir,
        fileSystemRoot.toString(),
        p.toUri(packageConfig.path).toString(),
      ], workingDirectory: tempDir.path);
      process.stdout
          .transform(utf8.decoder)
          .listen((line) => print('Test 1 stdout: $line'));
      process.stderr
          .transform(utf8.decoder)
          .listen((line) => print('Test 1 stderr: $line'));

      // Wait for a config file to be written.
      final configFile = File(p.join(tempDir.path, fesManagerConfigPath));
      await _waitForFileContentChanges(configFile);
      final serverInfo = FesServerInfo.fromFile(configFile);
      expect(serverInfo, isNotNull);
      expect(serverInfo!.port, isPositive);
      expect(serverInfo.token, isNotEmpty);

      // Connect to the FES socket, authenticate, send a request, and verify
      // response.
      final connection = await _connectAndAuth(
        serverInfo.port,
        serverInfo.token,
      );
      final socket = connection.socket;
      socket.writeln(
        jsonEncode({'instruction': 'READ_OUTPUT_FILE', 'path': 'non_existent'}),
      );
      final responseLine = await connection.socketLines.first;
      final response = jsonDecode(responseLine) as Map<String, dynamic>;
      expect(response.containsKey('error'), isTrue);

      await socket.close();
      process.kill();
      await process.exitCode;
    });

    test('passes environment defines to Frontend Server', () async {
      final fileSystemRoot = tempDir.uri.resolve('fes_root/');
      await Directory.fromUri(fileSystemRoot).create(recursive: true);

      final mainFile = File(
        p.join(tempDir.path, 'fes_root', 'web', 'main.dart'),
      );
      mainFile.createSync(recursive: true);
      mainFile.writeAsStringSync(
        "void main() { print(const String.fromEnvironment('MY_DEFINE')); }",
      );

      final scriptPath = _resolveFesManagerScriptPath();
      final process = await Process.start('dart', [
        scriptPath,
        sdkDir,
        fileSystemRoot.toString(),
        p.toUri(packageConfig.path).toString(),
        '-DMY_DEFINE=manager_hello',
      ], workingDirectory: tempDir.path);

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => print('Manager defines test stdout: $line'));

      final configFile = File(p.join(tempDir.path, fesManagerConfigPath));
      await _waitForFileContentChanges(configFile);
      final serverInfo = FesServerInfo.fromFile(configFile);

      expect(serverInfo, isNotNull);

      final connection = await _connectAndAuth(
        serverInfo!.port,
        serverInfo.token,
      );
      final socket = connection.socket;
      final socketLines = connection.socketLines;

      socket.writeln(
        jsonEncode({
          'instruction': 'COMPILE',
          'entrypoint': 'org-dartlang-app:///web/main.dart',
        }),
      );
      var responseLine = await socketLines.first;
      var response = jsonDecode(responseLine) as Map<String, dynamic>;
      expect(response['errorCount'], 0);

      socket.writeln(
        jsonEncode({
          'instruction': 'READ_OUTPUT_FILE',
          'path': 'test_scratch_space/web/main.ddc.js',
        }),
      );
      responseLine = await socketLines.first;
      response = jsonDecode(responseLine) as Map<String, dynamic>;
      expect(response.containsKey('content'), isTrue);
      expect(response['content'], contains('manager_hello'));

      await socket.close();
      process.kill();
      await process.exitCode;
    });

    test('updates the config file on restart', () async {
      final fileSystemRoot = tempDir.uri.resolve('fes_root/');
      await Directory.fromUri(fileSystemRoot).create(recursive: true);

      // Start first manager
      final scriptPath = _resolveFesManagerScriptPath();
      final process1 = await Process.start('dart', [
        scriptPath,
        sdkDir,
        fileSystemRoot.toString(),
        p.toUri(packageConfig.path).toString(),
      ], workingDirectory: tempDir.path);

      final configFile = File(p.join(tempDir.path, fesManagerConfigPath));
      await _waitForFileContentChanges(configFile);

      final content1 = await configFile.readAsString();

      // Stop first manager
      process1.kill();
      await process1.exitCode;

      // Start second manager
      final process2 = await Process.start('dart', [
        scriptPath,
        sdkDir,
        fileSystemRoot.toString(),
        p.toUri(packageConfig.path).toString(),
      ], workingDirectory: tempDir.path);

      // Wait for the config file to be updated with new content
      await _waitForFileContentChanges(configFile, previousContent: content1);
      final serverInfo2 = FesServerInfo.fromFile(configFile);
      expect(serverInfo2, isNotNull);

      // Connect to the new socket and send a request.
      final connection = await _connectAndAuth(
        serverInfo2!.port,
        serverInfo2.token,
      );
      final socket = connection.socket;
      socket.writeln(
        jsonEncode({'instruction': 'READ_OUTPUT_FILE', 'path': 'non_existent'}),
      );
      final responseLine = await connection.socketLines.first;

      final response = jsonDecode(responseLine) as Map<String, dynamic>;
      expect(response.containsKey('error'), isTrue);

      await socket.close();
      process2.kill();
      await process2.exitCode;
    });

    group('Token authorization', () {
      late Directory authTempDir;
      late File authPackageConfig;
      late Process authProcess;
      late FesServerInfo authServerInfo;

      setUp(() async {
        authTempDir = await Directory.systemTemp.createTemp('fes-auth-test');
        authPackageConfig = File(
          p.join(authTempDir.path, '.dart_tool', 'package_config.json'),
        );
        authPackageConfig.createSync(recursive: true);
        authPackageConfig.writeAsStringSync(
          jsonEncode({'configVersion': 2, 'packages': <String>[]}),
        );

        final fileSystemRoot = authTempDir.uri.resolve('fes_root/');
        await Directory.fromUri(fileSystemRoot).create(recursive: true);

        final scriptPath = _resolveFesManagerScriptPath();
        authProcess = await Process.start('dart', [
          scriptPath,
          sdkDir,
          fileSystemRoot.toString(),
          p.toUri(authPackageConfig.path).toString(),
        ], workingDirectory: authTempDir.path);

        final configFile = File(p.join(authTempDir.path, fesManagerConfigPath));
        await _waitForFileContentChanges(configFile);
        authServerInfo = FesServerInfo.fromFile(configFile)!;
      });

      tearDown(() async {
        authProcess.kill();
        await authProcess.exitCode;
        await authTempDir.delete(recursive: true);
      });

      test('rejects connection with invalid token', () async {
        final socket = await Socket.connect(
          InternetAddress.loopbackIPv4,
          authServerInfo.port,
        );
        final socketLines = socket
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .asBroadcastStream();

        final authResponseFuture = socketLines.first;
        socket.writeln(jsonEncode({'token': 'wrong_token'}));
        await socket.flush();

        final responseLine = await authResponseFuture;
        final response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['error'], 'Unauthorized');

        // Verify that the socket was closed by the server
        expect(socketLines.isEmpty, completion(isTrue));
      });

      test('rejects connection without token handshake', () async {
        final socket = await Socket.connect(
          InternetAddress.loopbackIPv4,
          authServerInfo.port,
        );
        final socketLines = socket
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .asBroadcastStream();

        final authResponseFuture = socketLines.first;
        socket.writeln(
          jsonEncode({'instruction': 'COMPILE', 'entrypoint': 'test.dart'}),
        );
        await socket.flush();

        final responseLine = await authResponseFuture;
        final response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['error'], 'Unauthorized');

        // Verify that the socket was closed by the server
        expect(socketLines.isEmpty, completion(isTrue));
      });

      test('config directory is user-private', () {
        final configFile = File(p.join(authTempDir.path, fesManagerConfigPath));
        final configDir = configFile.parent;

        if (Platform.isWindows) {
          final result = Process.runSync('powershell', [
            '-NoProfile',
            '-NonInteractive',
            '-Command',
            '(Get-Acl "${configDir.path}").AreAccessRulesProtected',
          ]);
          expect(result.exitCode, 0);
          expect(result.stdout.toString().trim(), 'True');
        } else {
          final dirStat = configDir.statSync();
          final dirMode = dirStat.mode & (7 * 8 * 8 + 7 * 8 + 7);
          expect(dirMode, 7 * 8 * 8);
        }
      });

      test(
        'throws version skew error when reading config file without token',
        () {
          final legacyConfigFile = File(
            p.join(authTempDir.path, 'legacy_config.json'),
          )..writeAsStringSync(jsonEncode({'port': 12345}));

          expect(
            () => FesServerInfo.fromFile(legacyConfigFile),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                allOf(
                  contains('incompatible version of build_web_compilers'),
                  contains('build_web_compilers >=4.8.11'),
                ),
              ),
            ),
          );
        },
      );
    });

    group('FES Manager API', () {
      late Directory testTempDir;
      late File testPackageConfig;
      late Process testProcess;
      late Socket testSocket;
      late Stream<String> testSocketLines;
      late File testMainFile;

      setUpAll(() async {
        testTempDir = await Directory.systemTemp.createTemp(
          'fes-manager-api-test',
        );
        testPackageConfig = File(
          p.join(testTempDir.path, '.dart_tool', 'package_config.json'),
        );
        testPackageConfig.createSync(recursive: true);
        testPackageConfig.writeAsStringSync(
          jsonEncode({'configVersion': 2, 'packages': <String>[]}),
        );

        final fileSystemRoot = testTempDir.uri.resolve('fes_root/');
        await Directory.fromUri(fileSystemRoot).create(recursive: true);

        testMainFile = File(
          p.join(testTempDir.path, 'fes_root', 'web', 'main.dart'),
        );
        testMainFile.createSync(recursive: true);
        testMainFile.writeAsStringSync('void main() { print("hello"); }');

        final scriptPath = _resolveFesManagerScriptPath();
        testProcess = await Process.start('dart', [
          scriptPath,
          sdkDir,
          fileSystemRoot.toString(),
          p.toUri(testPackageConfig.path).toString(),
        ], workingDirectory: testTempDir.path);

        testProcess.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) => print('FES Manager stdout: $line'));
        testProcess.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) => print('FES Manager stderr: $line'));

        final configFile = File(p.join(testTempDir.path, fesManagerConfigPath));
        await _waitForFileContentChanges(configFile);
        final serverInfo = FesServerInfo.fromFile(configFile)!;
        final connection = await _connectAndAuth(
          serverInfo.port,
          serverInfo.token,
        );
        testSocket = connection.socket;
        testSocketLines = connection.socketLines;

        // Perform an initial compile to ensure the Frontend Server is warmed up
        // and initialized for subsequent expression compilation and metadata
        // merging tests.
        testSocket.writeln(
          jsonEncode({
            'instruction': 'COMPILE',
            'entrypoint': 'org-dartlang-app:///web/main.dart',
          }),
        );
        final responseLine = await testSocketLines.first;
        final response = jsonDecode(responseLine) as Map<String, dynamic>;
        if (response['errorCount'] != 0) {
          throw StateError('Failed to run initial compile: $response');
        }
      });

      tearDownAll(() async {
        await testSocket.close();
        testProcess.kill();
        await testProcess.exitCode;
        await testTempDir.delete(recursive: true);
      });

      test('supports COMPILE instruction', () async {
        testSocket.writeln(
          jsonEncode({
            'instruction': 'COMPILE',
            'entrypoint': 'org-dartlang-app:///web/main.dart',
          }),
        );
        final responseLine = await testSocketLines.first;
        final response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['errorCount'], 0);
        expect(response['outputFilename'], endsWith('output.dill'));
      });

      test('supports MERGE_ALL_METADATA instruction', () async {
        testSocket.writeln(jsonEncode({'instruction': 'MERGE_ALL_METADATA'}));
        final responseLine = await testSocketLines.first;
        final response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response.containsKey('content'), isTrue);
      });

      test('supports COMPILE_EXPRESSION_JS instruction', () async {
        testSocket.writeln(
          jsonEncode({
            'instruction': 'COMPILE_EXPRESSION_JS',
            'libraryUri': 'org-dartlang-app:///web/main.dart',
            'scriptUri': 'org-dartlang-app:///web/main.dart',
            'line': 1,
            'column': 1,
            'jsModules': <String, String>{},
            'jsFrameValues': <String, String>{},
            'moduleName': 'web/main',
            'expression': '1 + 1',
          }),
        );
        final responseLine = await testSocketLines.first;
        final response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['errorCount'], 0);
        expect(response.containsKey('expressionData'), isTrue);
      });

      test('supports RECOMPILE_AND_RECORD instruction (success)', () async {
        testMainFile.writeAsStringSync('void main() { print("recompiled!"); }');
        testSocket.writeln(
          jsonEncode({
            'instruction': 'RECOMPILE_AND_RECORD',
            'entrypoint': 'org-dartlang-app:///web/main.dart',
            'filesToWrite': ['web/main.ddc.js'],
            'invalidatedFiles': ['org-dartlang-app:///web/main.dart'],
          }),
        );
        final responseLine = await testSocketLines.first;
        final response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['errorCount'], 0);
      });

      test('supports RECOMPILE_AND_RECORD instruction (bad recompile then '
          'restart)', () async {
        // 1. Initial full compile
        testMainFile.writeAsStringSync(
          'class A { final int x; A(this.x); } '
          'void main() { print("initial"); }',
        );
        testSocket.writeln(
          jsonEncode({
            'instruction': 'RECOMPILE_AND_RECORD',
            'entrypoint': 'org-dartlang-app:///web/main.dart',
            'filesToWrite': ['web/main.ddc.js'],
            'invalidatedFiles': ['org-dartlang-app:///web/main.dart'],
          }),
        );
        var responseLine = await testSocketLines.first;
        var response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['errorCount'], 0);

        // 2. Good recompile
        testMainFile.writeAsStringSync(
          'class A { final int x; A(this.x); } '
          'void main() { print("good"); }',
        );
        testSocket.writeln(
          jsonEncode({
            'instruction': 'RECOMPILE_AND_RECORD',
            'entrypoint': 'org-dartlang-app:///web/main.dart',
            'filesToWrite': ['web/main.ddc.js'],
            'invalidatedFiles': ['org-dartlang-app:///web/main.dart'],
          }),
        );
        responseLine = await testSocketLines.first;
        response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['errorCount'], 0);

        // 3. Bad recompile (invalid hot reload edit: A becomes const)
        testMainFile.writeAsStringSync(
          'class A { final int x; const A(this.x); } '
          'void main() { print("bad"); }',
        );
        testSocket.writeln(
          jsonEncode({
            'instruction': 'RECOMPILE_AND_RECORD',
            'entrypoint': 'org-dartlang-app:///web/main.dart',
            'filesToWrite': ['web/main.ddc.js'],
            'invalidatedFiles': ['org-dartlang-app:///web/main.dart'],
          }),
        );
        responseLine = await testSocketLines.first;
        response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['errorCount'], 0);

        // 4. Restart with no code changes that ends in success
        testSocket.writeln(
          jsonEncode({
            'instruction': 'RECOMPILE_AND_RECORD',
            'entrypoint': 'org-dartlang-app:///web/main.dart',
            'filesToWrite': ['web/main.ddc.js'],
            'invalidatedFiles': <String>[],
            'recompileRestart': true,
          }),
        );
        responseLine = await testSocketLines.first;
        response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['errorCount'], 0);

        // 5. Good recompile
        testMainFile.writeAsStringSync(
          'class A { final int x; const A(this.x); } '
          'void main() { print("another good"); }',
        );
        testSocket.writeln(
          jsonEncode({
            'instruction': 'RECOMPILE_AND_RECORD',
            'entrypoint': 'org-dartlang-app:///web/main.dart',
            'filesToWrite': ['web/main.ddc.js'],
            'invalidatedFiles': ['org-dartlang-app:///web/main.dart'],
          }),
        );
        responseLine = await testSocketLines.first;
        response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['errorCount'], 0);
      });

      test('throws an error when recompiling a different entrypoint '
          'without restart', () async {
        testMainFile.writeAsStringSync('void main() { print("hello"); }');
        testSocket.writeln(
          jsonEncode({
            'instruction': 'COMPILE',
            'entrypoint': 'org-dartlang-app:///web/main.dart',
          }),
        );
        var responseLine = await testSocketLines.first;
        var response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['errorCount'], 0);

        // Compile a different entrypoint.
        testSocket.writeln(
          jsonEncode({
            'instruction': 'COMPILE',
            'entrypoint': 'org-dartlang-app:///web/other.dart',
          }),
        );
        responseLine = await testSocketLines.first;
        response = jsonDecode(responseLine) as Map<String, dynamic>;

        expect(response.containsKey('error'), isTrue);
        expect(
          response['error'],
          contains('Cannot compile a different entrypoint'),
        );
      });

      test('READ_OUTPUT_FILE handles failures and recovers', () async {
        // 1. Initial valid compilation
        testMainFile.writeAsStringSync('void main() { print("hello"); }');
        testSocket.writeln(
          jsonEncode({
            'instruction': 'RECOMPILE_AND_RECORD',
            'entrypoint': 'org-dartlang-app:///web/main.dart',
            'filesToWrite': ['web/main.ddc.js'],
            'invalidatedFiles': ['org-dartlang-app:///web/main.dart'],
          }),
        );
        var responseLine = await testSocketLines.first;
        var response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['errorCount'], 0);

        testSocket.writeln(
          jsonEncode({
            'instruction': 'READ_OUTPUT_FILE',
            'path': 'test_scratch_space/web/main.ddc.js',
          }),
        );
        responseLine = await testSocketLines.first;
        response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response.containsKey('content'), isTrue);
        expect(response['content'], contains('print("hello")'));

        // 2. Write invalid file and attempt recompile (syntax error)
        testMainFile.writeAsStringSync('void main() { print("hello"');
        testSocket.writeln(
          jsonEncode({
            'instruction': 'RECOMPILE_AND_RECORD',
            'entrypoint': 'org-dartlang-app:///web/main.dart',
            'filesToWrite': ['web/main.ddc.js'],
            'invalidatedFiles': [
              'org-dartlang-app:///web/main.dart',
              'org-dartlang-app:///web/dummy1.dart',
            ],
          }),
        );
        responseLine = await testSocketLines.first;
        response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['errorCount'], greaterThan(0));

        // 3. Fix the invalid file and recover
        testMainFile.writeAsStringSync('void main() { print("hello fixed"); }');
        testSocket.writeln(
          jsonEncode({
            'instruction': 'RECOMPILE_AND_RECORD',
            'entrypoint': 'org-dartlang-app:///web/main.dart',
            'filesToWrite': ['web/main.ddc.js'],
            'invalidatedFiles': [
              'org-dartlang-app:///web/main.dart',
              'org-dartlang-app:///web/dummy2.dart',
            ],
          }),
        );
        responseLine = await testSocketLines.first;
        response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response['errorCount'], 0);

        testSocket.writeln(
          jsonEncode({
            'instruction': 'READ_OUTPUT_FILE',
            'path': 'test_scratch_space/web/main.ddc.js',
          }),
        );
        responseLine = await testSocketLines.first;
        response = jsonDecode(responseLine) as Map<String, dynamic>;
        expect(response.containsKey('content'), isTrue);
        expect(response['content'], contains('hello fixed'));
      });
    });
  });
}

Future<({Socket socket, Stream<String> socketLines})> _connectAndAuth(
  int port,
  String token,
) async {
  final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
  final socketLines = socket
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .asBroadcastStream();

  final authFuture = socketLines.first;
  socket.writeln(jsonEncode({'token': token}));
  await socket.flush();
  final authResponseLine = await authFuture;
  final authResponse = jsonDecode(authResponseLine) as Map<String, dynamic>;
  expect(authResponse['status'], 'AUTHENTICATED');
  return (socket: socket, socketLines: socketLines);
}

Future<String> _waitForFileContentChanges(
  File file, {
  String? previousContent,
}) async {
  while (true) {
    try {
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty && content != previousContent) {
          // Verify that [content] is valid JSON
          jsonDecode(content);
          return content;
        }
      }
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

String _resolveFesManagerScriptPath() {
  final localScript = p.absolute('bin/fes_manager.dart');
  if (File(localScript).existsSync()) return localScript;
  return p.absolute('builder_pkgs/build_web_compilers/bin/fes_manager.dart');
}
