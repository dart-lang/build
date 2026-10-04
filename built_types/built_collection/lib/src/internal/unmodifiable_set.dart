// Copyright (c) 2020, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection' as collection;

/// An unmodifiable view that preserves the wrapped set's behavior.
class UnmodifiableSetView<E> extends collection.UnmodifiableSetView<E> {
  final Set<E> _set;

  UnmodifiableSetView(this._set) : super(_set);

  // SetBase.first uses an iterator. Forward to _set so SplayTreeSet can
  // splay the minimum element for faster repeated reads.
  @override
  E get first => _set.first;

  // SetBase.last scans the entire set. Forward to _set to use optimized
  // getters provided by sets such as LinkedHashSet and SplayTreeSet.
  @override
  E get last => _set.last;

  // Forward to _set to preserve the behavior of custom sets supplied by
  // SetBuilder.withBase. SetBase relies on toSet(), which may return a
  // different set type.
  @override
  Set<E> intersection(Set<Object?> other) => _set.intersection(other);

  @override
  Set<E> union(Set<E> other) => _set.union(other);

  @override
  Set<E> difference(Set<Object?> other) => _set.difference(other);

  // SetBase.cast does not forward _set's factory for creating sets.
  // Cast _set directly to preserve ordering and identity equality in copies.
  @override
  Set<T> cast<T>() => UnmodifiableSetView<T>(_set.cast<T>());
}
