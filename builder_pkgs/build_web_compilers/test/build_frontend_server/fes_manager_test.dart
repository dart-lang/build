// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

      final scriptPath = p.absolute('bin/fes_manager.dart');
      final process = await Process.start('dart', [
        scriptPath,
        sdkDir,
        fileSystemRoot.toString(),
        p.toUri(packageConfig.path).toString(),
      ], workingDirectory: tempDir.path);

      // Wait for a config file to be written.
      final configFile = File(p.join(tempDir.path, fesManagerConfigPath));
      final content = await _waitForFileContentChanges(configFile);
      final json = jsonDecode(content) as Map<String, dynamic>;
      final port = json['port'] as int?;

      expect(port, isNotNull);

      // Connect to the FES socket, send a request, and verify its response.
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, port!);
      socket.writeln(
        jsonEncode({'instruction': 'READ_OUTPUT_FILE', 'path': 'non_existent'}),
      );
      final responseLine =
          await socket
              .cast<List<int>>()
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .first;
      final response = jsonDecode(responseLine) as Map<String, dynamic>;
      expect(response.containsKey('error'), isTrue);

      await socket.close();
      process.kill();
      await process.exitCode;
    });

    test('updates the config file on restart', () async {
      final fileSystemRoot = tempDir.uri.resolve('fes_root/');
      await Directory.fromUri(fileSystemRoot).create(recursive: true);

      // Start first manager
      final scriptPath = p.absolute('bin/fes_manager.dart');
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
      final content2 = await _waitForFileContentChanges(
        configFile,
        previousContent: content1,
      );
      final json2 = jsonDecode(content2) as Map<String, dynamic>;
      final port2 = json2['port'] as int;

      // Connect to the new socket and send a request.
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, port2);
      socket.writeln(
        jsonEncode({'instruction': 'READ_OUTPUT_FILE', 'path': 'non_existent'}),
      );
      final responseLine =
          await socket
              .cast<List<int>>()
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .first;

      final response = jsonDecode(responseLine) as Map<String, dynamic>;
      expect(response.containsKey('error'), isTrue);

      await socket.close();
      process2.kill();
      await process2.exitCode;
    });
  });
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
