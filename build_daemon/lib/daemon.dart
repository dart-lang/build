// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:built_value/serializer.dart';
import 'package:watcher/watcher.dart';

import 'change_provider.dart';
import 'constants.dart';
import 'daemon_builder.dart';
import 'data/build_target.dart';
import 'src/server.dart';

/// The long running daemon process.
///
/// Obtains a file lock to ensure a single instance and writes various status
/// files to be used by clients for connection.
///
/// Also starts a [Server] to listen for build target registration and event
/// notification.
class Daemon {
  final String _workingDirectory;
  final RandomAccessFile _lock;
  final Server _server;
  final _doneCompleter = Completer();

  StreamSubscription _sub;

  Daemon._(
    this._workingDirectory,
    this._lock,
    this._server,
    int port,
    Set<String> options,
  ) {
    _handleGracefulExit();

    _createVersionFile();
    _createOptionsFile(options);
    _createPortFile(port);

    _server.onDone.then((_) async {
      await _cleanUp();
    });
  }

  Future<void> get onDone => _doneCompleter.future;

  Future<void> stop({String message, int failureType}) =>
      _server.stop(message: message, failureType: failureType);

  /// Starts the daemon.
  ///
  /// If [changeProvider] is an [AutoChangeProvider] then builds will
  /// automatically occur upon changes.
  ///
  /// If [changeProvider] is a [ManualChangeProvider] then builds will only
  /// occur when triggered by a client.
  static Future<Daemon> start(
    String workingDirectory,
    Set<String> options,
    DaemonBuilder builder,
    ChangeProvider changeProvider, {
    Serializers serializersOverride,
    bool Function(BuildTarget, Iterable<WatchEvent>) shouldBuild,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    var lock = _tryGetLock(workingDirectory);
    if (lock == null) throw LockError();
    var server = Server(
      builder,
      timeout,
      changeProvider,
      serializersOverride: serializersOverride,
      shouldBuild: shouldBuild,
    );
    var port = await server.listen();
    return Daemon._(workingDirectory, lock, server, port, options);
  }

  Future<void> _cleanUp() async {
    await _server?.stop();
    await _sub?.cancel();
    // We need to close the lock prior to deleting the file.
    _lock?.closeSync();
    var workspace = Directory(daemonWorkspace(_workingDirectory));
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
    if (!_doneCompleter.isCompleted) _doneCompleter.complete();
  }

  void _createPortFile(int port) =>
      File(portFilePath(_workingDirectory)).writeAsStringSync('$port');

  void _createVersionFile() => File(versionFilePath(_workingDirectory))
      .writeAsStringSync(currentVersion);

  void _createOptionsFile(Set<String> options) =>
      File(optionsFilePath(_workingDirectory))
          .writeAsStringSync(options.toList().join('\n'));

  void _handleGracefulExit() {
    var cancelCount = 0;
    _sub = ProcessSignal.sigint.watch().listen((signal) async {
      if (signal == ProcessSignal.sigint) {
        cancelCount++;
        await _server.stop();
        if (cancelCount > 1) exit(1);
      }
    });
  }
}

void _createDaemonWorkspace(String workingDirectory) {
  try {
    Directory(daemonWorkspace(workingDirectory)).createSync(recursive: true);
  } catch (e) {
    throw Exception('Unable to create daemon workspace: $e');
  }
}

RandomAccessFile _tryGetLock(String workingDirectory) {
  try {
    _createDaemonWorkspace(workingDirectory);
    var lock = File(lockFilePath(workingDirectory))
        .openSync(mode: FileMode.write)
          ..lockSync();
    return lock;
  } on FileSystemException {
    return null;
  }
}

/// Thrown if the Daemon can't get the required lock file.
class LockError implements Exception {}
