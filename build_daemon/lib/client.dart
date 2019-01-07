// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/io.dart';

import 'constants.dart';
import 'data/build_options_request.dart';
import 'data/build_request.dart';
import 'data/build_status.dart';
import 'data/build_target_request.dart';
import 'data/log_to_paths_request.dart';
import 'data/serializers.dart';
import 'data/server_log.dart';

class BuildDaemonClient {
  IOWebSocketChannel _channel;

  final _buildResults = StreamController<BuildResults>.broadcast();

  final _serverLogStreamController = StreamController<ServerLog>.broadcast();

  BuildDaemonClient._();

  Stream<BuildResults> get buildResults => _buildResults.stream;
  Future<void> get finished async {
    if (_channel != null) await _channel.sink.done;
  }

  Stream<ServerLog> get serverLogs => _serverLogStreamController.stream;

  /// Adds a list of build options to be used for all builds.
  ///
  /// When this client disconnects these options will no longer be used by the
  /// build daemon.
  void addBuildOptions(Iterable<String> options) {
    var request = BuildOptionsRequest((b) => b..options.replace(options));
    _channel.sink.add(jsonEncode(serializers.serialize(request)));
  }

  /// Adds paths to write usage logs to.
  ///
  /// When the client disconnects these files will no longer be logged to.
  void logToPaths(Iterable<String> paths) {
    var request = LogToPathsRequest((b) => b..paths.replace(paths));
    _channel.sink.add(jsonEncode(serializers.serialize(request)));
  }

  /// Registers a build target to be built upon any file change.
  ///
  /// Changes that match the patterns in [blackListPattern] will be ignored.
  void registerBuildTarget(String target, Iterable<String> blackListPattern) {
    var request = BuildTargetRequest((b) => b
      ..target = target
      ..blackListPattern.replace(blackListPattern));
    _channel.sink.add(jsonEncode(serializers.serialize(request)));
  }

  /// Builds all registered targets.
  void startBuild() {
    var request = BuildRequest();
    _channel.sink.add(jsonEncode(serializers.serialize(request)));
  }

  Future<void> _connect(String workingDirectory, int port) async {
    _channel = IOWebSocketChannel.connect('ws://localhost:$port');
    _channel.stream.listen(_handleServerMessage)
      // TODO(grouma) - Implement proper error handling.
      ..onError(print);
  }

  void _handleServerMessage(dynamic data) {
    var message = serializers.deserialize(jsonDecode(data as String));
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

  static Future<BuildDaemonClient> connect(String workingDirectory,
      {String daemonCommand = ''}) async {
    Process process;
    if (daemonCommand.isEmpty) {
      process = await Process.start(
          'pub', ['run', 'build_daemon', workingDirectory],
          mode: ProcessStartMode.detachedWithStdio);
    } else {
      process = await Process.start(daemonCommand, [workingDirectory],
          mode: ProcessStartMode.detachedWithStdio);
    }
    // Print errors coming from the Dart Build Daemon to help with debugging.
    process.stderr.transform(utf8.decoder).listen(print);
    var result = await process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .firstWhere((line) => line == versionSkew || line == readyToConnectLog);

    if (result == versionSkew) {
      throw VersionSkew();
    }

    var port = _existingPort(workingDirectory);
    var client = BuildDaemonClient._();
    await client._connect(workingDirectory, port);
    return client;
  }

  static int _existingPort(String workingDirectory) {
    var portFile = File('${daemonWorkspace(workingDirectory)}'
        '/.dart_build_daemon_port');
    if (!portFile.existsSync()) throw Exception('Unable to read port file.');
    return int.parse(portFile.readAsStringSync());
  }
}

class VersionSkew extends Error {}
