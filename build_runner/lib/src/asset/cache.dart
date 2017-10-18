// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

class CachingAssetReader implements AssetReader {
  final _cache = <AssetId, Future<dynamic>>{};
  final AssetReader _wrapped;

  CachingAssetReader(this._wrapped);

  @override
  Future<bool> canRead(AssetId id) => _wrapped.canRead(id);

  @override
  Stream<AssetId> findAssets(Glob glob, {String package}) =>
      throw new UnimplementedError('unimplemented!');

  @override
  Future<List<int>> readAsBytes(AssetId id) =>
      _cache.putIfAbsent(id, () => _wrapped.readAsBytes(id)).then((value) {
        if (value is List<int>) return value;
        if (value is String) return UTF8.encode(value);
        throw new StateError('Unrecognized cached type ${value.runtimeType}');
      });

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) =>
      _cache.putIfAbsent(id, () => _wrapped.readAsString(id)).then((value) {
        if (value is String) return value;
        if (value is List<int>) return encoding.decode(value);
        throw new StateError('Unrecognized cached type ${value.runtimeType}');
      });
}
