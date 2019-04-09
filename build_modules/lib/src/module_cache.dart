// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';

import 'meta_module.dart';
import 'modules.dart';

final metaModuleCache = DecodingCache.resource((m) => MetaModule.fromJson(m));

final moduleCache = DecodingCache.resource((m) => Module.fromJson(m));

/// A cache of objects decoded from written assets suitable for use as a
/// [Resource].
///
/// Instances that are decoded will be cached throughout the duration of a build
/// and invalidated between builds. Instances that are shared through the cache
/// should be treated as immutable to avoid leaking any information which was
/// not loaded from the underlying asset.
class DecodingCache<T> {
  /// Create a [Resource] which can decoded instances of [T] serialized via json
  /// to assets.
  static Resource<DecodingCache<T>> resource<T>(
          T Function(Map<String, dynamic>) _fromJson) =>
      Resource<DecodingCache<T>>(() => DecodingCache._(_fromJson),
          dispose: (c) => c._dispose());

  final _cached = <AssetId, Future<Result<T>>>{};

  final T Function(Map<String, dynamic>) _fromJson;

  DecodingCache._(this._fromJson);

  void _dispose() => _cached.clear();

  /// Find and deserialize a [T] stored in [id].
  ///
  /// If the asset at [id] is unreadable the returned future will resolve to
  /// `null`. If the instance is cached it will not be decoded again, but the
  /// content dependencies will be tracked through [reader].
  Future<T> find(AssetId id, AssetReader reader) async {
    if (!await reader.canRead(id)) return null;
    var result = _cached.putIfAbsent(
        id,
        () => Result.capture(reader
            .readAsString(id)
            .then((c) => jsonDecode(c) as Map<String, dynamic>)
            .then(_fromJson)));
    return Result.release(result);
  }
}
