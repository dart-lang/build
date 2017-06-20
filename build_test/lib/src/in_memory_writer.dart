// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

/// An implementation of [AssetWriter] that records outputs to [assets].
abstract class RecordingAssetWriter implements AssetWriter {
  Map<AssetId, DatedValue> get assets;
}

/// An implementation of [AssetWriter] that writes outputs to memory.
class InMemoryAssetWriter implements RecordingAssetWriter {
  @override
  final Map<AssetId, DatedValue> assets = {};

  InMemoryAssetWriter();

  @override
  Future writeAsBytes(AssetId id, List<int> bytes,
      {Encoding encoding: UTF8, DateTime lastModified}) async {
    assets[id] = new DatedBytes(bytes, lastModified);
  }

  @override
  Future writeAsString(AssetId id, String contents,
      {Encoding encoding: UTF8, DateTime lastModified}) async {
    assets[id] = new DatedString(contents, lastModified);
  }
}

abstract class DatedValue {
  final DateTime date;

  String get stringValue;
  List<int> get bytesValue;

  DatedValue([DateTime date]) : date = date ?? new DateTime.now();
}

class DatedString extends DatedValue {
  @override
  final stringValue;

  @override
  List<int> get bytesValue => UTF8.encode(stringValue);

  DatedString(this.stringValue, [DateTime date]) : super(date);
}

class DatedBytes extends DatedValue {
  @override
  final bytesValue;

  @override
  String get stringValue => UTF8.decode(bytesValue);

  DatedBytes(this.bytesValue, [DateTime date]) : super(date);
}
