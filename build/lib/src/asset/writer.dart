// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'id.dart';

/// Abstract class that can write [Asset]s.
abstract class AssetWriter {
  Future writeAsBytes(AssetId id, List<int> bytes);

  Future writeAsString(AssetId id, String contents, {Encoding encoding: UTF8});
}

/// An [AssetWriter] which tracks all [AssetId]s written during it's lifetime.
class AssetWriterSpy implements AssetWriter {
  final AssetWriter _delegate;
  final List<AssetId> _assetsWritten = [];

  AssetWriterSpy(this._delegate);

  Iterable<AssetId> get assetsWritten => _assetsWritten;

  @override
  Future writeAsBytes(AssetId id, List<int> bytes) {
    _assetsWritten.add(id);
    return _delegate.writeAsBytes(id, bytes);
  }

  @override
  Future writeAsString(AssetId id, String contents, {Encoding encoding: UTF8}) {
    _assetsWritten.add(id);
    return _delegate.writeAsString(id, contents, encoding: encoding);
  }
}
