// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';

class OutputDigests {
  final Map<AssetId, Digest?> _digests = {};

  void add(AssetId id, Digest? digest) {
    if (_digests.containsKey(id)) {
      throw StateError('Already output: $id');
    }
    _digests[id] = digest;
  }

  Digest? get(AssetId id) {
    if (!_digests.containsKey(id)) {
      throw StateError('Not output: $id');
    }
    return _digests[id];
  }

  Iterable<MapEntry<AssetId, Digest?>> get digests => _digests.entries;
}

class BuilderOptionsDigests {
  final Map<AssetId, Digest> _digests;

  BuilderOptionsDigests.from(BuiltMap<AssetId, Digest> digests)
    : _digests = digests.toMap();

  BuiltMap<AssetId, Digest> toMap() => _digests.build();

  BuilderOptionsDigests() : _digests = {};

  void add(AssetId id, Digest digest) {
    if (_digests.containsKey(id)) {
      throw StateError('Already output: $id');
    }
    _digests[id] = digest;
  }

  Digest get(AssetId id) {
    if (!_digests.containsKey(id)) {
      throw StateError('Not present: $id');
    }
    return _digests[id]!;
  }

  Iterable<MapEntry<AssetId, Digest?>> get digests => _digests.entries;
}
