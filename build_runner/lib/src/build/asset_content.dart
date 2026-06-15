// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

/// Asset content, digests and conversions.
///
/// On serialization the content is dropped leaving only the digest.
class AssetContent {
  List<int>? _bytes;
  final String? _string;
  final Encoding? _encoding;
  Digest? _digest;

  AssetContent.bytes(List<int> bytes)
    : _bytes = bytes,
      _string = null,
      _encoding = null;

  AssetContent.string(String string, {Encoding encoding = utf8})
    : _bytes = null,
      _string = string,
      _encoding = encoding;

  // Only test instances and deseralized instances can be created without
  // content; `visibleForTesting` allows calls from the same file, which allows
  // calls from the serializer below.
  @visibleForTesting
  AssetContent.digest(Digest digest)
    : _bytes = null,
      _string = null,
      _encoding = null,
      _digest = digest;

  bool get hasContent => _bytes != null || _string != null;

  List<int> get bytes => _bytes ??= _encoding!.encode(_string!);

  String stringValue({Encoding encoding = utf8}) {
    if (_string != null && _encoding == encoding) return _string;
    return encoding.decode(bytes);
  }

  Digest get digest => _digest ??= md5.convert(bytes);
}

class AssetContentSerializer implements PrimitiveSerializer<AssetContent> {
  @override
  Iterable<Type> get types => [AssetContent];

  @override
  String get wireName => 'AssetContent';

  @override
  AssetContent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => AssetContent.digest(
    serializers.deserialize(serialized, specifiedType: const FullType(Digest))
        as Digest,
  );

  @override
  Object serialize(
    Serializers serializers,
    AssetContent object, {
    FullType specifiedType = FullType.unspecified,
  }) => serializers.serialize(
    object.digest,
    specifiedType: const FullType(Digest),
  )!;
}
