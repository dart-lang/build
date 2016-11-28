// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'asset.dart';
import 'id.dart';

abstract class AssetWriter {
  Future writeAsString(Asset asset, {Encoding encoding: UTF8});

  Future delete(AssetId id);
}

/// An [AssetWriter] which tracks all assets written during it's lifetime.
class AssetWriterSpy implements AssetWriter {
  final AssetWriter _delegate;
  final List<Asset> _assetsWritten = [];

  AssetWriterSpy(this._delegate);

  Iterable<Asset> get assetsWritten => _assetsWritten;

  @override
  Future writeAsString(Asset asset, {Encoding encoding: UTF8}) {
    _assetsWritten.add(asset);
    return _delegate.writeAsString(asset, encoding: encoding);
  }

  @override
  Future delete(AssetId id) => _delegate.delete(id);
}
