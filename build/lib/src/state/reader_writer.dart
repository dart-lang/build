// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import 'asset_finder.dart';
import 'asset_path_provider.dart';
import 'filesystem.dart';
import 'filesystem_cache.dart';
import 'generated_asset_hider.dart';
import 'reader_state.dart';

/// An [AssetReader] and [AssetWriter].
abstract interface class AssetReaderWriter
    implements AssetReader, AssetWriter {}

/// An [AssetReaderWriter] that delegates to an [AssetReader] and an
/// [AssetWriter].
///
/// The main `package:build` readers and writers already implement
/// `AssetReaderWriter`, this is used to support nonstandard readers/writers for
/// testing.
class DelegatingAssetReaderWriter
    implements AssetReaderWriter, AssetReaderState {
  final AssetReader reader;
  final AssetWriter writer;

  DelegatingAssetReaderWriter({required this.reader, required this.writer});

  @override
  AssetFinder get assetFinder => reader.assetFinder;

  @override
  AssetPathProvider get assetPathProvider => reader.assetPathProvider;

  @override
  GeneratedAssetHider get generatedAssetHider => reader.generatedAssetHider;

  @override
  FilesystemCache get cache => reader.cache;

  @override
  AssetReaderWriter copyWith({
    FilesystemCache? cache,
    GeneratedAssetHider? generatedAssetHider,
  }) => DelegatingAssetReaderWriter(
    reader: reader.copyWith(
      cache: cache,
      generatedAssetHider: generatedAssetHider,
    ),
    writer: writer,
  );

  @override
  Filesystem get filesystem => reader.filesystem;

  @override
  Future<bool> canRead(AssetId id) => reader.canRead(id);

  @override
  Future<Digest> digest(AssetId id) => reader.digest(id);

  @override
  Stream<AssetId> findAssets(Glob glob) => reader.findAssets(glob);

  @override
  Future<List<int>> readAsBytes(AssetId id) => reader.readAsBytes(id);

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) =>
      reader.readAsString(id, encoding: encoding);

  @override
  Future<void> writeAsBytes(AssetId id, List<int> bytes) =>
      writer.writeAsBytes(id, bytes);

  @override
  Future<void> writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) => writer.writeAsString(id, contents);

  // TODO(davidmorgan): fix interfaces/dependencies to improve this.
  Future delete(AssetId id) => throw UnimplementedError();
}
