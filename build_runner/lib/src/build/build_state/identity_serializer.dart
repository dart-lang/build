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

  final Map<T, int> _ids = Map.identity();
  final List<T> _objects = [];
  List<Object?> _serializedObjects = [];

  /// A serializer wrapping [delegate] to deduplicate by identity.
  IdentitySerializer(this.delegate)
    : _primitiveDelegate = delegate is PrimitiveSerializer<T> ? delegate : null,
      _structuredDelegate =
          delegate is StructuredSerializer<T> ? delegate : null;

  /// Sets the stored object values to [objects].
  ///
  /// Serialized values are indices into this list.
  void deserializeWithObjects(Iterable<T> objects) {
    _ids.clear();
    _objects.clear();
    _serializedObjects.clear();
    for (final object in objects) {
      _objects.add(object);
      _ids[object] = _objects.length - 1;
    }
  }

  /// The list of unique objects encountered since the most recent [reset].
  List<Object?> get serializedObjects => _serializedObjects;

  /// Clears the ID to object and serialized object mappings.
  ///
  /// Call this after serializing or deserializing to avoid retaining objects in
  /// memory; or, don't call it to continue using the same IDs and objects.
  void reset() {
    _ids.clear();
    _objects.clear();
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
  }) => _objects[serialized as int];

  @override
  Object serialize(
    Serializers serializers,
    T object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    // If it has already been seen, return the ID.
    return _ids.putIfAbsent(object, () {
      // Otherwise, serialize it, store the value and serialized value, and
      // return the index of the last of `_objects` as the ID.
      final serialized =
          _primitiveDelegate == null
              ? _structuredDelegate!.serialize(serializers, object)
              : _primitiveDelegate.serialize(serializers, object);
      _serializedObjects.add(serialized);
      return (_objects..add(object)).length - 1;
    });
  }
}
