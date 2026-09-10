// Copyright (c) 2023, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  final serializers = Serializers();

  group('int32 with known specifiedType', () {
    final data = Int32.MAX_VALUE;
    final serialized = Int32.MAX_VALUE.toInt();
    final specifiedType = const FullType(Int32);

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('int32 with unknown specifiedType', () {
    final data = Int32.MIN_VALUE;
    final serialized =
        json.decode(json.encode(['Int32', Int32.MIN_VALUE.toInt()])) as Object;
    final specifiedType = FullType.unspecified;

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });
}
