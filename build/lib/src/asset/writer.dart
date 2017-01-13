// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'asset.dart';
import 'id.dart';

/// Abstract class that can write [Asset]s.
abstract class AssetWriter {
  Future writeAsBytes(BytesAsset asset);

  Future writeAsString(StringAsset asset, {Encoding encoding: UTF8});
}

/// An [AssetWriter] which tracks all [AssetId]s written during it's lifetime.
class AssetWriterSpy implements AssetWriter {
  final AssetWriter _delegate;
  final List<AssetId> _assetsWritten = [];

  AssetWriterSpy(this._delegate);

  Iterable<AssetId> get assetsWritten => _assetsWritten;

  @override
  Future writeAsBytes(BytesAsset asset) {
    _assetsWritten.add(asset.id);
    return _delegate.writeAsBytes(asset);
  }

  @override
  Future writeAsString(StringAsset asset, {Encoding encoding: UTF8}) {
    _assetsWritten.add(asset.id);
    return _delegate.writeAsString(asset, encoding: encoding);
  }
}
