// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

class InMemoryAssetWriter implements AssetWriter {
  final Map<AssetId, String> assets = {};

  InMemoryAssetWriter();

  Future writeAsString(Asset asset, {Encoding encoding: UTF8}) async {
    assets[asset.id] = asset.stringContents;
  }

  Future delete(AssetId id) async {
    assets.remove(id);
  }
}
