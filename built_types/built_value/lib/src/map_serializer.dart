// Copyright (c) 2025, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import '../serializer.dart';

class MapSerializer implements StructuredSerializer<Map> {
  final bool structured = true;
  @override
  final Iterable<Type> types =
      BuiltList<Type>([Map, <Object, Object>{}.runtimeType]);
  @override
  final String wireName = 'Map';

  @override
  Iterable<Object?> serialize(Serializers serializers, Map Map,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);

    final keyType = specifiedType.parameters.isEmpty
        ? FullType.unspecified
        : specifiedType.parameters[0];
    final valueType = specifiedType.parameters.isEmpty
        ? FullType.unspecified
        : specifiedType.parameters[1];

    final result = <Object?>[];
    for (final key in Map.keys) {
      result.add(serializers.serialize(key, specifiedType: keyType));
      final value = Map[key];
      result.add(serializers.serialize(value, specifiedType: valueType));
    }
    return result;
  }

  @override
  Map deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;

    final keyType = specifiedType.parameters.isEmpty
        ? FullType.unspecified
        : specifiedType.parameters[0];
    final valueType = specifiedType.parameters.isEmpty
        ? FullType.unspecified
        : specifiedType.parameters[1];

    final result = isUnderspecified
        ? <Object, Object>{}
        : serializers.newBuilder(specifiedType) as Map;

    if (serialized.length % 2 == 1) {
      throw ArgumentError('odd length');
    }

    for (var i = 0; i != serialized.length; i += 2) {
      final key = serializers.deserialize(serialized.elementAt(i),
          specifiedType: keyType);
      final value = serializers.deserialize(serialized.elementAt(i + 1),
          specifiedType: valueType);
      result[key] = value;
    }

    return result;
  }
}
