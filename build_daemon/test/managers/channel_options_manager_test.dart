// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_daemon/src/managers/channel_options_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  test('can add options', () {
    var manager = ChannelOptionsManager();
    var channel = DummyChannel();
    expect(manager.options.isEmpty, isTrue);
    manager.addOption('--foo', channel);
    expect(manager.options.contains('--foo'), isTrue);
  });

  test('when a channel is removed the corresponding option is removed', () {
    var manager = ChannelOptionsManager();
    var channelA = DummyChannel();
    var channelB = DummyChannel();
    manager.addOption('--foo', channelA);
    expect(manager.options.contains('--foo'), isTrue);
    manager.addOption('--bar', channelB);
    expect(manager.options.isNotEmpty, isTrue);
    manager.removeChannel(channelA);
    expect(manager.options.contains('--foo'), isFalse);
    expect(manager.options.contains('--bar'), isTrue);
  });

  test(
      'when multiple channels request and option, '
      'it is only removed when both channels are removed', () {
    var manager = ChannelOptionsManager();
    var channelA = DummyChannel();
    var channelB = DummyChannel();
    manager.addOption('--foo', channelA);
    manager.addOption('--foo', channelB);
    expect(manager.options.contains('--foo'), isTrue);
    manager.removeChannel(channelB);
    expect(manager.options.contains('--foo'), isTrue);
    manager.removeChannel(channelA);
    expect(manager.options.isEmpty, isTrue);
  });
}

class DummyChannel extends Mock implements WebSocketChannel {}
