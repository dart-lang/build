// Copyright (c) 2020, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection' as collection;

/// An SDK unmodifiable view that forwards set-producing operations to its base.
class UnmodifiableSetView<E> extends collection.UnmodifiableSetView<E> {
  final Set<E> _set;

  UnmodifiableSetView(this._set) : super(_set);

  // SetBase.cast does not forward the base's factory for creating new sets.
  // Casting the base instead preserves its behavior, such as sorting or
  // identity equality, when the cast view produces a new set.
  @override
  Set<T> cast<T>() => UnmodifiableSetView<T>(_set.cast<T>());

  @override
  Set<E> intersection(Set<Object?> other) => _set.intersection(other);

  @override
  Set<E> union(Set<E> other) => _set.union(other);

  @override
  Set<E> difference(Set<Object?> other) => _set.difference(other);
}
