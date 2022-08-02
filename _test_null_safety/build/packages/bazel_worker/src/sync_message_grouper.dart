// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'message_grouper.dart';
import 'message_grouper_state.dart';

/// Groups bytes in delimited proto format into the bytes for each message.
class SyncMessageGrouper implements MessageGrouper {
  final _state = MessageGrouperState();
  final Stdin _stdin;

  SyncMessageGrouper(this._stdin);

  /// Blocks until the next full message is received, and then returns it.
  ///
  /// Returns null at end of file.
  @override
  List<int>? get next {
    try {
      List<int>? message;
      while (message == null) {
        var nextByte = _stdin.readByteSync();
        if (nextByte == -1) return null;
        message = _state.handleInput(nextByte);
      }
      return message;
    } catch (e) {
      // It appears we sometimes get an exception instead of -1 as expected when
      // stdin closes, this handles that in the same way (returning a null
      // message)
      return null;
    }
  }
}
