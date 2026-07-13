// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:build/experiments.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';
import 'package:uuid/uuid.dart';

import '../common.dart';
import 'package_config.dart';

final _log = Logger('FrontendServerProxy');
final frontendServerSnapshotPath = p.join(
  sdkDir,
  'bin',
  'snapshots',
  'frontend_server_aot.dart.snapshot',
);

/// A driver that proxies build requests to a [PersistentFrontendServer]
/// instance.
class FrontendServerProxyDriver {
  PersistentFrontendServer? _frontendServer;
  final _requestQueue = Queue<_CompilationRequest>();
  bool _isProcessing = false;
  CompilerOutput? _cachedOutput;
  static final _fesPool = Pool(1);

  void init(PersistentFrontendServer frontendServer) {
    _frontendServer = frontendServer;
  }

  PersistentFrontendServer? get fes => _frontendServer;

  /// Reads a compiled asset's content directly from the Frontend Server's
  /// in-memory file caches.
  Future<String?> readInMemoryFile(
    String path,
    String entrypoint,
    List<Uri> invalidatedFiles,
  ) async {
    return _fesPool.withResource(() async {
      return await _frontendServer!.client.readInMemoryFile(
        path,
        entrypoint,
        invalidatedFiles,
      );
    });
  }

  /// Sends a recompile request to the Frontend Server at [entrypoint] with
  /// [invalidatedFiles].
  ///
  /// The initial recompile request is treated as a full compile.
  ///
  /// [filesToWrite] contains JS files that should be written to the filesystem.
  /// If left empty, all files are written.
  Future<CompilerOutput?> recompileAndRecord(
    String entrypoint,
    List<Uri> invalidatedFiles,
    Iterable<String> filesToWrite, {
    bool recompileRestart = false,
  }) async {
    return _fesPool.withResource(() async {
      return await _frontendServer!.client.recompileAndRecord(
        entrypoint,
        invalidatedFiles,
        filesToWrite,
        recompileRestart: recompileRestart,
      );
    });
  }

  Future<CompilerOutput?> compile(String entrypoint) async {
    final completer = Completer<CompilerOutput?>();
    _requestQueue.add(_CompileRequest(entrypoint, completer));
    if (!_isProcessing) _processQueue();
    return completer.future;
  }

  Future<CompilerOutput?> recompile(
    String entrypoint,
    List<Uri> invalidatedFiles,
  ) async {
    final completer = Completer<CompilerOutput?>();
    _requestQueue.add(
      _RecompileRequest(entrypoint, invalidatedFiles, completer),
    );
    if (!_isProcessing) _processQueue();
    return completer.future;
  }

  Future<CompilerOutput?> recompileRestart(
    String entrypoint,
    List<Uri> invalidatedFiles,
  ) async {
    final completer = Completer<CompilerOutput?>();
    _requestQueue.add(
      _RecompileRestartRequest(entrypoint, invalidatedFiles, completer),
    );
    if (!_isProcessing) _processQueue();
    return completer.future;
  }

  Future<CompilerOutput?> compileExpressionToJs({
    required String libraryUri,
    required String scriptUri,
    required int line,
    required int column,
    required Map<String, String> jsModules,
    required Map<String, String> jsFrameValues,
    required String moduleName,
    required String expression,
  }) async {
    final completer = Completer<CompilerOutput?>();
    _requestQueue.add(
      _CompileExpressionToJsRequest(
        libraryUri,
        scriptUri,
        line,
        column,
        jsModules,
        jsFrameValues,
        moduleName,
        expression,
        completer,
      ),
    );
    if (!_isProcessing) _processQueue();
    return completer.future;
  }

  void _processQueue() async {
    if (_isProcessing || _requestQueue.isEmpty) return;

    _isProcessing = true;
    final request = _requestQueue.removeFirst();
    CompilerOutput? output;
    try {
      if (request is _CompileRequest) {
        _cachedOutput = await _frontendServer!.compile(request.entrypoint);
        output = _cachedOutput;
      } else if (request is _RecompileRequest) {
        // Compile the first [_RecompileRequest] as a [_CompileRequest] to warm
        // up the Frontend Server.
        if (_cachedOutput == null) {
          _cachedOutput = await _frontendServer!.compile(request.entrypoint);
          output = _cachedOutput;
        } else {
          output = await _frontendServer!.recompile(
            request.entrypoint,
            request.invalidatedFiles,
          );
        }
      } else if (request is _RecompileRestartRequest) {
        output = await _frontendServer!.recompileRestart(
          request.entrypoint,
          request.invalidatedFiles,
        );
        _cachedOutput = output;
      } else if (request is _CompileExpressionToJsRequest) {
        output = await _frontendServer!.compileExpressionToJs(
          libraryUri: request.libraryUri,
          scriptUri: request.scriptUri,
          line: request.line,
          column: request.column,
          jsModules: request.jsModules,
          jsFrameValues: request.jsFrameValues,
          moduleName: request.moduleName,
          expression: request.expression,
        );
      }
      if (request is _RecompileRequest) {
        if (output != null && output.errorCount == 0) {
          await _frontendServer!.accept();
        } else {
          // We must await [reject]'s output, but we swallow the output since it
          // doesn't provide useful information.
          await _frontendServer!.reject();
        }
      }
      request.completer.complete(output);
    } catch (e, s) {
      request.completer.completeError(e, s);
    }

    _isProcessing = false;
    if (_requestQueue.isNotEmpty) {
      _processQueue();
    }
  }

