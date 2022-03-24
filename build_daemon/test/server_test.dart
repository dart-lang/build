// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@OnPlatform({
  'windows': Skip('Directories cant be deleted while processes are still open')
})
import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:build_daemon/data/build_request.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:build_daemon/data/build_target_request.dart';
import 'package:build_daemon/data/serializers.dart';
import 'package:build_daemon/data/server_log.dart';
import 'package:build_daemon/src/fakes/fake_change_provider.dart';
import 'package:build_daemon/src/fakes/fake_test_builder.dart';
import 'package:build_daemon/src/server.dart';
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  group('Server', () {
    final webTarget = DefaultBuildTarget((b) => b.target = 'web');
    late final StreamController<ServerLog> logController;
    late final Stream<ServerLog> logs;
    late final IOWebSocketChannel client;
    late final Server server;

    setUp(() async {
      logController = StreamController<ServerLog>();
      logs = logController.stream.asBroadcastStream();

      // Start the server.
      server = _createServer();
      final port = await server.listen();

      // Connect the client and redirect its logs.
      client = _createClient(logController, port);
    });

    tearDown(() async {
      await server.stop();
      await client.sink.close();
      await logController.close();
      await checkThat(server.onDone).completes();
    });

    test('can forward logs to the client', () async {
      // Setup listening for a completed build.
      final buildCompleted = checkThat(StreamQueue(logs)).emits().that((l) => l
        ..level.equals(Level.INFO)
        ..message.equals(FakeTestDaemonBuilder.buildCompletedMessage)
        ..loggerName.equals(FakeTestDaemonBuilder.loggerName));

      // Build a target to register interested channels on the server.
      _requestBuild(client, webTarget);
      await buildCompleted;

      // Setup listening for forwarded logs.
      final logsReceived = checkThat(StreamQueue(logs)).emits().that((l) => l
        ..level.equals(Level.WARNING)
        ..message.contains('bad request')
        ..loggerName.equals(Server.loggerName));

      // Send request that with throw an exception an will be logged.
      client.sink.add('bad request');

      // Await for logs to arrive to the client.
      await logsReceived;
    });
  });
}

Server _createServer() {
  return Server(
    FakeTestDaemonBuilder(),
    const Duration(seconds: 30),
    FakeChangeProvider(),
  );
}

IOWebSocketChannel _createClient(
  StreamController<ServerLog> controller,
  int port,
) {
  final client = IOWebSocketChannel.connect('ws://localhost:$port');
  client.stream.listen((data) {
    final message = serializers.deserialize(jsonDecode(data as String));
    if (message is ServerLog) {
      controller.add(message);
    }
  });
  return client;
}

void _requestBuild(IOWebSocketChannel client, BuildTarget target) {
  client.sink.add(jsonEncode(
      serializers.serialize(BuildTargetRequest((b) => b.target = target))));
  client.sink.add(
    jsonEncode(serializers.serialize(BuildRequest())),
  );
}

extension _ServerLogChecks on Check<ServerLog> {
  Check<Level> get level => has((l) => l.level, 'level');
  Check<String> get message => has((l) => l.message, 'message');
  Check<String?> get loggerName => has((l) => l.loggerName, 'loggerName');
}
