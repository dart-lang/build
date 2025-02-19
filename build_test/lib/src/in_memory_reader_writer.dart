// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

/// An [AssetReader] that records which assets have been read to [assetsRead].
abstract class RecordingAssetReader implements AssetReader {
  Set<AssetId> get assetsRead;
}

/// An implementation of [AssetReader] and [AssetWriter] with primed in-memory
/// assets.
///
/// TODO(davidmorgan): merge into `FileBasedReader` and `FileBasedWriter`.
class InMemoryAssetReaderWriter
    implements AssetReader, AssetReaderState, AssetWriter {
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

  Map<AssetId, List<int>> get assets => _filesystem.assets;

  @override
  Future<bool> canRead(AssetId id) async {
    inputTracker.assetsRead.add(id);
    return filesystem.exists(id);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    if (!await canRead(id)) throw AssetNotFoundException(id);
    inputTracker.assetsRead.add(id);
    return filesystem.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    if (!await canRead(id)) throw AssetNotFoundException(id);
    inputTracker.assetsRead.add(id);
    return filesystem.readAsString(id, encoding: encoding);
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
  Future writeAsBytes(AssetId id, List<int> bytes) async =>
      filesystem.writeAsBytes(id, bytes);

  @override
  Future writeAsString(AssetId id, String contents,
          {Encoding encoding = utf8}) async =>
      filesystem.writeAsString(id, contents, encoding: encoding);

  @override
  Future<Digest> digest(AssetId id) async {
    var digestSink = AccumulatorSink<Digest>();
    md5.startChunkedConversion(digestSink)
      ..add(await readAsBytes(id))
      ..add(id.toString().codeUnits)
      ..close();
    return digestSink.events.first;
  }
}
