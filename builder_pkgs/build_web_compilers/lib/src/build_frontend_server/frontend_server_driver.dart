// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../common.dart';

final _log = Logger('FrontendServerProxy');
final dartaotruntimePath = p.join(sdkDir, 'bin', 'dartaotruntime');
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

  void init(PersistentFrontendServer frontendServer) {
    _frontendServer = frontendServer;
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
    if (_frontendServer!._socket != null) {
      final socket = _frontendServer!._socket!;
      final socketLines = _frontendServer!._socketLines!;
      final nextResponseFuture = socketLines.first;
      socket.writeln(
        jsonEncode({
          'instruction': 'RECOMPILE_AND_RECORD',
          'entrypoint': entrypoint,
          'invalidatedFiles':
              invalidatedFiles.map((u) => u.toString()).toList(),
          'filesToWrite': filesToWrite.toList(),
          'recompileRestart': recompileRestart,
        }),
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
      );
    }

    // The first request to the Frontend Server will be coerced to a full
    // compile. We must additionally write all of FES's generated files
    // to disk - not just those for the 'current' library.
    final isFirstRequest = _cachedOutput == null;
    final compilerOutput =
        recompileRestart
            ? await this.recompileRestart(entrypoint, invalidatedFiles)
            : await recompile(entrypoint, invalidatedFiles);
    if (compilerOutput == null ||
        compilerOutput.errorCount != 0 ||
        compilerOutput.errorMessage != null) {
      // Don't update the Frontend Server's state if an error occurred.
      return compilerOutput;
    }
    _frontendServer!.recordFiles();
    if (isFirstRequest || filesToWrite.isEmpty) {
      _frontendServer!.writeAllFiles();
    } else {
      for (final file in filesToWrite) {
        _frontendServer!.writeFile(file);
      }
    }
    return compilerOutput;
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
          _frontendServer!.accept();
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
  Process? _server;
  final Socket? _socket;
  final Stream<String>? _socketLines;
  final StdoutHandler? _stdoutHandler;
  final StreamController<String>? _stdinController;
  final Uri outputDillUri;
  final WebMemoryFilesystem _fileSystem;
  PersistentFrontendServer._({
    Process? server,
    StdoutHandler? stdoutHandler,
    StreamController<String>? stdinController,
    required this.outputDillUri,
    required WebMemoryFilesystem fileSystem,
    Socket? socket,
    Stream<String>? socketLines,
  }) : _server = server,
       _stdoutHandler = stdoutHandler,
       _stdinController = stdinController,
       _fileSystem = fileSystem,
       _socket = socket,
       _socketLines = socketLines;

  static Future<PersistentFrontendServer> start({
    required String sdkRoot,
    required Uri fileSystemRoot,
    required Uri packagesFile,
  }) async {
    final fes = await _tryConnectToFESManager(fileSystemRoot);
    if (fes != null) return fes;

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
      '--platform=$platformDill',
      '--output-dill=${outputDillUri.toFilePath()}',
      '--output-incremental-dill=${outputDillUri.toFilePath()}',
    ];
    final process = await _startWithReaper(dartaotruntimePath, args);
    final fileSystem = WebMemoryFilesystem(fileSystemRoot);
    final stdoutHandler = StdoutHandler(logger: _log);
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(stdoutHandler.handler);
    process.stderr.transform(utf8.decoder).listen(stderr.writeln);

    final stdinController = StreamController<String>();
    stdinController.stream.listen(process.stdin.writeln);

    return PersistentFrontendServer._(
      server: process,
      stdoutHandler: stdoutHandler,
      stdinController: stdinController,
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
  static Future<PersistentFrontendServer?> _tryConnectToFESManager(
    Uri fileSystemRoot,
  ) async {
    final configFile = File(
      p.join(Directory.current.path, fesManagerConfigPath),
    );
    if (!configFile.existsSync()) return null;

    try {
      final content = await configFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final port = json['port'] as int?;
      if (port == null) {
        throw StateError('Malformed FES port file: missing "port" field.');
      }

      final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
      final socketLines =
          socket
              .cast<List<int>>()
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .asBroadcastStream();
      final fileSystem = WebMemoryFilesystem(fileSystemRoot);
      return PersistentFrontendServer._(
        outputDillUri: fileSystemRoot.resolve('output.dill'),
        fileSystem: fileSystem,
        socket: socket,
        socketLines: socketLines,
      );
    } catch (e) {
      _log.warning(
        'Failed to connect to FES manager. Deleting stale config file and '
        'falling back to process mode.',
        e,
      );
      try {
        await configFile.delete();
      } catch (_) {}
      return null;
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

  Future<CompilerOutput?> compile(String entrypoint) async {
    if (_socket != null) {
      final socketLines = _socketLines!;
      final nextResponseFuture = socketLines.first;
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
      );
    }
    _stdoutHandler!.reset();
    _stdinController!.add('compile $entrypoint');
    return await _stdoutHandler.compilerOutput!.future;
  }

  /// Either [accept] or [reject] should be called after every [recompile] call.
  Future<CompilerOutput?> recompile(
    String entrypoint,
    List<Uri> invalidatedFiles,
  ) async {
    _stdoutHandler!.reset();
    final inputKey = const Uuid().v4();
    _stdinController!.add('recompile $entrypoint $inputKey');
    for (final file in invalidatedFiles) {
      _stdinController.add(file.toString());
    }
    _stdinController.add(inputKey);
    return await _stdoutHandler.compilerOutput!.future;
  }

  Future<CompilerOutput?> recompileRestart(
    String entrypoint,
    List<Uri> invalidatedFiles,
  ) async {
    _stdoutHandler!.reset();
    final inputKey = const Uuid().v4();
    _stdinController!.add('recompile-restart $entrypoint $inputKey');
    for (final file in invalidatedFiles) {
      _stdinController.add(file.toString());
    }
    _stdinController.add(inputKey);
    return await _stdoutHandler.compilerOutput!.future;
  }

  /// Compiles a Dart expression to JS via the Frontend Server.
  ///
  /// This method uses the `JSON_INPUT` protocol to communicate with the
  /// Frontend Server process.
  /// See: `pkg/frontend_server/lib/frontend_server.dart` in the Dart SDK.
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
    _stdoutHandler!.reset(expectSources: false);
    _stdinController!.add('JSON_INPUT');
    _stdinController.add(
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

  void accept() {
    _stdinController!.add('accept');
  }

  /// Reads the content of a file generated by the Frontend Server.
  ///
  /// This is called by the worker in `workers.dart` in response to a
  /// `READ_OUTPUT_FILE` request from the daemon in `daemon_builder.dart`.
  Future<String> readOutputFile(String path) => File(path).readAsString();

  Future<CompilerOutput?> reject() async {
    _stdoutHandler!.reset(expectSources: false);
    _stdinController!.add('reject');
    return await _stdoutHandler.compilerOutput!.future;
  }

  void reset() {
    _stdoutHandler!.reset();
    _stdinController!.add('reset');
  }

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

  Future<void> shutdown() async {
    _stdinController!.add('quit');
    await _server?.exitCode;
    await _stdinController.close();
    _server = null;
  }
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

  final Map<String, Uint8List> files = {};
  final Map<String, Uint8List> sourcemaps = {};
  final Map<String, Uint8List> metadata = {};

  WebMemoryFilesystem(this.jsRootUri);

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
  void writeFileToDisk(Uri outputDirectoryUri, String fileName) {
    assert(
      Directory.fromUri(outputDirectoryUri).existsSync(),
      '$outputDirectoryUri does not exist.',
    );
    var sourceFile = fileName;
    if (sourceFile.startsWith('package:')) {
      sourceFile =
          'packages/${sourceFile.substring('package:'.length, sourceFile.length)}';
    } else if (sourceFile.startsWith('$multiRootScheme:///')) {
      sourceFile = sourceFile.substring(
        '$multiRootScheme:///'.length,
        sourceFile.length,
      );
    }
    final sourceMapFile = '$sourceFile.map';
    final metadataFile = '$sourceFile.metadata';

    final sourceFileData = files[sourceFile];
    if (sourceFileData == null) {
      _log.warning(
        'File $fileName was requested but not compiled by the '
        'Frontend Server.',
      );
      return;
    }

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
      final sourcemapOffsets =
          (offsets['sourcemap'] as List<dynamic>).cast<int>();
      final metadataOffsets =
          (offsets['metadata'] as List<dynamic>).cast<int>();

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

      final byteView = Uint8List.view(
        codeBytes.buffer,
        codeStart,
        codeEnd - codeStart,
      );
      final fileName =
          filePath.startsWith('/') ? filePath.substring(1) : filePath;
      files[fileName] = byteView;
      updatedFiles.add(fileName);

      final sourcemapStart = sourcemapOffsets[0];
      final sourcemapEnd = sourcemapOffsets[1];
      if (sourcemapStart < 0 || sourcemapEnd > sourcemapBytes.lengthInBytes) {
        continue;
      }
      final sourcemapView = Uint8List.view(
        sourcemapBytes.buffer,
        sourcemapStart,
        sourcemapEnd - sourcemapStart,
      );
      final sourcemapName = '$fileName.map';
      sourcemaps[sourcemapName] = sourcemapView;

      final metadataStart = metadataOffsets[0];
      final metadataEnd = metadataOffsets[1];
      if (metadataStart < 0 || metadataEnd > metadataBytes.lengthInBytes) {
        _log.severe('Invalid byte index: [$metadataStart, $metadataEnd]');
        continue;
      }
      final metadataView = Uint8List.view(
        metadataBytes.buffer,
        metadataStart,
        metadataEnd - metadataStart,
      );
      metadata['$fileName.metadata'] = metadataView;
    }
    return updatedFiles;
  }
}

enum StdoutState { CollectDiagnostic, CollectDependencies }

/// Handles stdin/stdout communication with the Frontend Server.
class StdoutHandler {
  StdoutHandler({required Logger logger}) : _logger = logger {
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
