// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// A [Resource] encapsulates the logic for creating and disposing of some
/// expensive object which has a lifecycle.
///
/// Actual [Resource]s should be retrieved using `BuildStep#fetchResource`.
///
/// Build system implementations should be the only users that directly
/// instantiate a [ResourceManager] since they can handle the lifecycle
/// guarantees in a sane way.
class Resource<T> {
  /// Factory method which creates an instance of this resource.
  final FutureOr<T> Function() _create;

  /// Optional method which is given an existing instance that is ready to be
  /// disposed.
  final FutureOr Function(T instance) _userDispose;

  /// A Future instance of this resource if one has ever been requested.
  Future<T> _instance;

  Resource(this._create, {FutureOr Function(T instance) dispose})
      : _userDispose = dispose;

  /// Fetches an actual instance of this resource.
  Future<T> _fetch() {
    _instance ??= new Future.value(_create());
    return _instance;
  }

  /// Disposes the actual instance of this resource if present.
  Future _dispose() {
    if (_instance == null) return new Future.value(null);
    var oldInstance = _instance;
    _instance = null;
    if (_userDispose != null) {
      return oldInstance.then((old) => _userDispose(old));
    } else {
      return new Future.value(null);
    }
  }
}

/// Manages fetching and disposing of a group of [Resource]s.
///
/// This is an internal only API which should only be used by build system
/// implementations and not general end users. Instead end users should use
/// the `buildStep#fetchResource` method to get [Resource]s.
class ResourceManager {
  final _resources = new Set<Resource>();

  /// Fetches an instance of [resource].
  Future<T> fetch<T>(Resource<T> resource) async {
    _resources.add(resource);
    return resource._fetch();
  }

  /// Disposes of all [Resource]s fetched since the last call to [disposeAll].
  Future<Null> disposeAll() {
    var done = Future.wait(_resources.map((r) => r._dispose()));
    _resources.clear();
    return done.then((_) => null);
  }
}
