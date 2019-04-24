// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:built_value/serializer.dart';
import 'package:pedantic/pedantic.dart';
import 'package:watcher/watcher.dart';

import '../constants.dart';
import '../daemon_builder.dart';
import '../data/build_target.dart';
import 'file_wait.dart';
import 'server.dart';

/// Returns the current version of the running build daemon.
///
/// Null if one isn't running.
Future<String> runningVersion(String workingDirectory) async {
  var versionFile = File(versionFilePath(workingDirectory));
  if (!await waitForFile(versionFile)) return null;
  return versionFile.readAsStringSync();
}

/// Returns the current options of the running build daemon.
///
/// Null if one isn't running.
Future<Set<String>> currentOptions(String workingDirectory) async {
  var optionsFile = File(optionsFilePath(workingDirectory));
  if (!await waitForFile(optionsFile)) return Set();
  return optionsFile.readAsLinesSync().toSet();
}

/// The long running daemon process.
///
/// Obtains a file lock to ensure a single instance and writes various status
/// files to be used by clients for connection.
///
/// Also starts a [Server] to listen for build target registration and event
/// notification.
class Daemon {
  final String _workingDirectory;

  final _doneCompleter = Completer();

  Server _server;
  StreamSubscription _sub;
  RandomAccessFile _lock;

  Daemon(this._workingDirectory);

  Future<void> get onDone => _doneCompleter.future;

  Future<void> stop({String message}) => _server.stop(message: message);

  Future<void> start(
      Set<String> options, DaemonBuilder builder, Stream<WatchEvent> changes,
      {Serializers serializersOverride,
      bool Function(BuildTarget, Iterable<WatchEvent>) shouldBuild,
      Duration timeout = const Duration(seconds: 30)}) async {
    if (_server != null) return;
    _handleGracefulExit();

    _createVersionFile();
    _createOptionsFile(options);

    _server = Server(builder, changes, timeout,
        serializersOverride: serializersOverride, shouldBuild: shouldBuild);
    var port = await _server.listen();
    _createPortFile(port);

    unawaited(_server.onDone.then((_) async {
      await _cleanUp();
    }));
  }

  bool tryGetLock() {
    try {
      _createDaemonWorkspace();
      _lock = File(lockFilePath(_workingDirectory))
          .openSync(mode: FileMode.write)
            ..lockSync();
      return true;
    } on FileSystemException {
      return false;
    }
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

  void _createDaemonWorkspace() {
    try {
      Directory(daemonWorkspace(_workingDirectory)).createSync(recursive: true);
    } catch (e) {
      throw Exception('Unable to create daemon workspace: $e');
    }
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
