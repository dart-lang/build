// Copyright (c) 2023, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  final serializers = Serializers();

  group('Uint8List with known specifiedType', () {
    final serialized =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
    final data = base64Decode(serialized);
    final specifiedType = const FullType(Uint8List);

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('UInt8List with unknown specifiedType', () {
    final rawData =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
    final serialized =
        json.decode(json.encode(['UInt8List', rawData])) as Object;
    final data = base64Decode(rawData.toString());
    final specifiedType = FullType.unspecified;

    test('can be serialized', () {
      final serializedBy =
          serializers.serialize(data, specifiedType: specifiedType);
      expect(serializedBy, serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });
}
