// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/serializer.dart';

/// Wraps another `built_value` serializer to add serializing by identity.
///
/// Integer IDs are created as new values are encountered, and a mapping to
/// objects and serialized object values is maintained.
///
/// The serialized data does not contain the object values, only IDs. This might
/// not matter if this `IdentitySerializer` will stay in memory and be used to
/// deserialize. Or, the serialized object values must be serialized separately:
/// they can be obtained from [serializedObjects], and set via
/// [deserializeWithObjects].
///
/// TODO(davidmorgan): consider upstreaming to `built_value`.
class IdentitySerializer<T> implements PrimitiveSerializer<T> {
  final Serializer<T> delegate;
  final PrimitiveSerializer<T>? _primitiveDelegate;
  final StructuredSerializer<T>? _structuredDelegate;
  final FullType specifiedType;

  Map<T, int> _ids = Map.identity();
  List<T?> _objects = [];
  List<Object?> _serializedObjects = [];

  int lastTried = 0;

  /// A serializer wrapping [delegate] to deduplicate by identity.
  IdentitySerializer(this.delegate)
    : _primitiveDelegate = delegate is PrimitiveSerializer<T> ? delegate : null,
      _structuredDelegate =
          delegate is StructuredSerializer<T> ? delegate : null,
      specifiedType = FullType(delegate.types.first);

  /// Sets the stored object values to [objects].
  ///
  /// Serialized values are indices into this list.
  /*void deserializeWithObjects(Iterable<T> objects) {
    _ids.clear();
    _objects.clear();
    _serializedObjects.clear();
    for (final object in objects) {
      _objects.add(object);
      _ids[object] = _objects.length - 1;
    }
  }*/

  void deserializeObjects(List<Object?> serializedObjects) {
    _ids.clear();
    _serializedObjects = serializedObjects;
    _objects = List.filled(_serializedObjects.length, null);
    /*print('got ${_serializedObjects.length}');
    print('into ${_objects.length}');
    try {
      for (var i = _serializedObjects.length - 1; i != -1; --i) {
        print('deserialize $i ${_serializedObjects[i]}');
        if (_primitiveDelegate != null) {
          _objects[i] = _primitiveDelegate.deserialize(
            serializers,
            _serializedObjects[i]!,
          );
        } else {
          _objects[i] = _structuredDelegate!.deserialize(
            serializers,
            _serializedObjects[i] as Iterable,
          );
          _ids[_objects[i] as T] = i;
        }
      }
    } catch (e, st) {
      print('$e $st');
      rethrow;
    }*/
  }

  /// The list of unique objects encountered since the most recent [reset].
  List<Object?> serializedObjects(Serializers serializers) {
    while (_serializedObjects.length < _objects.length) {
      // print('$_serializedObjects, $_objects');
      final object = _objects[_serializedObjects.length]!;
      final serialized =
          _primitiveDelegate == null
              ? _structuredDelegate!.serialize(serializers, object)
              : _primitiveDelegate.serialize(serializers, object);
      _serializedObjects.add(serialized);
    }
    return _serializedObjects;
  }

  /// Clears the ID to object and serialized object mappings.
  ///
  /// Call this after serializing or deserializing to avoid retaining objects in
  /// memory; or, don't call it to continue using the same IDs and objects.
  void reset() {
    _ids = {};
    _objects = [];
    _serializedObjects = [];
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
    serialized as int;
    if (_objects[serialized] == null) {
      if (_primitiveDelegate != null) {
        _objects[serialized] = _primitiveDelegate.deserialize(
          serializers,
          _serializedObjects[serialized]!,
        );
      } else {
        _objects[serialized] = _structuredDelegate!.deserialize(
          serializers,
          _serializedObjects[serialized] as Iterable,
        );
        _ids[_objects[serialized] as T] = serialized;
      }
    }
    return _objects[serialized]!;
  }

  @override
  Object serialize(
    Serializers serializers,
    T object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    // If it has already been seen, return the ID.
    return _ids.putIfAbsent(object, () {
      // print('add $object');
      return (_objects..add(object)).length - 1;
    });
  }
}
