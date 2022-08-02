// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:protobuf/protobuf.dart';

/// State held by the [MessageGrouper] while waiting for additional data to
/// arrive.
class MessageGrouperState {
  /// Reads the initial length.
  var _lengthReader = _LengthReader();

  /// Reads messages from a stream of bytes.
  _MessageReader? _messageReader;

  /// Handle one byte at a time.
  ///
  /// Returns a [List<int>] of message bytes if [byte] was the last byte in a
  /// message, otherwise returns [null].
  List<int>? handleInput(int byte) {
    if (!_lengthReader.done) {
      _lengthReader.readByte(byte);
      if (_lengthReader.done) {
        _messageReader = _MessageReader(_lengthReader.length);
      }
    } else {
      assert(_messageReader != null);
      _messageReader!.readByte(byte);
    }

    if (_lengthReader.done && _messageReader!.done) {
      var message = _messageReader!.message;
      reset();
      return message;
    }

    return null;
  }

  /// Reset the state so that we are ready to receive the next message.
  void reset() {
    _lengthReader = _LengthReader();
    _messageReader = null;
  }
}

/// Reads a length one byte at a time.
///
/// The base-128 encoding is in little-endian order, with the high bit set on
/// all bytes but the last.  This was chosen since it's the same as the
/// base-128 encoding used by protobufs, so it allows a modest amount of code
/// reuse at the other end of the protocol.
class _LengthReader {
  /// Whether or not we are done reading the length.
  bool get done => _done;
  bool _done = false;

  /// If [_done] is `true`, the decoded value of the length bytes received so
  /// far (if any), otherwise unitialized.
  late int _length;

  /// The length read in.  You are only allowed to read this if [_done] is
  /// `true`.
  int get length {
    assert(_done);
    return _length;
  }

  final List<int> _buffer = <int>[];

  /// Read a single byte into [_length].
  void readByte(int byte) {
    assert(!_done);
    _buffer.add(byte);

    // Check for the last byte in the length, and then read it.
    if ((byte & 0x80) == 0) {
      _done = true;
      var reader = CodedBufferReader(_buffer);
      _length = reader.readInt32();
    }
  }
}

/// Reads some number of bytes from a stream, one byte at a time.
class _MessageReader {
  /// Whether or not we are done reading bytes from the stream.
  bool get done => _done;
  bool _done;

  /// The total length of the message to be read.
  final int _length;

  /// A [Uint8List] which holds the message data. You are only allowed to read
  /// this if [_done] is `true`.
  Uint8List get message {
    assert(_done);
    return _message;
  }

  final Uint8List _message;

  /// If [_done] is `false`, the number of message bytes that have been received
  /// so far.  Otherwise zero.
  int _numMessageBytesReceived = 0;

  _MessageReader(int length)
      : _message = Uint8List(length),
        _length = length,
        _done = length == 0;

  /// Reads [byte] into [_message].
  void readByte(int byte) {
    assert(!done);

    _message[_numMessageBytesReceived++] = byte;
    if (_numMessageBytesReceived == _length) _done = true;
  }
}
