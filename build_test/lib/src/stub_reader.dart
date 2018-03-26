// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

/// A no-op implementation of [AssetReader].
class StubAssetReader extends AssetReader implements MultiPackageAssetReader {
  StubAssetReader();

  @override
  Future<bool> canRead(AssetId id) => new Future.value(null);

  @override
  Future<List<int>> readAsBytes(AssetId id) => new Future.value(null);

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding}) =>
      new Future.value(null);

  @override
  Stream<AssetId> findAssets(Glob glob, {String package}) => null;

  @override
  Future<Digest> digest(AssetId id) => new Future.value(new Digest([1, 2, 3]));
}