  /// Clears the proxy driver's state between invocations of separate apps.
  void reset() {
    _requestQueue.clear();
    _isProcessing = false;
    _cachedOutput = null;
    _frontendServer?.reset();
  }

  Future<void> terminate() async {
    await _frontendServer!.shutdown();
    _frontendServer = null;
  }
}

abstract class _CompilationRequest {
  final Completer<CompilerOutput?> completer;
  _CompilationRequest(this.completer);
}

class _CompileRequest extends _CompilationRequest {
  final String entrypoint;
  _CompileRequest(this.entrypoint, super.completer);
}

class _RecompileRequest extends _CompilationRequest {
  final String entrypoint;
  final List<Uri> invalidatedFiles;
  _RecompileRequest(this.entrypoint, this.invalidatedFiles, super.completer);
}

class _RecompileRestartRequest extends _CompilationRequest {
  final String entrypoint;
  final List<Uri> invalidatedFiles;
  _RecompileRestartRequest(
    this.entrypoint,
    this.invalidatedFiles,
    super.completer,
  );
}

class _CompileExpressionToJsRequest extends _CompilationRequest {
  final String libraryUri;
  final String scriptUri;
  final int line;
  final int column;
  final Map<String, String> jsModules;
  final Map<String, String> jsFrameValues;
  final String moduleName;
  final String expression;

  _CompileExpressionToJsRequest(
    this.libraryUri,
    this.scriptUri,
    this.line,
    this.column,
    this.jsModules,
    this.jsFrameValues,
    this.moduleName,
    this.expression,
    super.completer,
  );
}

/// A single instance of the Frontend Server that persists across
/// compile/recompile requests.
class PersistentFrontendServer {
  final FrontendServerClient _client;
  final Uri outputDillUri;
  final WebMemoryFilesystem _fileSystem;

  PersistentFrontendServer._({
    required this._client,
    required this.outputDillUri,
    required this._fileSystem,
  });

  FrontendServerClient get client => _client;
  WebMemoryFilesystem get fileSystem => _fileSystem;

  static Future<PersistentFrontendServer> start({
    required String sdkRoot,
    required Uri fileSystemRoot,
    List<Uri>? fileSystemRoots,
    required Uri packagesFile,
    Map<String, String> environment = const {},
    String? librariesPath,
    String? platformSdk,
    String? sdkKernelPath,
  }) async {
    final rootPackage = getRootPackageName();
    final socketConnection = await _tryConnectToFESManager(fileSystemRoot);
    if (socketConnection != null) {
      return PersistentFrontendServer._(
        client: SocketFrontendServerClient(
          socketConnection.socket,
          socketConnection.socketLines,
        ),
        outputDillUri: fileSystemRoot.resolve('output.dill'),
        fileSystem: WebMemoryFilesystem(fileSystemRoot, rootPackage),
      );
    }

    // ScratchSpace's generated 'package_config.json' uses absolute file URIs
    // (e.g., file:///tmp/...), but Frontend Server expects paths mounted under
    // its multi-root scheme (e.g., org-dartlang-app:///). So we rewrite all
    // non-root package URIs their absolute multi-root URIs.
    final file = File.fromUri(packagesFile);
    if (!file.existsSync()) {
      throw StateError(
        'package_config.json does not exist at ${packagesFile.toFilePath()}',
      );
    }
    PackageConfig.rewriteToMultiRoot(file, multiRootScheme, rootPackage);

    final outputDillUri = fileSystemRoot.resolve('output.dill');
    // [platformDill] must be passed to the Frontend Server with a 'file:'
    // prefix to pass schema checks for Windows drive letters.
    final platformDill = Uri.file(
      p.join(sdkDir, 'lib', '_internal', 'ddc_outline.dill'),
    );
    final args = [
      frontendServerSnapshotPath,
      '--sdk-root=$sdkRoot',
      '--incremental',
      '--target=dartdevc',
      '--dartdevc-module-format=ddc',
      '--dartdevc-canary',
      '--no-js-strongly-connected-components',
      '--packages=${packagesFile.toFilePath()}',
      '--experimental-emit-debug-metadata',
      '--filesystem-scheme=$multiRootScheme',
      '--filesystem-root=${fileSystemRoot.toFilePath()}',
      if (fileSystemRoots != null)
        for (final root in fileSystemRoots)
          '--filesystem-root=${root.toFilePath()}',
      if (librariesPath != null) '--libraries-spec=$librariesPath',
      if (platformSdk != null) '--platform-sdk=$platformSdk',
      if (sdkKernelPath != null) '--sdk-kernel-path=$sdkKernelPath',
      '--platform=$platformDill',
      '--output-dill=${outputDillUri.toFilePath()}',
      '--output-incremental-dill=${outputDillUri.toFilePath()}',
      for (final define in environment.entries)
        '-D${define.key}=${define.value}',
      for (final experiment in enabledExperiments)
        '--enable-experiment=$experiment',
    ];
    final dartaotruntime = p.join(sdkRoot, 'bin', 'dartaotruntime');
    final process = await _startWithReaper(dartaotruntime, args);
    final fileSystem = WebMemoryFilesystem(fileSystemRoot, rootPackage);
    final stdoutHandler = StdoutHandler(logger: _log);
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(stdoutHandler.handler);
    process.stderr.transform(utf8.decoder).listen(_log.warning);

    return PersistentFrontendServer._(
      client: StdioFrontendServerClient(
        process,
        stdoutHandler,
        fileSystem,
        outputDillUri,
      ),
      outputDillUri: outputDillUri,
      fileSystem: fileSystem,
    );
  }

