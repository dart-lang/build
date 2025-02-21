// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:watcher/watcher.dart' show WatchEvent;

import '../../daemon_builder.dart';
import '../../data/build_status.dart';
import '../../data/build_target.dart';
import '../../data/server_log.dart';

class FakeDaemonBuilder implements DaemonBuilder {
  @override
  Stream<BuildResults> get builds => const Stream.empty();

  @override
  Stream<ServerLog> get logs => const Stream.empty();

  @override
  Future<void> build(
    Set<BuildTarget> targets,
    Iterable<WatchEvent> changes,
  ) async {}

  @override
  Future<void> stop() async {}
}
