// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:watcher/src/watch_event.dart';

import 'data/build_status.dart';
import 'data/build_target.dart';
import 'data/server_log.dart';

/// A builder for the daemon.
///
/// Intended to be used as an interface for specific builder implementations
/// which actually do the building.
class DaemonBuilder {
  Stream<BuildResults> get builds => Stream.empty();

  Stream<ServerLog> get logs => Stream.empty();

  Future<void> build(
      Set<BuildTarget> targets, Iterable<WatchEvent> changes) async {}

  Future<void> stop() async {}
}
