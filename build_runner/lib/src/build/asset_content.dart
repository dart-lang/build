// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Asset content and conversions.
class AssetContent {
  List<int>? _bytes;
  final String? _string;
  final Encoding? _encoding;

  AssetContent.bytes(List<int> bytes)
    : _bytes = bytes,
      _string = null,
      _encoding = null;

  AssetContent.string(String string, {Encoding encoding = utf8})
    : _bytes = null,
      _string = string,
      _encoding = encoding;

  List<int> get bytes => _bytes ??= _encoding!.encode(_string!);

  String stringValue({Encoding encoding = utf8}) {
    if (_string != null && _encoding == encoding) return _string;
    return encoding.decode(bytes);
  }

  Digest get digest => md5.convert(bytes);
}