  /// Tries to connect to a shared Frontend Server manager.
  ///
  /// Looks for a config file at [fesManagerConfigPath]. If it exists, reads the
  /// port and attempts to connect.
  ///
  /// If a connection can't be made, returns `null` and deletes the config file.
  static Future<_FesSocketConnection?> _tryConnectToFESManager(
    Uri fileSystemRoot, {
    int retries = 10,
  }) async {
    final configFile = File(
      p.join(Directory.current.path, fesManagerConfigPath),
    );
    if (!configFile.existsSync()) return null;

    int? port;
    for (var i = 0; i < retries; i++) {
      try {
        final content = await configFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        port = json['port'] as int?;
        if (port != null) break;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }

    if (port == null) {
      throw StateError(
        'FES config file found at ${configFile.path} '
        'but port could not be read.',
      );
    }

    try {
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
      final socketLines = socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();
      return _FesSocketConnection(socket, socketLines);
    } catch (e) {
      throw StateError('Failed to connect to FES manager at port $port: $e');
    }
  }

  /// `Process.start` plus a reaper script so that the child process is killed
  /// if the parent process is killed.
  static Future<Process> _startWithReaper(
    String command,
    List<String> arguments,
  ) async {
    final result = await Process.start(command, arguments);
    final reaper = await _startReaper(parentPid: pid, childPid: result.pid);
    if (reaper != null) {
      result.exitCode.then<void>((_) {
        reaper.kill();
      }).ignore();
    }
    return result;
  }

  /// Starts a script that waits until [parentPid] exits then kills [childPid].
  ///
  /// Returns `null` on failure to start the script.
  ///
  /// The caller is responsible for killing the reaper if the child exits first.
  static Future<Process?> _startReaper({
    required int parentPid,
    required int childPid,
  }) async {
    try {
      if (Platform.isWindows) {
        return await Process.start('powershell', [
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          'Wait-Process -Id $parentPid; Stop-Process -Id $childPid -Force',
        ]);
      } else {
        return await Process.start('bash', [
          '-c',
          'while kill -0 $parentPid; do sleep 1; done; kill -9 $childPid',
        ], mode: ProcessStartMode.detachedWithStdio);
      }
    } on ProcessException catch (_) {
      return null;
    }
  }

  Future<CompilerOutput?> compile(String entrypoint) =>
      _client.compile(entrypoint);

  Future<CompilerOutput?> recompile(
    String entrypoint,
    List<Uri> invalidatedFiles,
  ) => _client.recompile(entrypoint, invalidatedFiles);

  Future<CompilerOutput?> recompileRestart(
    String entrypoint,
    List<Uri> invalidatedFiles,
  ) => _client.recompileRestart(entrypoint, invalidatedFiles);

  Future<CompilerOutput?> compileExpressionToJs({
    required String libraryUri,
    required String scriptUri,
    required int line,
    required int column,
    required Map<String, String> jsModules,
    required Map<String, String> jsFrameValues,
    required String moduleName,
    required String expression,
  }) => _client.compileExpressionToJs(
    libraryUri: libraryUri,
    scriptUri: scriptUri,
    line: line,
    column: column,
    jsModules: jsModules,
    jsFrameValues: jsFrameValues,
    moduleName: moduleName,
    expression: expression,
  );

  Future<void> accept() => _client.accept();
  Future<String> readOutputFile(String path) => _client.readOutputFile(path);
  Future<CompilerOutput?> reject() => _client.reject();
  Future<void> reset() => _client.reset();

  /// Records all modified files into the in-memory filesystem.
  void recordFiles() {
    final outputDillPath = outputDillUri.toFilePath();
    final codeFile = File('$outputDillPath.sources');
    final manifestFile = File('$outputDillPath.json');
    final sourcemapFile = File('$outputDillPath.map');
    final metadataFile = File('$outputDillPath.metadata');
    _fileSystem.update(codeFile, manifestFile, sourcemapFile, metadataFile);
  }

  void writeAllFiles() {
    _fileSystem.writeAllFilesToDisk(_fileSystem.jsRootUri);
  }

  void writeFile(String fileName) {
    _fileSystem.writeFileToDisk(_fileSystem.jsRootUri, fileName);
  }

  Future<void> shutdown() => _client.shutdown();
}

class CompilerOutput {
  const CompilerOutput(
    this.outputFilename,
    this.errorCount,
    this.sources, {
    this.expressionData,
    this.errorMessage,
  });

