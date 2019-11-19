// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'in_memory_writer.dart';

/// A [MultiPackageAssetReader] which supports reads from previous outputs.
class WrittenAssetReader extends MultiPackageAssetReader {
  final RecordingAssetWriter source;

  /// An optional [AssetWriterSpy] to limit what's readable through this reader.
  ///
  /// Only assets reported as written trough this [AssetWriterSpy] can be read
  /// from this reader. When null, all assets from [source] are available.
  final AssetWriterSpy filterSpy;

  WrittenAssetReader(this.source, [this.filterSpy]);

  @override
  Future<bool> canRead(AssetId id) {
    var canRead = source.assets.containsKey(id);
    if (filterSpy != null) {
      canRead = canRead && filterSpy.assetsWritten.contains(id);
    }

    return Future.value(canRead);
  }

  @override
  Stream<AssetId> findAssets(Glob glob, {String package}) async* {
    var available = source.assets.keys.toSet();
    if (filterSpy != null) {
      available = available.intersection(filterSpy.assetsWritten.toSet());
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
    return Future.value(source.assets[id]);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding}) async {
    encoding ??= utf8;
    return encoding.decode(await readAsBytes(id));
  }
}
