// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_daemon/daemon_builder.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:build_daemon/data/server_log.dart';
import 'package:watcher/watcher.dart' show WatchEvent;

class FakeTestDaemonBuilder implements DaemonBuilder {
  static final loggerName = 'FakeTestDaemonBuilder';
  static final buildCompletedMessage = 'Build Completed';

  final _outputStreamController = StreamController<ServerLog>();
  late final Stream<ServerLog> _logs;

  FakeTestDaemonBuilder() {
    _logs = _outputStreamController.stream.asBroadcastStream();
  }

  @override
  Stream<BuildResults> get builds => Stream.empty();

  @override
  Stream<ServerLog> get logs => _logs;

  @override
  Future<void> build(
      Set<BuildTarget> targets, Iterable<WatchEvent> changes) async {
    _outputStreamController.add(ServerLog((b) => b
      ..loggerName = loggerName
      ..level = Level.INFO
      ..message = buildCompletedMessage));
  }

  @override
  Future<void> stop() => _outputStreamController.close();
}
