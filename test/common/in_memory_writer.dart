// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

class InMemoryAssetWriter implements AssetWriter {
  final Map<AssetId, DatedString> assets = {};

  InMemoryAssetWriter();

  Future writeAsString(Asset asset,
      {Encoding encoding: UTF8, DateTime lastModified}) async {
    assets[asset.id] = new DatedString(asset.stringContents, lastModified);
  }

  Future delete(AssetId id) async {
    assets.remove(id);
  }
}

class DatedString {
  final String value;
  final DateTime date;

  DatedString(this.value, [DateTime date]) : date = date ?? new DateTime.now();
}
