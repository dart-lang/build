// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build_frontend_server/build_frontend_server.dart';
import 'package:build_frontend_server/src/common.dart';
import 'package:path/path.dart' as p;

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

  // Delete the port file if it exists. Frontend Server finds a port and
  // writes it.
  final portFile = File(p.join(Directory.current.path, fesWorkerPortPath));
  if (portFile.existsSync()) portFile.deleteSync();

  final fes = await PersistentFrontendServer.start(
    sdkRoot: sdkRoot,
    fileSystemRoot: fileSystemRoot,
    packagesFile: packagesFile,
  );

  final driver = FrontendServerProxyDriver()..init(fes);
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);

  // Write port and filesystem root to file so we can create connections to it
  // or its scratch space later in the build.
  portFile.createSync(recursive: true);
  portFile.writeAsStringSync(
    jsonEncode({
      'port': server.port,
      'fileSystemRoot': fileSystemRoot.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    }),
  );

  print('Frontend Server Manager listening on port ${server.port}');

  server.listen((socket) {
    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) async {
          try {
            final request = jsonDecode(line) as Map<String, dynamic>;
            final instruction = request['instruction'] as String?;

            switch (instruction) {
              case 'COMPILE_EXPRESSION_JS':
                final result = await fes.compileExpressionToJs(
                  libraryUri: request['libraryUri'] as String,
                  scriptUri: request['scriptUri'] as String,
                  line: request['line'] as int,
                  column: request['column'] as int,
                  jsModules: Map<String, String>.from(
                    request['jsModules'] as Map,
                  ),
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
                    'sources':
                        result?.sources.map((u) => u.toString()).toList(),
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
                final filesToWrite =
                    (request['filesToWrite'] as List).cast<String>();

                final result = await driver.recompileAndRecord(
                  entrypoint,
                  invalidatedFiles,
                  filesToWrite,
                );

                socket.writeln(
                  jsonEncode({
                    'outputFilename': result?.outputFilename,
                    'errorCount': result?.errorCount,
                    'sources':
                        result?.sources.map((u) => u.toString()).toList(),
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
        });
  });

  // Handle shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    await fes.shutdown();
    if (portFile.existsSync()) portFile.deleteSync();
    exit(0);
  });
}
