// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// A basic LRU Cache.
class LruCache<K, V> {
  _Entry<K, V>? _head;
  _Entry<K, V>? _tail;

  final int Function(V) _computeWeight;

  int _currentWeightTotal = 0;
  final int _individualWeightMax;
  final int _totalWeightMax;

  final _entries = <K, _Entry<K, V>>{};

  LruCache(
    this._individualWeightMax,
    this._totalWeightMax,
    this._computeWeight,
  );

  V? operator [](K key) {
    final entry = _entries[key];
    if (entry == null) return null;

    _promote(entry);
    return entry.value;
  }

  void operator []=(K key, V value) {
    remove(key);
    final entry = _Entry(key, value, _computeWeight(value));
    // Don't cache at all if above the individual weight max.
    if (entry.weight > _individualWeightMax) {
      return;
    }

    _entries[key] = entry;
    _currentWeightTotal += entry.weight;
    _promote(entry);

    while (_currentWeightTotal > _totalWeightMax) {
      remove(_tail!.key);
    }
  }

  /// Removes the value at [key] from the cache, and returns the value if it
  /// existed.
  V? remove(K key) {
    final entry = _entries[key];
    if (entry == null) return null;

    _currentWeightTotal -= entry.weight;
    _entries.remove(key);

    // Remove from linked list.
    entry.previous?.next = entry.next;
    entry.next?.previous = entry.previous;

    if (entry == _tail) {
      _tail = entry.next;
    }
    if (entry == _head) {
      _head = entry.previous;
    }

    return entry.value;
  }

  /// Moves [link] to the [_head] of the list.
  void _promote(_Entry<K, V> link) {
    if (link == _head) return;

    if (link == _tail) {
      _tail = link.next;
    }

    // Remove from linked list.
    link.previous?.next = link.next;
    link.next?.previous = link.previous;

    _head?.next = link;
    link.previous = _head;
    _head = link;
    _tail ??= link;
    link.next = null;
  }

  @visibleForTesting
  int get linkedListLength {
    var result = 0;
    var current = _head;
    while (current != null) {
      ++result;
      current = current.previous;
    }
    return result;
  }
}

/// An entry in an [LruCache] which is also a part of a doubly linked list.
class _Entry<K, V> {
  _Entry<K, V>? next;
  _Entry<K, V>? previous;

  final int weight;

  final K key;

  final V value;

  _Entry(this.key, this.value, this.weight);
}
