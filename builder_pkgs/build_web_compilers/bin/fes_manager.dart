// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build_web_compilers/src/build_frontend_server/frontend_server_driver.dart';
import 'package:build_web_compilers/src/build_frontend_server/package_config.dart';
import 'package:build_web_compilers/src/common.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

/// Starts a persistent Frontend Server instance and exposes it via a socket.
///
/// Communicates with JSON-encoded instructions via a socket listening on a port
/// written in [fesManagerConfigPath].
///
/// This is only meant to be used by web builders, not direct use.
void main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.message}');
  });

  if (args.length < 3) {
    print(
      'Usage: fes_manager <sdkRoot> <fileSystemRoot> <packagesFile> '
      '[-Dkey=value ...]',
    );
    exit(1);
  }
  final sdkRoot = args[0];
  var fileSystemRoot = Uri.parse(args[1]);
  if (!fileSystemRoot.path.endsWith('/')) {
    fileSystemRoot = fileSystemRoot.replace(path: '${fileSystemRoot.path}/');
  }

  final packagesFile = Uri.parse(args[2]);

  // Parse environment variables.
  final environment = <String, String>{};
  for (var i = 3; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('-D')) {
      final parts = arg.substring(2).split('=');
      if (parts.length >= 2) {
        final key = parts[0];
        final value = parts.sublist(1).join('=');
        environment[key] = value;
      }
    }
  }

  // Delete stale config files if they exist. This manager will spin up a FES
  // instance and write its new config.
  final configFile = File(p.join(Directory.current.path, fesManagerConfigPath));
  if (configFile.existsSync()) configFile.deleteSync();

  final manager = await FesManager.start(
    sdkRoot: sdkRoot,
    fileSystemRoot: fileSystemRoot,
    packagesFile: packagesFile,
    environment: environment,
  );

  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);

  // Write the Frontend Server's config to file so we can create connections to
  // it later in the build.
  final tempConfigFile = File('${configFile.path}.tmp');
  tempConfigFile.createSync(recursive: true);
  tempConfigFile.writeAsStringSync(jsonEncode({'port': server.port}));
  tempConfigFile.renameSync(configFile.path);

  print('Frontend Server Manager listening on port ${server.port}');

  final activeSockets = <Socket>{};
  server.listen((socket) {
    activeSockets.add(socket);
    socket.done.catchError((Object error) {
      // Ignore 'SocketException: Connection reset by peer' exceptions.
    });
    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) => manager.handleRequest(line, socket),
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
    await manager.shutdown();
    if (configFile.existsSync()) configFile.deleteSync();
    exit(0);
  });
}

/// Manages a persistent Frontend Server and driver instance exposed via a local
/// socket.
///
/// Exposes the following socket instructions:
/// * COMPILE and RECOMPILE_AND_RECORD for builds and hot reloads/restarts.
/// * COMPILE_EXPRESSION_JS for expression evaluation.
/// * MERGE_ALL_METADATA for aggregating library metadata (required by DWDS).
/// * READ_OUTPUT_FILE for serving compiled artifacts, such as JS, source
///   maps, and metadata.
class FesManager {
  final PersistentFrontendServer fes;
  final FrontendServerProxyDriver driver;
  final PackageConfig packageConfig;
  final Pool _pool = Pool(1);
  String? _cachedEntrypoint;

  FesManager._({
    required this.fes,
    required this.driver,
    required this.packageConfig,
  });

  static Future<FesManager> start({
    required String sdkRoot,
    required Uri fileSystemRoot,
    required Uri packagesFile,
    Map<String, String> environment = const {},
  }) async {
    final fes = await PersistentFrontendServer.start(
      sdkRoot: sdkRoot,
      fileSystemRoot: fileSystemRoot,
      packagesFile: packagesFile,
      environment: environment,
    );
    final driver = FrontendServerProxyDriver()..init(fes);
    final packageConfig = await PackageConfig.load(File.fromUri(packagesFile));
    return FesManager._(fes: fes, driver: driver, packageConfig: packageConfig);
  }

