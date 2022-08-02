// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:protobuf/protobuf.dart';

import 'message_grouper.dart';

/// Collects stream data into messages by interpreting it as
/// base-128 encoded lengths interleaved with raw data.
class AsyncMessageGrouper implements MessageGrouper {
  /// The input stream.
  final StreamQueue<List<int>> _inputQueue;

  /// The current input buffer.
  List<int> _inputBuffer = [];

  /// Position in the current input buffer.
  int _inputBufferPos = 0;

  /// Completes after [cancel] is called or [inputStream] is closed.
  Future<void> get done => _done.future;
  final _done = Completer<void>();

  /// Whether currently reading length or raw data.
  bool _readingLength = true;

  /// If reading length, buffer to build up length one byte at a time until
  /// done.
  List<int> _lengthBuffer = [];

  /// If reading raw data, buffer for the data.
  Uint8List _message = Uint8List(0);

  /// If reading raw data, position in the buffer.
  int _messagePos = 0;

  AsyncMessageGrouper(Stream<List<int>> inputStream)
      : _inputQueue = StreamQueue(inputStream);

  /// Returns the next full message that is received, or null if none are left.
  @override
  Future<List<int>?> get next async {
    try {
      // Loop while there is data in the input buffer or the input stream.
      while (
          _inputBufferPos != _inputBuffer.length || await _inputQueue.hasNext) {
        // If the input buffer is empty fill it from the input stream.
        if (_inputBufferPos == _inputBuffer.length) {
          _inputBuffer = await _inputQueue.next;
          _inputBufferPos = 0;
        }

        // Loop over the input buffer. Might return without reading the full
        // buffer if a message completes. Then, this is tracked in
        // `_inputBufferPos`.
        while (_inputBufferPos != _inputBuffer.length) {
          if (_readingLength) {
            // Reading message length byte by byte.
            var byte = _inputBuffer[_inputBufferPos++];
            _lengthBuffer.add(byte);
            // Check for the last byte in the length, and then read it.
            if ((byte & 0x80) == 0) {
              var reader = CodedBufferReader(_lengthBuffer);
              var length = reader.readInt32();
              _lengthBuffer = [];

              // Special case: don't keep reading an empty message, return it
              // and `_readingLength` stays true.
              if (length == 0) {
                return Uint8List(0);
              }

              // Switch to reading raw data. Allocate message buffer and reset
              // `_messagePos`.
              _readingLength = false;
              _message = Uint8List(length);
              _messagePos = 0;
            }
          } else {
            // Copy as much as possible from the input buffer. Limit is the
            // smaller of the remaining length to fill in the message and the
            // remaining length in the buffer.
            var lengthToCopy = min(_message.length - _messagePos,
                _inputBuffer.length - _inputBufferPos);
            _message.setRange(
                _messagePos,
                _messagePos + lengthToCopy,
                _inputBuffer.sublist(
                    _inputBufferPos, _inputBufferPos + lengthToCopy));
            _messagePos += lengthToCopy;
            _inputBufferPos += lengthToCopy;

            // If there is a complete message to return, return it and switch
            // back to reading length.
            if (_messagePos == _message.length) {
              var result = _message;
              // Don't keep a reference to the message.
              _message = Uint8List(0);
              _readingLength = true;
              return result;
            }
          }
        }
      }

      // If there is nothing left in the queue then cancel the subscription.
      unawaited(cancel());
    } catch (e) {
      // It appears we sometimes get an exception instead of -1 as expected when
      // stdin closes, this handles that in the same way (returning a null
      // message)
      return null;
    }
  }

  /// Stop listening to the stream for further updates.
  Future cancel() {
    if (!_done.isCompleted) {
      _done.complete(null);
      return _inputQueue.cancel()!;
    }
    return done;
  }
}
