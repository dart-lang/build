import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart' show AssetWriter, Asset, AssetId;

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
