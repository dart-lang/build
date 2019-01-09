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
import 'server.dart';

/// Returns the current version of the running build daemon. Null if one isn't
/// running.
String runningVersion(String workingDirectory) {
  var versionFile = File(versionFilePath(workingDirectory));
  if (!versionFile.existsSync()) return null;
  return versionFile.readAsStringSync();
}

class Daemon {
  final String _workingDirectory;

  final _doneCompleter = Completer();

  Server _server;
  StreamSubscription _sub;

  Daemon(this._workingDirectory);

  Future<void> get onDone => _doneCompleter.future;

  Future<void> start(DaemonBuilder builder, Stream<WatchEvent> changes,
      {Serializers serializersOverride}) async {
    if (_server != null) return;
    _handleGracefulExit();

    _createVersionFile();

    _server =
        Server(builder, changes, serializersOverride: serializersOverride);
    var port = await _server.listen();
    _createPortFile(port);

    unawaited(_server.onDone.then((_) async {
      await _cleanUp();
    }));
  }

  bool tryGetLock() {
    try {
      _createDaemonWorkspace();
      File(lockFilePath(_workingDirectory))
          .openSync(mode: FileMode.write)
          .lockSync();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  Future<void> _cleanUp() async {
    await _server?.stop();
    await _sub?.cancel();
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

  void _handleGracefulExit() {
    var cancelCount = 0;
    _sub = ProcessSignal.sigint.watch().listen((signal) async {
      if (signal == ProcessSignal.sigint) {
        cancelCount++;
        await _cleanUp();
        if (cancelCount > 1) exit(1);
      }
    });
  }
}
