// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

/// An implementation of [AssetWriter] that records outputs to [assets].
abstract class RecordingAssetWriter implements AssetWriter {
  Map<AssetId, List<int>> get assets;
}

/// An implementation of [AssetWriter] that writes outputs to memory.
class InMemoryAssetWriter implements RecordingAssetWriter {
  @override
  final Map<AssetId, List<int>> assets = {};

  InMemoryAssetWriter();

  @override
  Future writeAsBytes(AssetId id, List<int> bytes) async {
    assets[id] = bytes;
  }

  @override
  Future writeAsString(AssetId id, String contents,
      {Encoding encoding: utf8}) async {
    assets[id] = encoding.encode(contents);
  }
}
