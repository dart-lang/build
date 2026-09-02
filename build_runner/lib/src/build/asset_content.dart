// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../contracts.dart';

/// Asset content with bytes and/or string in memory and an optional cached digest.
///
/// If only bytes are stored, conversion to string with [stringValue] is cached.
/// If only a string is stored, conversion to bytes with [bytes] is cached.
@Invariant('_bytes != null || _string != null')
class AssetContent {
  List<int>? _bytes;
  String? _string;
  Encoding? _encoding;
  Digest? _digest;

  @Pre('bytes != null')
  AssetContent.bytes(List<int> bytes, {Digest? digest})
    : _bytes = bytes,
      _string = null,
      _encoding = null,
      _digest = digest;

  @Pre('string != null')
  AssetContent.string(String string, {Encoding encoding = utf8, Digest? digest})
    : _bytes = null,
      _string = string,
      _encoding = encoding,
      _digest = digest;

  List<int> get bytes => _bytes ??= _encoding!.encode(_string!);

  String stringValue({Encoding encoding = utf8}) {
    if (_string != null && _encoding == encoding) return _string!;
    final string = encoding.decode(bytes);
    if (_string == null) {
      _string = string;
      _encoding = encoding;
    }
    return string;
  }

  /// Returns a copy with [newBytes].
  ///
  /// If this instance has a digest, it is copied without checking that
  /// [newBytes] matches the digest. This supports the current build_runner
  /// behavior that manual changes to output content are ignored, see
  /// https://github.com/dart-lang/build/issues/4985.
  @Pre('newBytes != null')
  @Post('result != null')
  AssetContent withBytes(List<int> newBytes) {
    if (_bytes == newBytes) return this;
    final result = AssetContent.bytes(newBytes);
    if (_digest != null) result._digest = _digest;
    return result;
  }

  Digest get digest => _digest ??= md5.convert(bytes);
}
