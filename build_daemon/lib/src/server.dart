// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build_daemon/data/continue_request.dart';
import 'package:built_value/serializer.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../change_provider.dart';
import '../constants.dart';
import '../daemon_builder.dart';
import '../data/build_request.dart';
import '../data/build_target.dart';
import '../data/build_target_request.dart';
import '../data/serializers.dart';
import '../data/shutdown_notification.dart';
import 'managers/build_target_manager.dart';

/// A server which communicates with build daemon clients over websockets.
///
/// Handles notifying clients of logs and results for registered build targets.
/// Note the server will only notify clients of pertinent events.
class Server {
  final _isDoneCompleter = Completer();
  final BuildTargetManager _buildTargetManager;
  final Serializers _serializers;
  final ChangeProvider _changeProvider;
  final BuildMode _buildMode;
  final _manualChanges = StreamController<List<WatchEvent>>();
  final _continueController = StreamController<void>();

  Timer _timeout;

  HttpServer _server;
  final DaemonBuilder _builder;
  // Channels that are interested in the current build.
  var _interestedChannels = <WebSocketChannel>{};

  final _subs = <StreamSubscription>[];

  Server(this._builder, Duration timeout, ChangeProvider changeProvider,
      this._buildMode,
      {Serializers serializersOverride,
      bool Function(BuildTarget, Iterable<WatchEvent>) shouldBuild})
      : _changeProvider = changeProvider,
        _serializers = serializersOverride ?? serializers,
        _buildTargetManager =
            BuildTargetManager(shouldBuildOverride: shouldBuild) {
    _forwardData();

    _handleChanges(changeProvider.changes, _manualChanges.stream);

    // Stop the server if nobody connects.
    _timeout = Timer(timeout, () async {
      if (_buildTargetManager.isEmpty) {
        await stop();
      }
    });
  }

  Future<void> get onDone => _isDoneCompleter.future;

  /// Starts listening for build daemon clients.
  Future<int> listen() async {
    var handler = webSocketHandler((WebSocketChannel channel) async {
      channel.stream.listen((message) async {
        dynamic request;
        try {
          request = _serializers.deserialize(jsonDecode(message as String));
        } catch (_) {
          print('Unable to parse message: $message');
          return;
        }
        if (request is BuildTargetRequest) {
          _buildTargetManager.addBuildTarget(request.target, channel);
        } else if (request is BuildRequest) {
          var changes = await _changeProvider.collectChanges();
          _manualChanges.add(changes);
        } else if (request is ContinueRequest) {
          _continueController.add(null);
        }
      }, onDone: () {
        _removeChannel(channel);
      });
    });

    _server = await HttpMultiServer.loopback(0);
    serveRequests(_server, handler);
    return _server.port;
  }

  Future<void> stop({String message, int failureType}) async {
    message ??= '';
    failureType ??= 0;
    if (message.isNotEmpty && failureType != 0) {
      for (var connection in _buildTargetManager.allChannels) {
        connection.sink
            .add(jsonEncode(_serializers.serialize(ShutdownNotification((b) => b
              ..message = message
              ..failureType = failureType))));
      }
    }
    _timeout.cancel();
    await _server?.close(force: true);
    await _builder?.stop();
    for (var sub in _subs) {
      await sub.cancel();
    }
    if (!_isDoneCompleter.isCompleted) _isDoneCompleter.complete();
  }

  void _forwardData() {
    _subs
      ..add(_builder.logs.listen((log) {
        var message = jsonEncode(_serializers.serialize(log));
        for (var channel in _interestedChannels) {
          channel.sink.add(message);
        }
      }))
      ..add(_builder.builds.listen((status) {
        var message = jsonEncode(_serializers.serialize(status));
        for (var channel in _interestedChannels) {
          channel.sink.add(message);
        }
      }));
  }

  void _handleChanges(
    Stream<List<WatchEvent>> autoChanges,
    Stream<List<WatchEvent>> manualChanges,
  ) {
    if (_buildMode == BuildMode.Step) {
      autoChanges = autoChanges
          .buffer(_continueController.stream)
          .map((changesList) => changesList.expand((x) => x).toList());
    }
    _subs.add(
        autoChanges.merge(manualChanges).asyncMapBuffer((changesLists) async {
      var changes = changesLists.expand((x) => x).toList();
      var buildTargets = changes.isEmpty
          ? _buildTargetManager.targets
          : _buildTargetManager.targetsForChanges(changes);
      if (buildTargets.isEmpty) return;
      _interestedChannels =
          buildTargets.expand(_buildTargetManager.channels).toSet();
      await _builder.build(buildTargets, changes);
    }).listen((_) {}));
  }

  void _removeChannel(WebSocketChannel channel) async {
    _buildTargetManager.removeChannel(channel);
    if (_buildTargetManager.isEmpty) {
      await stop();
    }
  }
}
