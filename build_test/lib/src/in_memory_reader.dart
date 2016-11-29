// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import 'in_memory_writer.dart';

class InMemoryAssetReader implements AssetReader {
  final Map<AssetId, DatedString> assets;

  InMemoryAssetReader(this.assets);

  @override
  Future<bool> hasInput(AssetId id) {
    return new Future.value(assets.containsKey(id));
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async {
    if (!await hasInput(id)) throw new AssetNotFoundException(id);
    return assets[id].value;
  }
}