  final String outputFilename;
  final int errorCount;
  final List<Uri> sources;

  /// Non-null for expression compilation requests.
  final Uint8List? expressionData;

  /// Non-null when a compilation error was encountered.
  final String? errorMessage;
}

// A simple in-memory filesystem for handling the Frontend Server's compiled
// output.
class WebMemoryFilesystem {
  /// The root directory's URI from which JS file are being served.
  final Uri jsRootUri;
  final String? rootPackageName;

  final Map<String, Uint8List> files = {};
  final Map<String, Uint8List> sourcemaps = {};
  final Map<String, Uint8List> metadata = {};

  WebMemoryFilesystem(this.jsRootUri, [this.rootPackageName]);

  /// Writes the entirety of this filesystem to [outputDirectoryUri].
  void writeAllFilesToDisk(Uri outputDirectoryUri) {
    assert(
      Directory.fromUri(outputDirectoryUri).existsSync(),
      '$outputDirectoryUri does not exist.',
    );
    final filesToWrite = {...files, ...sourcemaps, ...metadata};
    _writeToDisk(outputDirectoryUri, filesToWrite);
  }

  /// Writes [fileName] and its associated sourcemap and metadata files to
  /// [outputDirectoryUri].
  ///
  /// [fileName] is the file path of the compiled JS file being requested.
  /// Source maps and metadata files will be pulled in based on this name.
  ///
  /// Maps Frontend Server URIs to local server/hoisted paths:
  /// - package:foo/lib/bar.dart -> packages/foo/bar.dart
  /// - org-dartlang-app:///web/main.dart -> web/main.dart
  /// - lib/src/helper.dart -> packages/root_package/src/helper.dart
  void writeFileToDisk(Uri outputDirectoryUri, String fileName) {
    assert(
      Directory.fromUri(outputDirectoryUri).existsSync(),
      '$outputDirectoryUri does not exist.',
    );
    final sourceFile = fesToAssetPath(fileName, rootPackage: rootPackageName);
    final sourceFileData = files[sourceFile];
    if (sourceFileData == null) {
      _log.warning(
        'File $fileName was requested but not compiled by the '
        'Frontend Server.',
      );
      return;
    }

    final sourceMapFile = '$sourceFile.map';
    final metadataFile = '$sourceFile.metadata';
    final filesToWrite = {
      sourceFile: files[sourceFile]!,
      sourceMapFile: sourcemaps[sourceMapFile]!,
      metadataFile: metadata[metadataFile]!,
    };

    _writeToDisk(outputDirectoryUri, filesToWrite);
  }

  /// Writes [rawFilesToWrite] to [outputDirectoryUri], where [rawFilesToWrite]
  /// is a map of file paths to their contents.
  void _writeToDisk(
    Uri outputDirectoryUri,
    Map<String, Uint8List> rawFilesToWrite,
  ) {
    rawFilesToWrite.forEach((path, content) {
      final outputFileUri = outputDirectoryUri.resolve(path);
      final outputFilePath = outputFileUri.toFilePath();
      final outputFile = File(outputFilePath);
      outputFile.createSync(recursive: true);
      outputFile.writeAsBytesSync(content);
    });
  }

