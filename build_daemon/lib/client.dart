// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build_daemon/data/build_target.dart';
import 'package:built_value/serializer.dart';
import 'package:web_socket_channel/io.dart';

import 'constants.dart';
import 'data/build_request.dart';
import 'data/build_status.dart';
import 'data/build_target_request.dart';
import 'data/serializers.dart';
import 'data/server_log.dart';

class BuildDaemonClient {
  IOWebSocketChannel _channel;
  Serializers _serializers;

  final _buildResults = StreamController<BuildResults>.broadcast();

  final _serverLogStreamController = StreamController<ServerLog>.broadcast();

  BuildDaemonClient._();

  Stream<BuildResults> get buildResults => _buildResults.stream;
  Future<void> get finished async {
    if (_channel != null) await _channel.sink.done;
  }

  Stream<ServerLog> get serverLogs => _serverLogStreamController.stream;

  /// Registers a build target to be built upon any file change.
  void registerBuildTarget(BuildTarget target) => _channel.sink.add(jsonEncode(
      _serializers.serialize(BuildTargetRequest((b) => b..target = target))));

  /// Builds all registered targets.
  void startBuild() {
    var request = BuildRequest();
    _channel.sink.add(jsonEncode(_serializers.serialize(request)));
  }

  Future<void> _connect(String workingDirectory, int port,
      Serializers serializersOverride) async {
    _channel = IOWebSocketChannel.connect('ws://localhost:$port');
    _channel.stream.listen(_handleServerMessage)
      // TODO(grouma) - Implement proper error handling.
      ..onError(print);
    _serializers = serializersOverride ?? serializers;
  }

  void _handleServerMessage(dynamic data) {
    var message = _serializers.deserialize(jsonDecode(data as String));
    if (message is ServerLog) {
      _serverLogStreamController.add(message);
    } else if (message is BuildResults) {
      _buildResults.add(message);
    } else {
      // In practice we should never reach this state due to the
      // deserialize call.
      throw StateError(
          'Unexpected message from the Dart Build Daemon\n $message');
    }
  }

  static bool _isActionMessage(String line) =>
      line == versionSkew || line == readyToConnectLog || line == optionsSkew;

  static Future<BuildDaemonClient> connect(
      String workingDirectory, List<String> daemonCommand,
      {Serializers serializersOverride}) async {
    var process = await Process.start(
        daemonCommand.first, daemonCommand.sublist(1),
        mode: ProcessStartMode.detachedWithStdio,
        workingDirectory: workingDirectory);

    // Print errors coming from the Dart Build Daemon to help with debugging.
    process.stderr.transform(utf8.decoder).listen(print);
    var stream = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
    // Forward output from the daemon until an action message is provided.
    // TODO(grouma) - we probably should use a logger here.
    var sub = stream.where((line) => !_isActionMessage(line)).listen(print);
    var result = await stream.firstWhere(_isActionMessage, orElse: () => null);
    if (result == null) {
      throw Exception('Unable to start build daemon.');
    } else if (result == versionSkew) {
      throw VersionSkew();
    } else if (result == optionsSkew) {
      throw OptionsSkew();
    }
    await sub.cancel();
    var port = _existingPort(workingDirectory);
    var client = BuildDaemonClient._();
    await client._connect(workingDirectory, port, serializersOverride);
    return client;
  }

  static int _existingPort(String workingDirectory) {
    var portFile = File(portFilePath(workingDirectory));
    if (!portFile.existsSync()) throw Exception('Unable to read port file.');
    return int.parse(portFile.readAsStringSync());
  }
}

class VersionSkew extends Error {}

class OptionsSkew extends Error {}
