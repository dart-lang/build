// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  group('BuiltMap with known specifiedType but missing builder', () {
    final data = BuiltMap<int, String>({1: 'one', 2: 'two', 3: 'three'});
    final specifiedType =
        const FullType(BuiltMap, [FullType(int), FullType(String)]);
    final serializers = Serializers();
    final serialized =
        json.decode(json.encode([1, 'one', 2, 'two', 3, 'three'])) as Object;

    test('cannot be serialized', () {
      expect(() => serializers.serialize(data, specifiedType: specifiedType),
          throwsA(const TypeMatcher<StateError>()));
    });

    test('cannot be deserialized', () {
      expect(
          () =>
              serializers.deserialize(serialized, specifiedType: specifiedType),
          throwsA(const TypeMatcher<DeserializationError>()));
    });
  });

  group('BuiltMap with known specifiedType and correct builder', () {
    final data = BuiltMap<int, String>({1: 'one', 2: 'two', 3: 'three'});
    final specifiedType =
        const FullType(BuiltMap, [FullType(int), FullType(String)]);
    final serializers = (Serializers().toBuilder()
          ..addBuilderFactory(specifiedType, MapBuilder<int, String>.new))
        .build();
    final serialized =
        json.decode(json.encode([1, 'one', 2, 'two', 3, 'three'])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });

    test('keeps generic type when deserialized', () {
      expect(
          serializers
              .deserialize(serialized, specifiedType: specifiedType)
              .runtimeType,
          BuiltMap<int, String>().runtimeType);
    });
  });

  group('BuiltMap nested left with known specifiedType', () {
    final data = BuiltMap<BuiltMap<int, String>, String>({
      BuiltMap<int, String>({1: 'one'}): 'one!',
      BuiltMap<int, String>({2: 'two'}): 'two!'
    });
    const innerTypeLeft = FullType(BuiltMap, [FullType(int), FullType(String)]);
    final specifiedType =
        const FullType(BuiltMap, [innerTypeLeft, FullType(String)]);
    final serializers = (Serializers().toBuilder()
          ..addBuilderFactory(innerTypeLeft, MapBuilder<int, String>.new)
          ..addBuilderFactory(
              specifiedType, MapBuilder<BuiltMap<int, String>, String>.new))
        .build();
    final serialized = json.decode(json.encode([
      [1, 'one'],
      'one!',
      [2, 'two'],
      'two!'
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('BuiltMap nested right with known specifiedType', () {
    final data = BuiltMap<int, BuiltMap<String, String>>({
      1: BuiltMap<String, String>({'one': 'one!'}),
      2: BuiltMap<String, String>({'two': 'two!'})
    });
    const innerTypeRight =
        FullType(BuiltMap, [FullType(String), FullType(String)]);
    final specifiedType =
        const FullType(BuiltMap, [FullType(int), innerTypeRight]);
    final serializers = (Serializers().toBuilder()
          ..addBuilderFactory(innerTypeRight, MapBuilder<String, String>.new)
          ..addBuilderFactory(
              specifiedType, MapBuilder<int, BuiltMap<String, String>>.new))
        .build();
    final serialized = json.decode(json.encode([
      1,
      ['one', 'one!'],
      2,
      ['two', 'two!']
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('BuiltMap nested both with known specifiedType', () {
    final data = BuiltMap<BuiltMap<int, int>, BuiltMap<String, String>>({
      BuiltMap<int, int>({1: 1}): BuiltMap<String, String>({'one': 'one!'}),
      BuiltMap<int, int>({2: 2}): BuiltMap<String, String>({'two': 'two!'})
    });
    const builtMapOfIntIntGenericType =
        FullType(BuiltMap, [FullType(int), FullType(int)]);
    const builtMapOfStringStringGenericType =
        FullType(BuiltMap, [FullType(String), FullType(String)]);
    final specifiedType = const FullType(BuiltMap,
        [builtMapOfIntIntGenericType, builtMapOfStringStringGenericType]);
    final serializers = (Serializers().toBuilder()
          ..addBuilderFactory(
              builtMapOfIntIntGenericType, MapBuilder<int, int>.new)
          ..addBuilderFactory(
              builtMapOfStringStringGenericType, MapBuilder<String, String>.new)
          ..addBuilderFactory(specifiedType,
              MapBuilder<BuiltMap<int, int>, BuiltMap<String, String>>.new))
        .build();
    final serialized = json.decode(json.encode([
      [1, 1],
      ['one', 'one!'],
      [2, 2],
      ['two', 'two!']
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });

    test('keeps generic type on deserialization', () {
      final genericSerializer = (serializers.toBuilder()
            ..addBuilderFactory(specifiedType,
                MapBuilder<BuiltMap<int, int>, BuiltMap<String, String>>.new)
            ..addBuilderFactory(
                builtMapOfIntIntGenericType, MapBuilder<int, int>.new)
            ..addBuilderFactory(builtMapOfStringStringGenericType,
                MapBuilder<String, String>.new))
          .build();

      expect(
          genericSerializer
              .deserialize(serialized, specifiedType: specifiedType)
              .runtimeType,
          BuiltMap<BuiltMap<int, int>, BuiltMap<String, String>>().runtimeType);
    });
  });

  group('BuiltMap with Object values', () {
    final data = BuiltMap<int, Object>({1: 'one', 2: 2, 3: 'three'});
    final specifiedType =
        const FullType(BuiltMap, [FullType(int), FullType.unspecified]);
    final serializers = (Serializers().toBuilder()
          ..addBuilderFactory(specifiedType, MapBuilder<int, Object>.new))
        .build();
    final serialized = json.decode(json.encode([
      1,
      ['String', 'one'],
      2,
      ['int', 2],
      3,
      ['String', 'three']
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('BuiltMap with Object keys', () {
    final data = BuiltMap<Object, String>({1: 'one', 'two': 'two', 3: 'three'});
    final specifiedType =
        const FullType(BuiltMap, [FullType.unspecified, FullType(String)]);
    final serializers = (Serializers().toBuilder()
          ..addBuilderFactory(specifiedType, MapBuilder<Object, String>.new))
        .build();
    final serialized = json.decode(json.encode([
      ['int', 1],
      'one',
      ['String', 'two'],
      'two',
      ['int', 3],
      'three'
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('BuiltMap with Object keys and values', () {
    final data = BuiltMap<Object, Object>({1: 'one', 'two': 2, 3: 'three'});
    final specifiedType = const FullType(BuiltMap);
    final serializers = Serializers();
    final serialized = json.decode(json.encode([
      ['int', 1],
      ['String', 'one'],
      ['String', 'two'],
      ['int', 2],
      ['int', 3],
      ['String', 'three']
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });

  group('BuiltMap with unknown specifiedType', () {
    final data = BuiltMap<Object, Object>({1: 'one', 'two': 2, 3: 'three'});
    final specifiedType = FullType.unspecified;
    final serializers = Serializers();
    final serialized = json.decode(json.encode([
      'map',
      ['int', 1],
      ['String', 'one'],
      ['String', 'two'],
      ['int', 2],
      ['int', 3],
      ['String', 'three']
    ])) as Object;

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
