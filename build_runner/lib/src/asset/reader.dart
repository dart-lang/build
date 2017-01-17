import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import '../generate/input_set.dart';

abstract class RunnerAssetReader extends AssetReader {
  /// Gets a [Stream<AssetId>] of all assets available matching [inputSets].
  Stream<AssetId> listAssetIds(Iterable<InputSet> inputSets);

  /// Asynchronously gets the last modified [DateTime] of [id].
  Future<DateTime> lastModified(AssetId id);
}

class AssetReaderSpy implements AssetReader {
  final AssetReader _delegate;
  final Set<AssetId> _assetsRead = new Set();

  AssetReaderSpy(this._delegate);

  Iterable<AssetId> get assetsRead => _assetsRead;

  @override
  Future<bool> hasInput(AssetId input) {
    _assetsRead.add(input);
    return _delegate.hasInput(input);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) {
    _assetsRead.add(id);
    return _delegate.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId input, {Encoding encoding: UTF8}) {
    _assetsRead.add(input);
    return _delegate.readAsString(input, encoding: encoding);
  }
}
