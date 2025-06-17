// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:pool/pool.dart';

/// A single resource pool which supports an extra [withSharedResource]
/// method for concurrent shared access to the resource.
///
/// Useful for read/write operations.
class SharedResourcePool extends Pool {
  Future<PoolResource>? __sharedResource;
  Future<PoolResource>? get _sharedResource => __sharedResource;
  set _sharedResource(Future<PoolResource>? resource) {
    if (resource == null && _sharedResourceCount != 0) {
      throw StateError('Shared resource was released but still has references');
    } else if (resource != null && _sharedResourceCount != 1) {
      throw StateError(
        'Attempted to create a new shared resource but there are already '
        '${_sharedResourceCount - 1} references (expected 0).',
      );
    }
    __sharedResource = resource;
  }

  int _sharedResourceCount = 0;

  SharedResourcePool() : super(1);

  /// Any number of entities can access the same shared resource.
  ///
  /// Note that this can starve calls to `withResource` as the shared resource
  /// will not be released until there are no more references to it, and there
  /// is no limit on the number of concurrent or total references.
  Future<T> withSharedResource<T>(FutureOr<T> Function() callback) async {
    if (isClosed) {
      throw StateError(
        'withSharedResource() may not be called on a closed Pool.',
      );
    }
    _sharedResourceCount++;
    _sharedResource ??= request();
    var resource = await _sharedResource!;

    try {
      return await callback();
    } finally {
      _sharedResourceCount--;
      if (_sharedResourceCount == 0) {
        resource.release();
        _sharedResource = null;
      }
    }
  }
}
