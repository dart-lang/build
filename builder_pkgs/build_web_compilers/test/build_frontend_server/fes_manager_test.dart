// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build_web_compilers/src/build_frontend_server/common.dart';
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

      final portFile = File(p.join(Directory.current.path, fesWorkerPortPath));
      if (portFile.existsSync()) portFile.deleteSync();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('writes a port file and can receive messages', () async {
      final fileSystemRoot = tempDir.uri.resolve('fes_root/');
      await Directory.fromUri(fileSystemRoot).create(recursive: true);

      final process = await Process.start('dart', [
        'bin/fes_manager.dart',
        sdkDir,
        fileSystemRoot.toString(),
        p.toUri(packageConfig.path).toString(),
      ]);

      // Wait for a port file to be written.
      final portFile = File(p.join(Directory.current.path, fesWorkerPortPath));
      final content = await _waitForFile(portFile);
      final json = jsonDecode(content) as Map<String, dynamic>;
      final port = json['port'] as int?;
      final path = json['fileSystemRoot'] as String?;

      expect(port, isNotNull);
      expect(path, fileSystemRoot.toString());

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

      if (portFile.existsSync()) portFile.deleteSync();
    });

    test('updates the port file on restart', () async {
      final fileSystemRoot = tempDir.uri.resolve('fes_root/');
      await Directory.fromUri(fileSystemRoot).create(recursive: true);

      // Start first manager
      final process1 = await Process.start('dart', [
        'bin/fes_manager.dart',
        sdkDir,
        fileSystemRoot.toString(),
        p.toUri(packageConfig.path).toString(),
      ]);

      final portFile = File(p.join(Directory.current.path, fesWorkerPortPath));
      await _waitForFile(portFile);

      final content1 = await portFile.readAsString();

      // Stop first manager
      process1.kill();
      await process1.exitCode;

      // Start second manager
      final process2 = await Process.start('dart', [
        'bin/fes_manager.dart',
        sdkDir,
        fileSystemRoot.toString(),
        p.toUri(packageConfig.path).toString(),
      ]);

      // Wait for the port file to be updated with new content
      var content2 = '';
      var attempts = 0;
      while (attempts < 100) {
        content2 = await _waitForFile(portFile);
        if (content2 != content1) break;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (attempts >= 100) {
        fail('Timed out waiting for port file to change');
      }
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

      if (portFile.existsSync()) portFile.deleteSync();
    });
  });
}

Future<String> _waitForFile(File file) async {
  while (!await file.exists()) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return await file.readAsString();
}
