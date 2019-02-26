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

int _existingPort(String workingDirectory) {
  var portFile = File(portFilePath(workingDirectory));
  if (!portFile.existsSync()) throw MissingPortFile();
  return int.parse(portFile.readAsStringSync());
}

Future<void> _handleDaemonStartup(
  Process process,
  void Function(ServerLog) logHandler,
) async {
  process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    logHandler(ServerLog((b) => b..log = line));
  });
  var stream = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .asBroadcastStream();

  // The daemon may log critical information prior to it successfully
  // starting. Capture this data and forward to the logHandler.
  var sub = stream.where((line) => !_isActionMessage(line)).listen((line) {
    logHandler(ServerLog((b) => b..log = line));
  });

  var daemonAction =
      await stream.firstWhere(_isActionMessage, orElse: () => null);

  if (daemonAction == null) {
    throw StateError('Unable to start build daemon.');
  } else if (daemonAction == versionSkew) {
    throw VersionSkew();
  } else if (daemonAction == optionsSkew) {
    throw OptionsSkew();
  }
  await sub.cancel();
}

bool _isActionMessage(String line) =>
    line == versionSkew || line == readyToConnectLog || line == optionsSkew;

class BuildDaemonClient {
  final _buildResults = StreamController<BuildResults>.broadcast();
  final Serializers _serializers;

  IOWebSocketChannel _channel;

  BuildDaemonClient._(
    int port,
    this._serializers,
    void Function(ServerLog) logHandler,
  ) {
    _channel = IOWebSocketChannel.connect('ws://localhost:$port')
      ..stream.listen((data) {
        var message = _serializers.deserialize(jsonDecode(data as String));
        if (message is ServerLog) {
          logHandler(message);
        } else if (message is BuildResults) {
          _buildResults.add(message);
        } else {
          // In practice we should never reach this state due to the
          // deserialize call.
          throw StateError(
              'Unexpected message from the Dart Build Daemon\n $message');
        }
      })
          // TODO(grouma) - Implement proper error handling.
          .onError(print);
  }

  Stream<BuildResults> get buildResults => _buildResults.stream;
  Future<void> get finished async => await _channel.sink.done;

  /// Registers a build target to be built upon any file change.
  void registerBuildTarget(BuildTarget target) => _channel.sink.add(jsonEncode(
      _serializers.serialize(BuildTargetRequest((b) => b..target = target))));

  /// Builds all registered targets.
  void startBuild() {
    var request = BuildRequest();
    _channel.sink.add(jsonEncode(_serializers.serialize(request)));
  }

  Future<void> close() => _channel.sink.close();

  static Future<BuildDaemonClient> connect(
      String workingDirectory, List<String> daemonCommand,
      {Serializers serializersOverride,
      void Function(ServerLog) logHandler}) async {
    logHandler ??= (_) {};
    var daemonSerializers = serializersOverride ?? serializers;

    var process = await Process.start(
        daemonCommand.first, daemonCommand.sublist(1),
        mode: ProcessStartMode.detachedWithStdio,
        workingDirectory: workingDirectory);

    await _handleDaemonStartup(process, logHandler);

    return BuildDaemonClient._(
        _existingPort(workingDirectory), daemonSerializers, logHandler);
  }
}

class MissingPortFile implements Exception {}

class OptionsSkew implements Exception {}

class VersionSkew implements Exception {}
