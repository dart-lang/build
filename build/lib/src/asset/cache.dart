// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import '../generate/input_set.dart';
import 'asset.dart';
import 'id.dart';
import 'reader.dart';
import 'writer.dart';

/// A basic [Asset] cache by [AssetId].
class AssetCache {
  /// Caches the values for this cache.
  final Map<AssetId, Asset> _cache = {};

  /// Whether or not this value exists in the cache.
  bool contains(AssetId id) => _cache.containsKey(id);

  /// Get [id] from the cache.
  Asset get(AssetId id) => _cache[id];

  /// Put [asset] into the cache.
  ///
  /// By default it will not overwrite existing assets, and will throw if
  /// [asset] already exists.
  void put(Asset asset, {bool overwrite: false}) {
    if (!overwrite && contains(asset.id)) {
      throw new ArgumentError('$asset already exists in the cache.');
    }
    _cache[asset.id] = asset;
  }

  /// Removes [id] from the cache, and returns the [Asset] for it if present.
  Asset remove(AssetId id) => _cache.remove(id);
}

/// An [AssetReader] which takes both an [AssetCache] and an [AssetReader]. It
/// will first look up values in the [AssetCache], and if not present it will
/// use the [AssetReader] and add the [Asset] to the [AssetCache].
class CachedAssetReader extends AssetReader {
  final AssetCache _cache;
  final AssetReader _reader;

  /// Cache of ongoing reads by [AssetId].
  final _pendingReads = <AssetId, Future<String>>{};

  /// Cache of ongoing hasInput checks by [AssetId].
  final _pendingHasInputChecks = <AssetId, Future<bool>>{};

  CachedAssetReader(this._cache, this._reader);

  /// Evicts [id] from the underlying cache.
  void evictFromCache(AssetId id) {
    _cache.remove(id);
  }

  @override
  // Can't use async keyword here because we need to update
  // `_pendingHasInputChecks` synchronously.
  Future<bool> hasInput(AssetId id) {
    try {
      if (_cache.contains(id)) return new Future.value(true);
      return _pendingHasInputChecks.putIfAbsent(id, () async {
        try {
          return _reader.hasInput(id);
        } finally {
          // Make sure we always remove the pending check
          _pendingHasInputChecks.remove(id);
        }
      });
    } catch (e, s) {
      return new Future.error(e, s);
    }
  }

  @override
  // Can't use async keyword here because we need to update
  // `_pendingReads` synchronously.
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) {
    try {
      if (_cache.contains(id)) {
        return new Future.value(_cache.get(id).stringContents);
      }

      return _pendingReads.putIfAbsent(id, () async {
        try {
          var content = await _reader.readAsString(id, encoding: encoding);
          _cache.put(new Asset(id, content));
          return content;
        } finally {
          // Make sure we always remove the pending read
          _pendingReads.remove(id);
        }
      });
    } catch (e, s) {
      return new Future.error(e, s);
    }
  }

  @override
  Stream<AssetId> listAssetIds(Iterable<InputSet> inputSets) =>
      _reader.listAssetIds(inputSets);

  @override
  Future<DateTime> lastModified(AssetId id) => _reader.lastModified(id);
}

/// An [AssetWriter] which takes both an [AssetCache] and an [AssetWriter]. It
/// writes [Asset]s to both always.
///
/// Writes are done synchronously to the cache, and then asynchronously to the
/// [AssetWriter].
class CachedAssetWriter extends AssetWriter {
  final AssetCache _cache;
  final AssetWriter _writer;

  CachedAssetWriter(this._cache, this._writer);

  @override
  // Can't use async keyword here because we need to update `_cache`
  // synchronously.
  Future writeAsString(Asset asset, {Encoding encoding: UTF8}) {
    try {
      _cache.put(asset);
      return _writer.writeAsString(asset, encoding: encoding);
    } catch (e, s) {
      return new Future.error(e, s);
    }
  }

  @override
  // Can't use async keyword here because we need to update `_cache`
  // synchronously.
  Future delete(AssetId id) {
    try {
      _cache.remove(id);
      return _writer.delete(id);
    } catch (e, s) {
      return new Future.error(e, s);
    }
  }
}
