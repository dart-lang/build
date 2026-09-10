// Copyright (c) 2025, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  group('Map with known specifiedType but missing builder', () {
    final data = <int, String>{1: 'one', 2: 'two', 3: 'three'};
    final specifiedType =
        const FullType(Map, [FullType(int), FullType(String)]);
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

  group('Map with known specifiedType and correct builder', () {
    final data = <int, String>{1: 'one', 2: 'two', 3: 'three'};
    final specifiedType =
        const FullType(Map, [FullType(int), FullType(String)]);
    final serializers = (Serializers().toBuilder()
          ..addBuilderFactory(specifiedType, () => <int, String>{}))
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
          <int, String>{}.runtimeType);
    });
  });

  group('Map nested left with known specifiedType', () {
    final data = <Map<int, String>, String>{
      <int, String>{1: 'one'}: 'one!',
      <int, String>{2: 'two'}: 'two!'
    };
    const innerTypeLeft = FullType(Map, [FullType(int), FullType(String)]);
    final specifiedType =
        const FullType(Map, [innerTypeLeft, FullType(String)]);
    final serializers = (Serializers().toBuilder()
          ..addBuilderFactory(innerTypeLeft, () => <int, String>{})
          ..addBuilderFactory(
              specifiedType, () => <Map<int, String>, String>{}))
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
      // `expect` does not deep compare `Map` by key, `toString` is close
      // enough.
      expect(
          serializers
              .deserialize(serialized, specifiedType: specifiedType)
              .toString(),
          data.toString());
    });
  });

  group('Map nested right with known specifiedType', () {
    final data = <int, Map<String, String>>{
      1: <String, String>{'one': 'one!'},
      2: <String, String>{'two': 'two!'}
    };
    const innerTypeRight = FullType(Map, [FullType(String), FullType(String)]);
    final specifiedType = const FullType(Map, [FullType(int), innerTypeRight]);
    final serializers = (Serializers().toBuilder()
          ..addBuilderFactory(innerTypeRight, () => <String, String>{})
          ..addBuilderFactory(
              specifiedType, () => <int, Map<String, String>>{}))
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

  group('Map nested both with known specifiedType', () {
    final data = <Map<int, int>, Map<String, String>>{
      <int, int>{1: 1}: <String, String>{'one': 'one!'},
      <int, int>{2: 2}: <String, String>{'two': 'two!'}
    };
    const MapOfIntIntGenericType =
        FullType(Map, [FullType(int), FullType(int)]);
    const MapOfStringStringGenericType =
        FullType(Map, [FullType(String), FullType(String)]);
    final specifiedType = const FullType(
        Map, [MapOfIntIntGenericType, MapOfStringStringGenericType]);
    final serializers = (Serializers().toBuilder()
          ..addBuilderFactory(MapOfIntIntGenericType, () => <int, int>{})
          ..addBuilderFactory(
              MapOfStringStringGenericType, () => <String, String>{})
          ..addBuilderFactory(
              specifiedType, () => <Map<int, int>, Map<String, String>>{}))
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
      // `expect` does not deep compare `Map` by key, `toString` is close
      // enough.
      expect(
          serializers
              .deserialize(serialized, specifiedType: specifiedType)
              .toString(),
          data.toString());
    });

    test('keeps generic type on deserialization', () {
      final genericSerializer = (serializers.toBuilder()
            ..addBuilderFactory(
                specifiedType, () => <Map<int, int>, Map<String, String>>{})
            ..addBuilderFactory(MapOfIntIntGenericType, () => <int, int>{})
            ..addBuilderFactory(
                MapOfStringStringGenericType, () => <String, String>{}))
          .build();

      expect(
          genericSerializer
              .deserialize(serialized, specifiedType: specifiedType)
              .runtimeType,
          <Map<int, int>, Map<String, String>>{}.runtimeType);
    });
  });

  group('Map with Object values', () {
    final data = <int, Object>{1: 'one', 2: 2, 3: 'three'};
    final specifiedType =
        const FullType(Map, [FullType(int), FullType.unspecified]);
    final serializers = (Serializers().toBuilder()
          ..addBuilderFactory(specifiedType, () => <int, Object>{}))
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

  group('Map with Object keys', () {
    final data = <Object, String>{1: 'one', 'two': 'two', 3: 'three'};
    final specifiedType =
        const FullType(Map, [FullType.unspecified, FullType(String)]);
    final serializers = (Serializers().toBuilder()
          ..addBuilderFactory(specifiedType, () => <Object, String>{}))
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

  group('Map with Object keys and values', () {
    final data = <Object, Object>{1: 'one', 'two': 2, 3: 'three'};
    final specifiedType = const FullType(Map);
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

  group('Map with unknown specifiedType', () {
    final data = <Object, Object>{1: 'one', 'two': 2, 3: 'three'};
    final specifiedType = FullType.unspecified;
    final serializers = Serializers();
    final serialized = json.decode(json.encode([
      'Map',
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
