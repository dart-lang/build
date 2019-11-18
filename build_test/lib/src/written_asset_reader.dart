// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'in_memory_writer.dart';

/// A [MultiPackageAssetReader] reading outputs written into a
/// [RecordingAssetWriter].
class WrittenAssetReader extends MultiPackageAssetReader {
  final RecordingAssetWriter source;

  WrittenAssetReader(this.source);

  @override
  Future<bool> canRead(AssetId id) {
    return Future.value(source.assets.containsKey(id));
  }

  @override
  Stream<AssetId> findAssets(Glob glob, {String package}) async* {
    for (var asset in source.assets.keys) {
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