  /// Update the filesystem with the provided source and manifest files.
  ///
  /// Returns the list of updated files.
  List<String> update(
    File codeFile,
    File manifestFile,
    File sourcemapFile,
    File metadataFile,
  ) {
    final updatedFiles = <String>[];
    final codeBytes = codeFile.readAsBytesSync();
    final sourcemapBytes = sourcemapFile.readAsBytesSync();
    final manifest = Map.castFrom<dynamic, dynamic, String, Object?>(
      json.decode(manifestFile.readAsStringSync()) as Map,
    );
    final metadataBytes = metadataFile.readAsBytesSync();

    for (final filePath in manifest.keys) {
      final Map<String, dynamic> offsets =
          Map.castFrom<dynamic, dynamic, String, Object?>(
            manifest[filePath] as Map,
          );
      final codeOffsets = (offsets['code'] as List<dynamic>).cast<int>();
      final sourcemapOffsets = (offsets['sourcemap'] as List<dynamic>)
          .cast<int>();
      final metadataOffsets = (offsets['metadata'] as List<dynamic>)
          .cast<int>();

      if (codeOffsets.length != 2 ||
          sourcemapOffsets.length != 2 ||
          metadataOffsets.length != 2) {
        _log.severe('Invalid manifest byte offsets: $offsets');
        continue;
      }

      final codeStart = codeOffsets[0];
      final codeEnd = codeOffsets[1];
      if (codeStart < 0 || codeEnd > codeBytes.lengthInBytes) {
        _log.severe('Invalid byte index: [$codeStart, $codeEnd]');
        continue;
      }
      var byteView = Uint8List.view(
        codeBytes.buffer,
        codeStart,
        codeEnd - codeStart,
      );
      final fileName = fesToAssetPath(filePath, rootPackage: rootPackageName);

      var codeString = utf8.decode(byteView);
      codeString = codeString.replaceAllMapped(
        RegExp(r'dartDevEmbedder\.debugger\.setSourceMap\([\s\S]*?\);'),
        (match) => match
            .group(0)!
            .replaceAll('"$fesJsExtension"', '"$jsModuleExtension"'),
      );
      codeString = codeString.replaceAll(
        fesSourceMapExtension,
        jsSourceMapExtension,
      );
      byteView = Uint8List.fromList(utf8.encode(codeString));

      files[fileName] = byteView;
      updatedFiles.add(fileName);

      final sourcemapStart = sourcemapOffsets[0];
      final sourcemapEnd = sourcemapOffsets[1];
      if (sourcemapStart < 0 || sourcemapEnd > sourcemapBytes.lengthInBytes) {
        continue;
      }
      var sourcemapView = Uint8List.view(
        sourcemapBytes.buffer,
        sourcemapStart,
        sourcemapEnd - sourcemapStart,
      );
      var sourcemapString = utf8.decode(sourcemapView);
      sourcemapString = sourcemapString.replaceAll(
        fesJsExtension,
        jsModuleExtension,
      );
      sourcemapView = Uint8List.fromList(utf8.encode(sourcemapString));
      final sourcemapName = '$fileName.map';
      sourcemaps[sourcemapName] = sourcemapView;

      final metadataStart = metadataOffsets[0];
      final metadataEnd = metadataOffsets[1];
      if (metadataStart < 0 || metadataEnd > metadataBytes.lengthInBytes) {
        _log.severe('Invalid byte index: [$metadataStart, $metadataEnd]');
        continue;
      }
      var metadataView = Uint8List.view(
        metadataBytes.buffer,
        metadataStart,
        metadataEnd - metadataStart,
      );
      var metadataString = utf8.decode(metadataView);
      metadataString = metadataString.replaceAll(
        fesJsExtension,
        jsModuleExtension,
      );
      metadataString = metadataString.replaceAll('.dart.lib', '');
      metadataString = metadataString.replaceAllMapped(
        RegExp(r'"name"\s*:\s*"([^"]*?)\.dart"'),
        (match) => '"name":"${match.group(1)}"',
      );
      metadataView = Uint8List.fromList(utf8.encode(metadataString));
      metadata['$fileName.metadata'] = metadataView;
    }
    return updatedFiles;
  }
}

enum StdoutState { CollectDiagnostic, CollectDependencies }

/// Handles stdin/stdout communication with the Frontend Server.
class StdoutHandler {
  StdoutHandler({required this._logger}) {
    reset();
  }
  final Logger _logger;

  String? boundaryKey;
  StdoutState state = StdoutState.CollectDiagnostic;
  Completer<CompilerOutput?>? compilerOutput;
  final sources = <Uri>[];

  var _suppressCompilerMessages = false;
  var _expectSources = true;
  var _errorBuffer = StringBuffer();

  void handler(String message) {
    const kResultPrefix = 'result ';
    if (boundaryKey == null && message.startsWith(kResultPrefix)) {
      boundaryKey = message.substring(kResultPrefix.length);
      return;
    }
    final messageBoundaryKey = boundaryKey;
    if (messageBoundaryKey != null && message.startsWith(messageBoundaryKey)) {
      if (_expectSources) {
        if (state == StdoutState.CollectDiagnostic) {
          state = StdoutState.CollectDependencies;
          return;
        }
      }
      if (message.length <= messageBoundaryKey.length) {
        compilerOutput?.complete();
        return;
      }
      final spaceDelimiter = message.lastIndexOf(' ');
      final fileName = message.substring(
        messageBoundaryKey.length + 1,
        spaceDelimiter,
      );
      final errorCount = int.parse(
        message.substring(spaceDelimiter + 1).trim(),
      );

      final output = CompilerOutput(
        fileName,
        errorCount,
        sources,
        expressionData: null,
        errorMessage: _errorBuffer.isNotEmpty ? _errorBuffer.toString() : null,
      );
      compilerOutput?.complete(output);
      return;
    }
    switch (state) {
      case StdoutState.CollectDiagnostic when _suppressCompilerMessages:
        _logger.info(message);
        _errorBuffer.writeln(message);
      case StdoutState.CollectDiagnostic:
        _logger.warning(message);
        _errorBuffer.writeln(message);
      case StdoutState.CollectDependencies:
        switch (message[0]) {
          case '+':
            sources.add(Uri.parse(message.substring(1)));
          case '-':
            sources.remove(Uri.parse(message.substring(1)));
          default:
            _logger.warning('Ignoring unexpected prefix for $message uri');
        }
    }
  }

