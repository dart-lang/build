// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:built_value/serializer.dart';
import 'package:pool/pool.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:stream_transform/stream_transform.dart' hide concat;
import 'package:watcher/watcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../daemon_builder.dart';
import '../data/build_request.dart';
import '../data/build_target.dart';
import '../data/build_target_request.dart';
import '../data/serializers.dart';
import 'managers/build_target_manager.dart';

class Server {
  final _isDoneCompleter = Completer();
  final BuildTargetManager _buildTargetManager;
  final _pool = Pool(1);
  final Serializers _serializers;
  Timer _timeout;

  HttpServer _server;
  DaemonBuilder _builder;
  final _channels = Set<WebSocketChannel>();
  // Channels that are interested in the current build.
  var _interestedChannels = Set<WebSocketChannel>();

  final _subs = <StreamSubscription>[];

  Server(this._builder, Stream<WatchEvent> changes,
      {Serializers serializersOverride,
      bool Function(BuildTarget, Iterable<WatchEvent>) shouldBuild})
      : _serializers = serializersOverride ?? serializers,
        _buildTargetManager =
            BuildTargetManager(shouldBuildOverride: shouldBuild) {
    _forwardData();
    _handleChanges(changes);

    // Stop the server if nobody connects.
    _timeout = Timer(Duration(seconds: 30), () async {
      if (_buildTargetManager.isEmpty) {
        await stop();
      }
    });
  }

  Future<void> get onDone => _isDoneCompleter.future;

  Future<int> listen() async {
    var handler = webSocketHandler((WebSocketChannel channel) async {
      _channels.add(channel);

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
          await _build(_buildTargetManager.targets, <WatchEvent>[]);
        }
      }, onDone: () {
        _channels.remove(channel);
        _removeChannel(channel);
      });
    });
    _server = await serve(handler, 'localhost', 0);
    return _server.port;
  }

  Future<void> stop() async {
    _timeout.cancel();
    await _server?.close(force: true);
    await _builder?.stop();
    for (var sub in _subs) {
      await sub.cancel();
    }
    if (!_isDoneCompleter.isCompleted) _isDoneCompleter.complete();
  }

  Future<void> _build(
          Set<BuildTarget> buildTargets, Iterable<WatchEvent> changes) =>
      _pool.withResource(() {
        _interestedChannels =
            buildTargets.expand(_buildTargetManager.channels).toSet();
        return _builder.build(buildTargets, changes);
      });

  void _forwardData() {
    _subs.add(_builder.logs.listen((log) {
      var message = jsonEncode(_serializers.serialize(log));
      for (var channel in _interestedChannels) {
        channel.sink.add(message);
      }
    }));
    _subs.add(_builder.builds.listen((status) {
      var message = jsonEncode(_serializers.serialize(status));
      for (var channel in _interestedChannels) {
        channel.sink.add(message);
      }
    }));
  }

  void _handleChanges(Stream<WatchEvent> changes) {
    _subs.add(changes.transform(asyncMapBuffer((changes) async {
      if (changes.isEmpty) return;
      if (_buildTargetManager.targets.isEmpty) return;
      var buildTargets = _buildTargetManager.targetsForChanges(changes);
      if (buildTargets.isEmpty) return;
      await _build(buildTargets, changes);
    })).listen((_) {}));
  }

  void _removeChannel(WebSocketChannel channel) async {
    _buildTargetManager.removeChannel(channel);
    if (_buildTargetManager.isEmpty) {
      await stop();
    }
  }
}
