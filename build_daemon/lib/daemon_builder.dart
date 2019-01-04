import 'dart:async';

import 'data/build_status.dart';
import 'data/server_log.dart';

class DaemonBuilder {
  Stream<BuildResults> get builds => Stream.empty();

  Stream<ServerLog> get logs => Stream.empty();

  Future<void> build(
      Set<String> targets, Set<String> options, Set<String> logToPaths) async {}

  Future<void> stop() async {}
}
