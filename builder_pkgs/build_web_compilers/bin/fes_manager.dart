// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build_web_compilers/src/build_frontend_server/frontend_server_driver.dart';
import 'package:build_web_compilers/src/common.dart';
import 'package:path/path.dart' as p;

/// Starts a persistent Frontend Server instance and exposes it via a socket.
///
/// This avoids the overhead of restarting the Frontend Server for every
/// compile or expression eval request. Communicates with JSON-encoded
/// instructions on a port written to [fesManagerConfigPath].
///
/// This is only meant to be used by web builders, not direct use.
void main(List<String> args) async {
  if (args.length < 3) {
    print('Usage: fes_manager <sdkRoot> <fileSystemRoot> <packagesFile>');
    exit(1);
  }
  final sdkRoot = args[0];
  var fileSystemRoot = Uri.parse(args[1]);
  if (!fileSystemRoot.path.endsWith('/')) {
    fileSystemRoot = fileSystemRoot.replace(path: '${fileSystemRoot.path}/');
  }

  final packagesFile = Uri.parse(args[2]);

  // Delete stale config files if they exist. This manager will spin up a FES
  // instance and write its new config.
  final configFile = File(p.join(Directory.current.path, fesManagerConfigPath));
  if (configFile.existsSync()) configFile.deleteSync();

  final fes = await PersistentFrontendServer.start(
    sdkRoot: sdkRoot,
    fileSystemRoot: fileSystemRoot,
    packagesFile: packagesFile,
  );

  final driver = FrontendServerProxyDriver()..init(fes);
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);

  // Write config to file so we can create connections to it later in the build.
  configFile.createSync(recursive: true);
  configFile.writeAsStringSync(jsonEncode({'port': server.port}));

  print('Frontend Server Manager listening on port ${server.port}');

  final activeSockets = <Socket>{};
  server.listen((socket) {
    activeSockets.add(socket);
    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) => _handleRequest(line, socket, fes, driver),
          onDone: () => activeSockets.remove(socket),
          onError: (_) => activeSockets.remove(socket),
        );
  });

  // Handle shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    await server.close();
    for (final socket in activeSockets) {
      await socket.close();
    }
    await fes.shutdown();
    if (configFile.existsSync()) configFile.deleteSync();
    exit(0);
  });
}

/// Handles custom JSON instructions and delegates them to [fes] or [driver].
///
/// The result is serialized and written back to [socket].
Future<void> _handleRequest(
  String jsonLine,
  Socket socket,
  PersistentFrontendServer fes,
  FrontendServerProxyDriver driver,
) async {
  try {
    final request = jsonDecode(jsonLine) as Map<String, dynamic>;
    final instruction = request['instruction'] as String?;

    switch (instruction) {
      case 'COMPILE_EXPRESSION_JS':
        final result = await fes.compileExpressionToJs(
          libraryUri: request['libraryUri'] as String,
          scriptUri: request['scriptUri'] as String,
          line: request['line'] as int,
          column: request['column'] as int,
          jsModules: Map<String, String>.from(request['jsModules'] as Map),
          jsFrameValues: Map<String, String>.from(
            request['jsFrameValues'] as Map,
          ),
          moduleName: request['moduleName'] as String,
          expression: request['expression'] as String,
        );

        final bytes = result?.expressionData;
        final expressionDataString =
            bytes != null ? base64.encode(bytes) : null;

        socket.writeln(
          jsonEncode({
            'expressionData': expressionDataString,
            'errorCount': result?.errorCount,
            'errorMessage': result?.errorMessage,
          }),
        );
        break;
      case 'COMPILE':
        final entrypoint = request['entrypoint'] as String;
        final result = await fes.compile(entrypoint);
        socket.writeln(
          jsonEncode({
            'outputFilename': result?.outputFilename,
            'errorCount': result?.errorCount,
            'sources': result?.sources.map((u) => u.toString()).toList(),
          }),
        );
        break;
      case 'RECOMPILE_AND_RECORD':
        final entrypoint = request['entrypoint'] as String;
        final invalidatedFiles =
            (request['invalidatedFiles'] as List)
                .cast<String>()
                .map(Uri.parse)
                .toList();
        final filesToWrite = (request['filesToWrite'] as List).cast<String>();

        final result = await driver.recompileAndRecord(
          entrypoint,
          invalidatedFiles,
          filesToWrite,
        );

        socket.writeln(
          jsonEncode({
            'outputFilename': result?.outputFilename,
            'errorCount': result?.errorCount,
            'sources': result?.sources.map((u) => u.toString()).toList(),
            'errorMessage': result?.errorMessage,
          }),
        );
        break;
      case 'READ_OUTPUT_FILE':
        final path = request['path'] as String;
        final content = await fes.readOutputFile(path);
        socket.writeln(jsonEncode({'content': content}));
        break;
      default:
        socket.writeln(
          jsonEncode({'error': 'Unknown instruction: $instruction'}),
        );
    }
  } catch (e) {
    socket.writeln(jsonEncode({'error': e.toString()}));
  }
}
