// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/serializer.dart';

class IdentitySerializer<T> implements PrimitiveSerializer<T> {
  final Serializer<T> delegate;
  final PrimitiveSerializer<T>? _primitiveDelegate;
  final StructuredSerializer<T>? _structuredDelegate;

  final Map<T, int> _ids = Map.identity();
  final List<T> _objects = [];
  final List<Object?> _serializedObjects = [];

  IdentitySerializer(this.delegate)
    : _primitiveDelegate = delegate is PrimitiveSerializer<T> ? delegate : null,
      _structuredDelegate =
          delegate is StructuredSerializer<T> ? delegate : null;

  Iterable<Object?> get serializedObjects => _serializedObjects;

  void setObjects(Iterable<T> objects) {
    _ids.clear();
    _objects.clear();
    for (final object in objects) {
      _objects.add(object);
      _ids[object] = _objects.length - 1;
    }
  }

  @override
  Iterable<Type> get types => delegate.types;

  @override
  String get wireName => delegate.wireName;

  @override
  T deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _objects[serialized as int];
  }

  // TODO: check equality vs identity?
  @override
  Object serialize(
    Serializers serializers,
    T object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _ids.putIfAbsent(object, () {
      final serialized =
          _primitiveDelegate == null
              ? _structuredDelegate!.serialize(serializers, object)
              : _primitiveDelegate!.serialize(serializers, object);
      _serializedObjects.add(serialized);
      return (_objects..add(object)).length - 1;
    });
  }
}

class _ListIterator<T> implements Iterator<T> {
  final List<T> list;
  int index = -1;

  _ListIterator(this.list);

  @override
  bool moveNext() => ++index < list.length;

  @override
  T get current => list[index];
}
