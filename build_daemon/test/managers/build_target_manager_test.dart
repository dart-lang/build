// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_daemon/data/build_target_request.dart';
import 'package:build_daemon/src/managers/build_target_manager.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  test('can add build targets', () {
    var manager = BuildTargetManager();
    var channel = DummyChannel();
    var request = BuildTargetRequest((b) => b
      ..target = 'foo'
      ..blackListPattern = ListBuilder());
    expect(manager.targets.isEmpty, isTrue);
    manager.addBuildTarget(request, channel);
    expect(
        manager.targets.map((target) => target.target).toList().contains('foo'),
        isTrue);
  });

  test('when a channel is removed the corresponding target is removed', () {
    var manager = BuildTargetManager();
    var channelA = DummyChannel();
    var channelB = DummyChannel();
    var requestA = BuildTargetRequest((b) => b
      ..target = 'foo'
      ..blackListPattern = ListBuilder());
    manager.addBuildTarget(requestA, channelA);
    expect(
        manager.targets.map((target) => target.target).toList().contains('foo'),
        isTrue);
    var requestB = BuildTargetRequest((b) => b
      ..target = 'bar'
      ..blackListPattern = ListBuilder());
    manager.addBuildTarget(requestB, channelB);
    expect(manager.targets.isNotEmpty, isTrue);
    manager.removeChannel(channelA);
    expect(
        manager.targets.map((target) => target.target).toList().contains('foo'),
        isFalse);
    expect(
        manager.targets.map((target) => target.target).toList().contains('bar'),
        isTrue);
  });

  test(
      'when multiple channels are listening to a target, '
      'it is only removed when both channels are removed', () {
    var manager = BuildTargetManager();
    var channelA = DummyChannel();
    var channelB = DummyChannel();
    var request = BuildTargetRequest((b) => b
      ..target = 'foo'
      ..blackListPattern = ListBuilder());
    manager.addBuildTarget(request, channelA);
    manager.addBuildTarget(request, channelB);
    expect(
        manager.targets.map((target) => target.target).toList().contains('foo'),
        isTrue);
    manager.removeChannel(channelB);
    expect(
        manager.targets.map((target) => target.target).toList().contains('foo'),
        isTrue);
    manager.removeChannel(channelA);
    expect(manager.targets.isEmpty, isTrue);
  });

  test(
      'a build target will be reused if the target and the blackListPattern '
      'is the same', () {
    var manager = BuildTargetManager();
    var channelA = DummyChannel();
    var channelB = DummyChannel();
    var requestA = BuildTargetRequest((b) => b
      ..target = 'foo'
      ..blackListPattern = ListBuilder(['bar']));
    var requestB = BuildTargetRequest((b) => b
      ..target = 'foo'
      ..blackListPattern = ListBuilder(['bar']));
    manager.addBuildTarget(requestA, channelA);
    manager.addBuildTarget(requestB, channelB);
    expect(manager.targets.length, 1);
  });

  test('different blackListPatterns result in different build targets', () {
    var manager = BuildTargetManager();
    var channelA = DummyChannel();
    var channelB = DummyChannel();
    var requestA = BuildTargetRequest((b) => b
      ..target = 'foo'
      ..blackListPattern = ListBuilder());
    var requestB = BuildTargetRequest((b) => b
      ..target = 'foo'
      ..blackListPattern = ListBuilder(['bar']));
    manager.addBuildTarget(requestA, channelA);
    manager.addBuildTarget(requestB, channelB);
    expect(manager.targets.length, 2);
  });

  test(
      'correctly uses the blackListPattern to filter build targets for changes',
      () {
    var manager = BuildTargetManager();
    var channel = DummyChannel();
    var request = BuildTargetRequest((b) => b
      ..target = 'foo'
      ..blackListPattern = ListBuilder([r'.*_test\.dart$']));
    manager.addBuildTarget(request, channel);
    var targets = manager.targetsForChanges(
        [WatchEvent(ChangeType.ADD, 'foo/bar/blah/some_file.dart')]);
    expect(targets.map((target) => target.target).toList().contains('foo'),
        isTrue);
    targets = manager.targetsForChanges(
        [WatchEvent(ChangeType.ADD, 'foo/bar/blah/some_test.dart')]);
    expect(targets.isEmpty, isTrue);
  });
}

class DummyChannel extends Mock implements WebSocketChannel {}
