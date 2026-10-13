// Copyright (c) 2020, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
// @dart=2.12

import 'dart:convert';

import 'package:_built_value_end_to_end_test/imported_values.dart';
import 'package:_built_value_end_to_end_test/serializers.dart';
import 'package:_built_value_end_to_end_test/values.dart';
import 'package:built_collection/built_collection.dart';
import 'package:test/test.dart';

void main() {
  group('ImportedValue', () {
    final data = ImportedValue((b) => b.simpleValue
      ..anInt = 1
      ..aString = 'two');
    final serialized = json.decode(json.encode([
      'ImportedValue',
      'simpleValue',
      [
        'anInt',
        1,
        'aString',
        'two',
      ],
      'simpleValues',
      <Object>[],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('ImportedCustomValue', () {
    final data = ImportedCustomValue((b) => b
      ..simpleValue = SimpleValue((b) => b
        ..anInt = 1
        ..aString = 'two')
      ..simpleValues = BuiltList.of([]));
    final serialized = json.decode(json.encode([
      'ImportedCustomValue',
      'simpleValue',
      [
        'anInt',
        1,
        'aString',
        'two',
      ],
      'simpleValues',
      <Object>[],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('ImportedCustomNestedValue', () {
    final data = ImportedCustomNestedValue((b) => b.simpleValue
      ..anInt = 1
      ..aString = 'two');
    final serialized = json.decode(json.encode([
      'ImportedCustomNestedValue',
      'simpleValue',
      [
        'anInt',
        1,
        'aString',
        'two',
      ],
      'simpleValues',
      <Object>[],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });
}
