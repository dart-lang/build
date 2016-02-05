// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

class InMemoryAssetReader implements AssetReader {
  final Map<AssetId, String> assets;

  InMemoryAssetReader(this.assets);

  @override
  Future<bool> hasInput(AssetId id) {
    return new Future.value(assets.containsKey(id));
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async {
    if (!await hasInput(id)) throw new AssetNotFoundException(id);
    return assets[id];
  }

  @override
  Stream<AssetId> listAssetIds(Iterable<InputSet> inputSets) async* {
    for (var id in assets.keys) {
      var matches = inputSets.any((inputSet) {
        if (inputSet.package != id.package) return false;
        return inputSet.globs.any((glob) => glob.matches(id.path));
      });
      if (matches) yield id;
    }
  }
}
