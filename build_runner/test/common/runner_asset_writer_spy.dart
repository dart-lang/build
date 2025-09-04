// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build_runner/src/internal.dart';

class RunnerAssetWriterSpy implements RunnerAssetWriter {
  final RunnerAssetWriter _delegate;
  final _assetsWritten = <AssetId>{};

  final _assetsDeleted = <AssetId>{};
  Iterable<AssetId> get assetsDeleted => _assetsDeleted;

  RunnerAssetWriterSpy(this._delegate);

  @override
  Future<void> writeAsBytes(AssetId id, List<int> bytes) {
    _assetsWritten.add(id);
    return _delegate.writeAsBytes(id, bytes);
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) {
    _assetsWritten.add(id);
    return _delegate.writeAsString(id, contents, encoding: encoding);
  }

  @override
  Future<void> delete(AssetId id) {
    _assetsDeleted.add(id);
    return _delegate.delete(id);
  }

  @override
  Future<void> deleteDirectory(AssetId id) => _delegate.deleteDirectory(id);
}
