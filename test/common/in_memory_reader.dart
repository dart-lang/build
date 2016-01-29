// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

class InMemoryAssetReader implements AssetReader {
  final Map<AssetId, String> assets;

  InMemoryAssetReader(this.assets);

  Future<bool> hasInput(AssetId id) {
    return new Future.value(assets.containsKey(id));
  }

  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async {
    if (!await hasInput(id)) throw new AssetNotFoundException(id);
    return assets[id];
  }
}
