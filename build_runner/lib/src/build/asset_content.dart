// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Asset content with bytes or string in memory and an optional cached digest.
class AssetContent {
  List<int>? _bytes;
  final String? _string;
  final Encoding? _encoding;
  Digest? _digest;

  AssetContent.bytes(List<int> bytes, {Digest? digest})
    : _bytes = bytes,
      _string = null,
      _encoding = null,
      _digest = digest;

  AssetContent.string(String string, {Encoding encoding = utf8, Digest? digest})
    : _bytes = null,
      _string = string,
      _encoding = encoding,
      _digest = digest;

  List<int> get bytes => _bytes ??= _encoding!.encode(_string!);

  String stringValue({Encoding encoding = utf8}) {
    if (_string != null && _encoding == encoding) return _string;
    return encoding.decode(bytes);
  }

  /// Returns a copy with [newBytes].
  ///
  /// If this instance has a digest, it is copied without checking that
  /// [newBytes] matches the digest. This supports the current build_runner
  /// behavior that manual changes to output content are ignored, see
  /// https://github.com/dart-lang/build/issues/4985.
  AssetContent withBytes(List<int> newBytes) {
    if (_bytes == newBytes) return this;
    final result = AssetContent.bytes(newBytes);
    if (_digest != null) result._digest = _digest;
    return result;
  }

  Digest get digest => _digest ??= md5.convert(bytes);
}