  // This is needed to get ready to process next compilation result output,
  // with its own boundary key and new completer.
  void reset({
    bool suppressCompilerMessages = false,
    bool expectSources = true,
  }) {
    boundaryKey = null;
    compilerOutput = Completer<CompilerOutput?>();
    _suppressCompilerMessages = suppressCompilerMessages;
    _expectSources = expectSources;
    state = StdoutState.CollectDiagnostic;
    _errorBuffer = StringBuffer();
  }
}

/// Serializes async writes and flushes to an IOSink (such as stdin).
///
/// Ensures every write is flushed to the OS pipe before the next begins.
class _StdinWriterQueue {
  final IOSink _stdin;
  final Logger _log;
  Future<void> _chain = Future.value();

  _StdinWriterQueue(this._stdin, this._log);

  /// Schedules [line] to be written and flushed to stdin.
  ///
  /// Returns a [Future] that completes only after the line has been written
  /// and flushed.
  Future<void> send(String line) async {
    _log.fine('FES Stdin queue write: $line');
    _chain = _chain
        .then((_) async {
          _stdin.writeln(line);
          await _stdin.flush().catchError((_) {});
        })
        .catchError((_) {});
    await _chain;
  }
}

abstract class FrontendServerClient {
  Future<CompilerOutput?> compile(String entrypoint);

  Future<CompilerOutput?> recompile(
    String entrypoint,
    List<Uri> invalidatedFiles,
  );

  Future<CompilerOutput?> recompileRestart(
    String entrypoint,
    List<Uri> invalidatedFiles,
  );

  Future<CompilerOutput?> compileExpressionToJs({
    required String libraryUri,
    required String scriptUri,
    required int line,
    required int column,
    required Map<String, String> jsModules,
    required Map<String, String> jsFrameValues,
    required String moduleName,
    required String expression,
  });

  Future<void> accept();
  Future<CompilerOutput?> reject();
  Future<void> reset();
  Future<void> shutdown();
  Future<String> readOutputFile(String path);

  Future<String?> readInMemoryFile(
    String path,
    String entrypoint,
    List<Uri> invalidatedFiles,
  );

  Future<CompilerOutput?> recompileAndRecord(
    String entrypoint,
    List<Uri> invalidatedFiles,
    Iterable<String> filesToWrite, {
    bool recompileRestart = false,
  });
}

/// A Frontend Server client that communicates with a shared external FES
/// Manager process over a socket using JSON-encoded commands.
///
/// Primarily used by webdev and supports client-side hot reload and expression
/// eval.
class SocketFrontendServerClient implements FrontendServerClient {
  final Socket _socket;
  final Stream<String> _socketLines;

  SocketFrontendServerClient(this._socket, this._socketLines);

  @override
  Future<CompilerOutput?> compile(String entrypoint) async {
    final nextResponseFuture = _socketLines.first;
    _socket.writeln(
      jsonEncode({'instruction': 'COMPILE', 'entrypoint': entrypoint}),
    );
    final responseLine = await nextResponseFuture;
    final compileResult = jsonDecode(responseLine) as Map<String, dynamic>;
    return CompilerOutput(
      compileResult['outputFilename'] as String? ?? '',
      (compileResult['errorCount'] as int?) ?? 0,
      (compileResult['sources'] as List?)
              ?.cast<String>()
              .map(Uri.parse)
              .toList() ??
          [],
      errorMessage: compileResult['errorMessage'] as String?,
    );
  }

  @override
  Future<String?> readInMemoryFile(
    String path,
    String entrypoint,
    List<Uri> invalidatedFiles,
  ) async {
    final nextResponseFuture = _socketLines.first;
    _socket.writeln(
      jsonEncode({
        'instruction': 'READ_OUTPUT_FILE',
        'path': path,
        'entrypoint': entrypoint,
        'invalidatedFiles': invalidatedFiles.map((u) => u.toString()).toList(),
      }),
    );
    await _socket.flush();
    final responseLine = await nextResponseFuture;
    final response = jsonDecode(responseLine) as Map<String, dynamic>;
    return response['content'] as String?;
  }

