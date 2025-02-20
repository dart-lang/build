// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:watcher/watcher.dart' show WatchEvent;

import '../../daemon_builder.dart';
import '../../data/build_status.dart';
import '../../data/build_target.dart';
import '../../data/server_log.dart';

class FakeTestDaemonBuilder implements DaemonBuilder {
  static final loggerName = 'FakeTestDaemonBuilder';
  static final buildCompletedMessage = 'Build Completed';

  final _outputStreamController = StreamController<ServerLog>();
  final _buildsController = StreamController<BuildResults>.broadcast();

  late final Stream<ServerLog> _logs;

  FakeTestDaemonBuilder() {
    _logs = _outputStreamController.stream.asBroadcastStream();
  }

  @override
  Stream<BuildResults> get builds => _buildsController.stream;

  @override
  Stream<ServerLog> get logs => _logs;

  @override
  Future<void> build(
    Set<BuildTarget> targets,
    Iterable<WatchEvent> changes,
  ) async {
    _outputStreamController.add(
      ServerLog(
        (b) =>
            b
              ..loggerName = loggerName
              ..level = Level.INFO
              ..message = buildCompletedMessage,
      ),
    );

    _buildsController.add(
      BuildResults(
        (b) => b.changedAssets.add(Uri.parse('package:foo/bar.dart')),
      ),
    );
  }

  @override
  Future<void> stop() {
    return Future.wait([
      _outputStreamController.close(),
      _buildsController.close(),
    ]);
  }
}