  void _verifyEntrypoint(String? entrypoint) {
    if (entrypoint == null) return;
    if (_cachedEntrypoint != null && entrypoint != _cachedEntrypoint) {
      throw StateError(
        'Cannot compile a different entrypoint: '
        'expected $_cachedEntrypoint but got $entrypoint.',
      );
    }
    _cachedEntrypoint ??= entrypoint;
  }

  /// Delegates custom JSON instructions on [jsonLine] to [fes] and/or [driver].
  ///
  /// The result is serialized and written back to [socket].
  Future<void> handleRequest(String jsonLine, Socket socket) async {
    try {
      final request = jsonDecode(jsonLine) as Map<String, dynamic>;
      final instruction = request['instruction'] as String?;
      final entrypoint = request['entrypoint'] as String?;
      _verifyEntrypoint(entrypoint);

      await _pool.withResource(() async {
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
            final expressionDataString = bytes != null
                ? base64.encode(bytes)
                : null;

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
            final result = await driver.recompileAndRecord(entrypoint, [], []);
            socket.writeln(
              jsonEncode({
                'outputFilename': result?.outputFilename,
                'errorCount': result?.errorCount,
                'sources': result?.sources.map((u) => u.toString()).toList(),
                'errorMessage': result?.errorMessage,
              }),
            );
            break;
          case 'RECOMPILE_AND_RECORD':
            await _handleRecompileAndRecord(request, socket);
            break;
          case 'MERGE_ALL_METADATA':
            _handleMergeAllMetadata(socket);
            break;
          case 'READ_OUTPUT_FILE':
            await _handleReadOutputFile(request, socket);
            break;
          default:
            socket.writeln(
              jsonEncode({'error': 'Unknown instruction: $instruction'}),
            );
        }
      });
      await socket.flush().catchError((_) {});
    } catch (e, st) {
      print('FES_MANAGER_EXCEPTION in REQUEST: $e\n$st');
      try {
        socket.writeln(jsonEncode({'error': e.toString()}));
      } catch (_) {
        // Ignore 'SocketException: Connection reset by peer' exceptions.
      }
    }
  }

  /// Handles RECOMPILE_AND_RECORD requests.
  ///
  /// Expected [request] fields:
  /// * `entrypoint`: String (the target entrypoint URI)
  /// * `filesToWrite`: List[String] (assets to record/write back)
  /// * `invalidatedFiles`: List[String] (URIs of modified files)
  /// * `recompileRestart`: bool (whether to trigger a hot restart)
  ///
  /// Copies newly invalidated source files from the package root into FES
  /// scratch space and delegates compilation to the FES driver.
  /// Example invalidated file -> ensuing scratch space write:
  /// - package:$rootPackage/lib/library.dart ->
  ///     $scratchSpace/packages/$rootPackage/library.dart
  /// - org-dartlang-app:///web/main.dart -> $scratchSpace/web/main.dart
  Future<void> _handleRecompileAndRecord(
    Map<String, dynamic> request,
    Socket socket,
  ) async {
    final entrypoint = request['entrypoint'] as String;
    final recompileRestart = request['recompileRestart'] as bool? ?? false;
    // Rename the build system's '.ddc.js' extensions to FES's '.dart.lib.js'.
    final filesToWrite = (request['filesToWrite'] as List)
        .cast<String>()
        .map((f) => f.replaceAll(jsModuleExtension, fesJsExtension))
        .toList();
    final isColdStart = fes.fileSystem.files.isEmpty;
    final invalidatedFiles = (request['invalidatedFiles'] as List)
        .cast<String>()
        .map(Uri.parse)
        .map(_translateBuildRunnerUriToFrontendServerUri)
        .toList();
    if (isColdStart) {
      invalidatedFiles.add(Uri.parse(entrypoint));
    }

    try {
      final result = await driver.recompileAndRecord(
        entrypoint,
        invalidatedFiles,
        filesToWrite,
        recompileRestart: recompileRestart,
      );

      socket.writeln(
        jsonEncode({
          'outputFilename': result?.outputFilename,
          'errorCount': result?.errorCount,
          'sources': result?.sources.map((u) => u.toString()).toList(),
          'errorMessage': result?.errorMessage,
        }),
      );
    } catch (e, st) {
      print('FES_MANAGER_EXCEPTION in RECOMPILE: $e\n$st');
      socket.writeln(jsonEncode({'error': e.toString()}));
    }
  }

  /// Handles MERGE_ALL_METADATA requests.
  ///
  /// DWDS requests merged metadata during hot reload.
  void _handleMergeAllMetadata(Socket socket) {
    final contents = <String>[];
    for (final key in fes.fileSystem.metadata.keys) {
      final data = fes.fileSystem.metadata[key];
      if (data != null) {
        contents.add(utf8.decode(data));
      }
    }
    final mergedContent = contents.join('\n');
    socket.writeln(jsonEncode({'content': mergedContent}));
  }

  /// Handles the READ_OUTPUT_FILE requests.
  ///
  /// Triggers a compile/recompile if a valid entrypoint is provided
  /// (i.e., it's not a test) and there are modified files.
  ///
  /// Expected [request] fields:
  /// * `path`: String (target asset filepath to read)
  /// * `entrypoint`: String? (optional entrypoint URI for cold-start compiling)
  /// * `invalidatedFiles`: List[String]? (optional list of modified file URIs)
  Future<void> _handleReadOutputFile(
    Map<String, dynamic> request,
    Socket socket,
  ) async {
    final path = request['path'] as String;

    // Look up the requested file in the memory filesystem caches.
    String? content;
    final scratchSpacePrefix = testScratchSpacePathPrefix;
    final index = path.indexOf(scratchSpacePrefix);
    if (index != -1) {
      final relativeKey = fesToAssetPath(
        path.substring(index + scratchSpacePrefix.length),
        rootPackage: fes.fileSystem.rootPackageName,
      );
      final fesRelativeKey = relativeKey.replaceAll(jsModuleExtension, fesJsExtension);
      final memoryData =
          fes.fileSystem.files[relativeKey] ??
          fes.fileSystem.sourcemaps[relativeKey] ??
          fes.fileSystem.metadata[relativeKey] ??
          fes.fileSystem.files[fesRelativeKey] ??
          fes.fileSystem.sourcemaps[fesRelativeKey] ??
          fes.fileSystem.metadata[fesRelativeKey];
      if (memoryData != null) {
        content = utf8.decode(memoryData);
        print('FES_MANAGER_SUCCESS: read ${content.length} bytes for $path (found via $relativeKey or $fesRelativeKey)');
      } else {
        print('FES_MANAGER_FAILED: memoryData was null for $path (tried $relativeKey and $fesRelativeKey)');
        print('AVAILABLE FILES IN FES: ${fes.fileSystem.files.keys.toList()}');
      }
    }
    if (content == null) {
      throw StateError(
        'Requested file not found in Frontend Server memory cache: $path',
      );
    }
    socket.writeln(jsonEncode({'content': content}));
  }

  /// Translates a build runner [uri] into the format expected by the Frontend
  /// Server.
  ///
  /// build runner reports reloaded root under 'packages/' (e.g.
  /// `packages/<root_package>/`), but the Frontend Server expects them to be
  /// at its workspace root directory (`org-dartlang-app:///`). For example:
  /// Before: `org-dartlang-app:///packages/my_root_package/src/foo.dart`
  /// After:  `org-dartlang-app:///lib/src/foo.dart`
  Uri _translateBuildRunnerUriToFrontendServerUri(Uri uri) {
    if (uri.scheme == 'org-dartlang-app') {
      final segments = uri.pathSegments;
      final rootPackageName = fes.fileSystem.rootPackageName;
      if (segments.length >= 3 &&
          segments[0] == 'packages' &&
          segments[1] == rootPackageName) {
        final rootPackageUri = packageConfig.packages[rootPackageName];
        if (rootPackageUri != null && rootPackageUri.path.endsWith('lib/')) {
          return uri.replace(pathSegments: ['lib', ...segments.skip(2)]);
        }
      }
    }
    return uri;
  }

  Future<void> shutdown() async {
    await fes.shutdown();
  }
}