  @override
  Future<CompilerOutput?> recompileAndRecord(
    String entrypoint,
    List<Uri> invalidatedFiles,
    Iterable<String> filesToWrite, {
    bool recompileRestart = false,
  }) async {
    final nextResponseFuture = _socketLines.first;
    _socket.writeln(
      jsonEncode({
        'instruction': 'RECOMPILE_AND_RECORD',
        'entrypoint': entrypoint,
        'invalidatedFiles': invalidatedFiles.map((u) => u.toString()).toList(),
        'filesToWrite': filesToWrite.toList(),
        'recompileRestart': recompileRestart,
      }),
    );
    await _socket.flush();
    final responseLine = await nextResponseFuture;
    final compileResult = jsonDecode(responseLine) as Map<String, dynamic>;
    return CompilerOutput(
      compileResult['outputFilename'] as String? ?? '',
      (compileResult['errorCount'] as int?) ?? 0,
      (compileResult['sources'] as List?)
              ?.cast<String>()
              .map(Uri.parse)
              .toList() ??
          [],
      errorMessage: compileResult['errorMessage'] as String?,
    );
  }

  @override
  Future<CompilerOutput?> recompile(
    String entrypoint,
    List<Uri> invalidatedFiles,
  ) => throw UnsupportedError('Use recompileAndRecord for socket client.');

  @override
  Future<CompilerOutput?> recompileRestart(
    String entrypoint,
    List<Uri> invalidatedFiles,
  ) => throw UnsupportedError('Use recompileAndRecord for socket client.');

  @override
  Future<CompilerOutput?> compileExpressionToJs({
    required String libraryUri,
    required String scriptUri,
    required int line,
    required int column,
    required Map<String, String> jsModules,
    required Map<String, String> jsFrameValues,
    required String moduleName,
    required String expression,
  }) async {
    final nextResponseFuture = _socketLines.first;
    _socket.writeln(
      jsonEncode({
        'instruction': 'COMPILE_EXPRESSION_JS',
        'libraryUri': libraryUri,
        'scriptUri': scriptUri,
        'line': line,
        'column': column,
        'jsModules': jsModules,
        'jsFrameValues': jsFrameValues,
        'moduleName': moduleName,
        'expression': expression,
      }),
    );
    await _socket.flush();
    final responseLine = await nextResponseFuture;
    final response = jsonDecode(responseLine) as Map<String, dynamic>;
    final bytes = response['expressionData'] != null
        ? base64.decode(response['expressionData'] as String)
        : null;
    return CompilerOutput(
      '',
      (response['errorCount'] as int?) ?? 0,
      [],
      expressionData: bytes,
      errorMessage: response['errorMessage'] as String?,
    );
  }

  @override
  Future<void> accept() async {}

  @override
  Future<CompilerOutput?> reject() async => null;

  @override
  Future<void> reset() async {}

  @override
  Future<void> shutdown() async {
    await _socket.close();
  }

  @override
  Future<String> readOutputFile(String path) async {
    final nextResponseFuture = _socketLines.first;
    _socket.writeln(
      jsonEncode({'instruction': 'READ_OUTPUT_FILE', 'path': path}),
    );
    await _socket.flush();
    final responseLine = await nextResponseFuture;
    final response = jsonDecode(responseLine) as Map<String, dynamic>;
    return response['content'] as String? ?? '';
  }
}

/// A Frontend Server client that interacts with a persistent local FES process
/// over stdio.
///
/// Used when running with `build_runner serve`.
class StdioFrontendServerClient implements FrontendServerClient {
  final Process _server;
  final StdoutHandler _stdoutHandler;
  final WebMemoryFilesystem _fileSystem;
  final Uri _outputDillUri;
  final _StdinWriterQueue _stdinWriterQueue;
  CompilerOutput? _cachedOutput;

  StdioFrontendServerClient(
    this._server,
    this._stdoutHandler,
    this._fileSystem,
    this._outputDillUri,
  ) : _stdinWriterQueue = _StdinWriterQueue(_server.stdin, _log);

  Future<void> _send(String line) async {
    await _stdinWriterQueue.send(line);
  }

  @override
  Future<CompilerOutput?> compile(String entrypoint) async {
    _stdoutHandler.reset();
    await _send('compile $entrypoint');
    return await _stdoutHandler.compilerOutput!.future;
  }

  @override
  Future<CompilerOutput?> recompile(
    String entrypoint,
    List<Uri> invalidatedFiles,
  ) async {
    _stdoutHandler.reset();
    final inputKey = const Uuid().v4();
    await _send('recompile $entrypoint $inputKey');
    for (final file in invalidatedFiles) {
      await _send(file.toString());
    }
    await _send(inputKey);
    return await _stdoutHandler.compilerOutput!.future;
  }

