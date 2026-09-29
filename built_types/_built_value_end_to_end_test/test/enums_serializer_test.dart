// Copyright (c) 2020, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
// @dart=2.12

import 'dart:convert';

import 'package:_built_value_end_to_end_test/enums.dart';
import 'package:_built_value_end_to_end_test/serializers.dart';
import 'package:test/test.dart';

void main() {
  group('TestEnum', () {
    final data = TestEnum.yes;
    final serialized = json.decode(json.encode(['TestEnum', 'yes'])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('NewConstructorEnum', () {
    final data = NewConstructorEnum.yes;
    final serialized =
        json.decode(json.encode(['NewConstructorEnum', 'yes'])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('WireNameEnum', () {
    final data = WireNameEnum.yes;
    final serialized = json.decode(json.encode(['E', 'y'])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('WireNumberEnum', () {
    final data = WireNumberEnum.yes;
    final serialized =
        json.decode(json.encode(['WireNumberEnum', 1])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('FallbackEnum', () {
    final data = FallbackEnum.no;
    final serialized =
        json.decode(json.encode(['FallbackEnum', 'some_unrecognized_value']))
            as Object;

    test('deserializes using fallback', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('FallbackNumberEnum', () {
    final data = FallbackNumberEnum.no;
    final serialized =
        json.decode(json.encode(['FallbackNumberEnum', 75])) as Object;

    test('deserializes using fallback', () {
      expect(serializers.deserialize(serialized), data);
    });
  });
}
