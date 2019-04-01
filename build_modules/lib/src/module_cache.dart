// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';

import 'meta_module.dart';
import 'modules.dart';

final metaModuleCache = Resource<DecodingCache<MetaModule>>(
    () => DecodingCache((m) => MetaModule.fromJson(m)),
    dispose: (c) => c.dispose());

final moduleCache = Resource<DecodingCache<Module>>(
    () => DecodingCache((m) => Module.fromJson(m)),
    dispose: (c) => c.dispose());

class DecodingCache<T> {
  final _cached = <AssetId, Future<Result<T>>>{};

  final T Function(Map<String, dynamic>) _construct;

  DecodingCache(this._construct);

  void dispose() => _cached.clear();

  Future<T> find(AssetId id, AssetReader reader) async {
    if (!await reader.canRead(id)) return null;
    var result = _cached.putIfAbsent(
        id,
        () => Result.capture(reader
            .readAsString(id)
            .then((c) => jsonDecode(c) as Map<String, dynamic>)
            .then(_construct)));
    return Result.release(result);
  }
}
