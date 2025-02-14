// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:glob/glob.dart';

/// An [AssetReader] that records which assets have been read to [assetsRead].
abstract class RecordingAssetReader implements AssetReader {
  Set<AssetId> get assetsRead;
}

/// An implementation of [AssetWriter] that records outputs to [assets].
abstract class RecordingAssetWriter implements AssetWriter {
  Map<AssetId, List<int>> get assets;
}

/// An implementation of [AssetReader] and [AssetWriter] with primed in-memory
/// assets.
class InMemoryAssetReaderWriter extends AssetReader
    implements InMemoryAssetReader, InMemoryAssetWriter {
  @override
  late final AssetFinder assetFinder = FunctionAssetFinder(_findAssets);

  @override
  final Map<AssetId, List<int>> assets;
  final String? rootPackage;

  @override
  final InputTracker inputTracker = InputTracker();

  @override
  Set<AssetId> get assetsRead => inputTracker.assetsRead;

  /// Create a new asset reader that contains [sourceAssets].
  ///
  /// Any strings in [sourceAssets] will be converted into a `List<int>` of
  /// bytes.
  ///
  /// May optionally define a [rootPackage], which is required for some APIs.
  InMemoryAssetReaderWriter(
      {Map<AssetId, dynamic>? sourceAssets, this.rootPackage})
      : assets = _assetsAsBytes(sourceAssets);

  @override
  AssetPathProvider? get assetPathProvider => null;

  static Map<AssetId, List<int>> _assetsAsBytes(Map<AssetId, dynamic>? assets) {
    if (assets == null || assets.isEmpty) {
      return {};
    }
    final output = <AssetId, List<int>>{};
    assets.forEach((id, stringOrBytes) {
      if (stringOrBytes is List<int>) {
        output[id] = stringOrBytes;
      } else if (stringOrBytes is String) {
        output[id] = utf8.encode(stringOrBytes);
      } else {
        throw UnsupportedError('Invalid asset contents: $stringOrBytes.');
      }
    });
    return output;
  }

  @override
  Future<bool> canRead(AssetId id) async {
    inputTracker.assetsRead.add(id);
    return assets.containsKey(id);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    if (!await canRead(id)) throw AssetNotFoundException(id);
    inputTracker.assetsRead.add(id);
    return assets[id]!;
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    if (!await canRead(id)) throw AssetNotFoundException(id);
    inputTracker.assetsRead.add(id);
    return encoding.decode(assets[id]!);
  }

  // This is only for generators, so only `BuildStep` needs to implement it.
  @override
  Stream<AssetId> findAssets(Glob glob) => throw UnimplementedError();

  Stream<AssetId> _findAssets(Glob glob, String? package) {
    package ??= rootPackage;
    if (package == null) {
      throw UnsupportedError(
          'Root package is required to use findAssets without providing an '
          'explicit package.');
    }
    return Stream.fromIterable(assets.keys
        .where((id) => id.package == package && glob.matches(id.path)));
  }

  @override
  void cacheBytesAsset(AssetId id, List<int> bytes) {
    assets[id] = bytes;
  }

  @override
  void cacheStringAsset(AssetId id, String contents, {Encoding? encoding}) {
    encoding ??= utf8;
    assets[id] = encoding.encode(contents);
  }

  @override
  Future writeAsBytes(AssetId id, List<int> bytes) async {
    assets[id] = bytes;
  }

  @override
  Future writeAsString(AssetId id, String contents,
      {Encoding encoding = utf8}) async {
    assets[id] = encoding.encode(contents);
  }
}

/// An implementation of [AssetReader] with primed in-memory assets.
abstract class InMemoryAssetReader
    implements AssetReader, RecordingAssetReader, AssetReaderState {
  abstract final Map<AssetId, List<int>> assets;

  /// Create a new asset reader that contains [sourceAssets].
  ///
  /// Any strings in [sourceAssets] will be converted into a `List<int>` of
  /// bytes.
  ///
  /// May optionally define a [rootPackage], which is required for some APIs.
  factory InMemoryAssetReader(
          {Map<AssetId, dynamic>? sourceAssets, String? rootPackage}) =>
      InMemoryAssetReaderWriter(
          sourceAssets: sourceAssets, rootPackage: rootPackage);

  /// Create a new asset reader backed by [assets].
  // InMemoryAssetReader.shareAssetCache(this.assets, {this.rootPackage});

  void cacheBytesAsset(AssetId id, List<int> bytes);

  void cacheStringAsset(AssetId id, String contents, {Encoding? encoding});
}

/// An implementation of [AssetWriter] that writes outputs to memory.
abstract class InMemoryAssetWriter implements RecordingAssetWriter {
  factory InMemoryAssetWriter() => InMemoryAssetReaderWriter();

  @override
  Future writeAsBytes(AssetId id, List<int> bytes) async {
    assets[id] = bytes;
  }

  @override
  Future writeAsString(AssetId id, String contents,
      {Encoding encoding = utf8}) async {
    assets[id] = encoding.encode(contents);
  }
}
