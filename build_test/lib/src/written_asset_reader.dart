// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:glob/glob.dart';

import 'in_memory_reader_writer.dart';

/// An [AssetReader] which supports reads from previous outputs.
class WrittenAssetReader extends AssetReader implements AssetReaderState {
  final InMemoryAssetReaderWriter source;

  /// An optional [AssetWriterSpy] to limit what's readable through this reader.
  ///
  /// Only assets reported as written through this [AssetWriterSpy] can be read
  /// from this reader. When null, all assets from [source] are available.
  final AssetWriterSpy? filterSpy;

  /// Assets allowed to be read because of a call to [allowReadingAll].
  final Set<AssetId> _additionallyAllowed = {};

  WrittenAssetReader(this.source, [this.filterSpy]);

  @override
  Filesystem get filesystem => source.filesystem;

  @override
  late final AssetFinder assetFinder = FunctionAssetFinder(_findAssets);

  @override
  AssetPathProvider? get assetPathProvider => null;

  @override
  InputTracker? get inputTracker => null;

  /// Marks [assets] as allowed to be read.
  ///
  /// They are then readable regardless of whether they were written through
  /// [filterSpy].
  void allowReadingAll(Iterable<AssetId> assets) {
    _additionallyAllowed.addAll(assets);
  }

  @override
  Future<bool> canRead(AssetId id) {
    var canRead = source.assets.containsKey(id);
    if (filterSpy != null) {
      canRead =
          canRead &&
          (_additionallyAllowed.contains(id) ||
              filterSpy!.assetsWritten.contains(id));
    }

    return Future.value(canRead);
  }

  // This is only for generators, so only `BuildStep` needs to implement it.
  @override
  Stream<AssetId> findAssets(Glob glob) => throw UnimplementedError();

  Stream<AssetId> _findAssets(Glob glob, String? package) async* {
    var available = source.assets.keys.toSet();
    if (filterSpy != null) {
      available = available.intersection(
        filterSpy!.assetsWritten.toSet().union(_additionallyAllowed),
      );
    }

    for (var asset in available) {
      if (!glob.matches(asset.path)) continue;
      if (package != null && asset.package != package) continue;

      yield asset;
    }
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) {
    if (!source.assets.containsKey(id)) {
      throw AssetNotFoundException(id);
    }
    return Future.value(source.assets[id]!);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    return encoding.decode(await readAsBytes(id));
  }
}
