// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:crypto/crypto.dart';

import 'meta_module.dart';
import 'modules.dart';

Map<String, dynamic> _deserialize(List<int> bytes) =>
    jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

List<int> _serialize(Map<String, dynamic> data) =>
    utf8.encode(jsonEncode(data));

final metaModuleCache = DecodingCache.resource(
    (m) => MetaModule.fromJson(_deserialize(m)), (m) => _serialize(m.toJson()));

final moduleCache = DecodingCache.resource(
    (m) => Module.fromJson(_deserialize(m)), (m) => _serialize(m.toJson()));

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
          T Function(List<int>) fromBytes, List<int> Function(T) toBytes) =>
      Resource<DecodingCache<T>>(() => DecodingCache._(fromBytes, toBytes),
          dispose: (c) => c._dispose());

  final _cached = <AssetId, _Entry<T>>{};

  final T Function(List<int>) _fromBytes;
  final List<int> Function(T) _toBytes;

  DecodingCache._(this._fromBytes, this._toBytes);

  void _dispose() {
    _cached.removeWhere((_, entry) => entry.digest == null);
    for (var entry in _cached.values) {
      entry.needsCheck = true;
    }
  }

  /// Find and deserialize a [T] stored in [id].
  ///
  /// If the asset at [id] is unreadable the returned future will resolve to
  /// `null`. If the instance is cached it will not be decoded again, but the
  /// content dependencies will be tracked through [reader].
  Future<T> find(AssetId id, AssetReader reader) async {
    if (!await reader.canRead(id)) return null;
    _Entry<T> entry;
    if (!_cached.containsKey(id)) {
      entry = _cached[id] = _Entry()
        ..needsCheck = false
        ..value = Result.capture(reader.readAsBytes(id).then(_fromBytes))
        ..digest = Result.capture(reader.digest(id));
    } else {
      entry = _cached[id];
      if (entry.needsCheck) {
        await (entry.onGoingCheck ??= () async {
          var previousDigest = await Result.release(entry.digest);
          entry.digest = Result.capture(reader.digest(id));
          if (await Result.release(entry.digest) != previousDigest) {
            entry.value =
                Result.capture(reader.readAsBytes(id).then(_fromBytes));
          }
          entry
            ..needsCheck = false
            ..onGoingCheck = null;
        }());
      }
    }
    return Result.release(entry.value);
  }

  /// Serialized and write a [T] to [id].
  ///
  /// The instance will be cached so that later calls to [find] may return the
  /// instances without deserializing it.
  Future<void> write(AssetId id, AssetWriter writer, T instance) async {
    await writer.writeAsBytes(id, _toBytes(instance));
    _cached[id] = _Entry()
      ..needsCheck = false
      ..value = Result.capture(Future.value(instance));
  }
}

class _Entry<T> {
  bool needsCheck = false;
  Future<Result<T>> value;
  Future<Result<Digest>> digest;
  Future<void> onGoingCheck;
}