  @override
  Future<CompilerOutput?> recompileRestart(
    String entrypoint,
    List<Uri> invalidatedFiles,
  ) async {
    _stdoutHandler.reset();
    final inputKey = const Uuid().v4();
    await _send('recompile-restart $entrypoint $inputKey');
    for (final file in invalidatedFiles) {
      await _send(file.toString());
    }
    await _send(inputKey);
    return await _stdoutHandler.compilerOutput!.future;
  }

  @override
  Future<CompilerOutput?> compileExpressionToJs({
    required String libraryUri,
    required String scriptUri,
    required int line,
    required int column,
    required Map<String, String> jsModules,
    required Map<String, String> jsFrameValues,
    required String moduleName,
    required String expression,
  }) async {
    _stdoutHandler.reset(expectSources: false);
    await _send('JSON_INPUT');
    await _send(
      json.encode({
        'type': 'COMPILE_EXPRESSION_JS',
        'data': {
          'expression': expression,
          'libraryUri': libraryUri,
          'scriptUri': scriptUri,
          'line': line,
          'column': column,
          'jsModules': jsModules,
          'jsFrameValues': jsFrameValues,
          'moduleName': moduleName,
        },
      }),
    );
    CompilerOutput? result;
    try {
      result = await _stdoutHandler.compilerOutput!.future.timeout(
        const Duration(seconds: 10),
      );
    } on TimeoutException {
      _stdoutHandler.reset();
      return const CompilerOutput(
        '',
        1,
        [],
        errorMessage: 'Timeout waiting for expression compilation',
      );
    }

    if (result != null &&
        result.expressionData == null &&
        result.outputFilename.isNotEmpty) {
      final file = File(result.outputFilename);
      if (file.existsSync()) {
        return CompilerOutput(
          result.outputFilename,
          result.errorCount,
          result.sources,
          expressionData: file.readAsBytesSync(),
          errorMessage: result.errorMessage,
        );
      }
    }
    return result;
  }

  @override
  Future<void> accept() async {
    await _send('accept');
  }

  @override
  Future<CompilerOutput?> reject() async {
    _stdoutHandler.reset(expectSources: false);
    await _send('reject');
    return await _stdoutHandler.compilerOutput!.future;
  }

  @override
  Future<void> reset() async {
    _stdoutHandler.reset();
    await _send('reset');
  }

  @override
  Future<void> shutdown() async {
    await _send('quit');
    await _server.exitCode;
  }

  @override
  Future<String> readOutputFile(String path) => File(path).readAsString();

  @override
  Future<String?> readInMemoryFile(
    String path,
    String entrypoint,
    List<Uri> invalidatedFiles,
  ) async {
    String? content;
    final scratchSpacePrefix = testScratchSpacePathPrefix;
    final index = path.indexOf(scratchSpacePrefix);
    final strippedPath = index != -1
        ? path.substring(index + scratchSpacePrefix.length)
        : path;
    final relativeKey = fesToAssetPath(
      strippedPath,
      rootPackage: _fileSystem.rootPackageName,
    );

    final memoryData =
        _fileSystem.files[relativeKey] ??
        _fileSystem.sourcemaps[relativeKey] ??
        _fileSystem.metadata[relativeKey];
    if (memoryData != null) {
      content = utf8.decode(memoryData);
    }

    if (content == null) {
      throw StateError(
        'Requested memory file not found in Frontend Server memory cache: '
        '$path',
      );
    }
    return content;
  }

  @override
  Future<CompilerOutput?> recompileAndRecord(
    String entrypoint,
    List<Uri> invalidatedFiles,
    Iterable<String> filesToWrite, {
    bool recompileRestart = false,
  }) async {
    final isFirstRequest = _cachedOutput == null;
    final compilerOutput = await (switch ((isFirstRequest, recompileRestart)) {
      (true, _) => compile(entrypoint),
      (false, true) => this.recompileRestart(entrypoint, invalidatedFiles),
      (false, false) => recompile(entrypoint, invalidatedFiles),
    });
    if (compilerOutput == null ||
        compilerOutput.errorCount != 0 ||
        compilerOutput.errorMessage != null) {
      await reject();
      return compilerOutput;
    }
    await accept();
    _cachedOutput = compilerOutput;
    recordFiles();
    writeAllFiles();
    return compilerOutput;
  }

  void recordFiles() {
    final outputDillPath = _outputDillUri.toFilePath();
    final codeFile = File('$outputDillPath.sources');
    final manifestFile = File('$outputDillPath.json');
    final sourcemapFile = File('$outputDillPath.map');
    final metadataFile = File('$outputDillPath.metadata');
    _fileSystem.update(codeFile, manifestFile, sourcemapFile, metadataFile);
  }

  void writeAllFiles() {
    _fileSystem.writeAllFilesToDisk(_fileSystem.jsRootUri);
  }
}

class _FesSocketConnection {
  final Socket socket;
  final Stream<String> socketLines;
  _FesSocketConnection(this.socket, this.socketLines);
}
