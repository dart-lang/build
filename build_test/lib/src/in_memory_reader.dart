// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';
import 'dart:typed_data';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:glob/glob.dart';

/// An [AssetReader] that records which assets have been read to [assetsRead].
abstract class RecordingAssetReader implements AssetReader {
  Set<AssetId> get assetsRead;
}

/// An implementation of [AssetReader] and [AssetWriter] with primed in-memory
/// assets.
///
/// TODO(davidmorgan): merge into `FileBasedReader` and `FileBasedWriter`.
class InMemoryAssetReaderWriter extends AssetReader
    implements InMemoryAssetReader, InMemoryAssetWriter {
  @override
  late final AssetFinder assetFinder = FunctionAssetFinder(_findAssets);

  final InMemoryFilesystem _filesystem = InMemoryFilesystem();

  final String? rootPackage;

  @override
  final InputTracker inputTracker = InputTracker();

  /// Create a new asset reader/writer.
  ///
  /// May optionally define a [rootPackage], which is required for some APIs.
  InMemoryAssetReaderWriter({this.rootPackage});

  @override
  AssetPathProvider? get assetPathProvider => null;

  @override
  Filesystem get filesystem => _filesystem;

  @override
  Map<AssetId, List<int>> get assets => _filesystem.assets;

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
  Future writeAsBytes(AssetId id, List<int> bytes) async {
    assets[id] = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  }

  @override
  Future writeAsString(AssetId id, String contents,
      {Encoding encoding = utf8}) async {
    assets[id] = encoding.encode(contents) as Uint8List;
  }
}

/// An implementation of [AssetReader] with primed in-memory assets.
abstract class InMemoryAssetReader implements AssetReader, AssetReaderState {
  abstract final Map<AssetId, List<int>> assets;

  /// Create a new asset reader.
  ///
  /// May optionally define a [rootPackage], which is required for some APIs.
  factory InMemoryAssetReader({String? rootPackage}) =>
      InMemoryAssetReaderWriter(rootPackage: rootPackage);
}

/// An implementation of [AssetWriter] that writes outputs to memory.
abstract class InMemoryAssetWriter implements AssetWriter {
  abstract final Map<AssetId, List<int>> assets;

  factory InMemoryAssetWriter() => InMemoryAssetReaderWriter();

  @override
  Future writeAsBytes(AssetId id, List<int> bytes);

  @override
  Future writeAsString(AssetId id, String contents, {Encoding encoding = utf8});
}
