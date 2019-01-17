// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:built_value/serializer.dart';
import 'package:web_socket_channel/io.dart';

import 'constants.dart';
import 'data/build_request.dart';
import 'data/build_status.dart';
import 'data/build_target_request.dart';
import 'data/log_to_paths_request.dart';
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

  /// Adds paths to write usage logs to.
  ///
  /// When the client disconnects these files will no longer be logged to.
  void logToPaths(Iterable<String> paths) {
    var request = LogToPathsRequest((b) => b..paths.replace(paths));
    _channel.sink.add(jsonEncode(_serializers.serialize(request)));
  }

  /// Registers a build target to be built upon any file change.
  ///
  /// Changes that match the patterns in [blackListPattern] will be ignored.
  void registerBuildTarget(String target, Iterable<String> blackListPattern) {
    var request = BuildTargetRequest((b) => b
      ..target = target
      ..blackListPattern.replace(blackListPattern));
    _channel.sink.add(jsonEncode(_serializers.serialize(request)));
  }

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
    var output = stream.where((line) => !_isActionMessage(line)).toList();
    var result = await stream.firstWhere(_isActionMessage, orElse: () => null);

    if (result == null) {
      throw Exception(
          'Unable to start build daemon: ${(await output).join('\n')}');
    } else if (result == versionSkew) {
      throw VersionSkew('${await output}');
    } else if (result == optionsSkew) {
      throw OptionsSkew('${await output}');
    }

    var port = _existingPort(workingDirectory);
    var client = BuildDaemonClient._();
    await client._connect(workingDirectory, port, serializersOverride);
    return client;
  }

  static int _existingPort(String workingDirectory) {
    var portFile = File('${daemonWorkspace(workingDirectory)}'
        '/.dart_build_daemon_port');
    if (!portFile.existsSync()) throw Exception('Unable to read port file.');
    return int.parse(portFile.readAsStringSync());
  }
}

class VersionSkew extends Error {
  final String details;
  VersionSkew(this.details);
}

class OptionsSkew extends Error {
  final String details;
  OptionsSkew(this.details);
}
