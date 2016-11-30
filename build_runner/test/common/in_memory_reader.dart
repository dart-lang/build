// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:mirrors';

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';

import 'in_memory_writer.dart';

class InMemoryAssetReader implements RunnerAssetReader {
  final Map<AssetId, DatedString> assets;

  InMemoryAssetReader(this.assets);

  @override
  Future<bool> hasInput(AssetId id) {
    return new Future.value(assets.containsKey(id));
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async {
    if (!await hasInput(id)) throw new AssetNotFoundException(id);
    return assets[id].value;
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

  final Map<Uri, LibraryMirror> _allLibraries = currentMirrorSystem().libraries;

  @override
  Future<DateTime> lastModified(AssetId id) async {
    if (!assets.containsKey(id)) {
      /// Support reading files imported by the test script as well. Also
      /// pretend like they are very old so that builds don't get invalidated.
      ///
      /// Overridden values in [assets] will take precedence.
      var uri = new Uri(
          scheme: 'package',
          path: '${id.package}/${id.path.replaceFirst("lib/", "")}');
      if (_allLibraries[uri] != null) {
        return new DateTime.fromMillisecondsSinceEpoch(0);
      }

      throw new AssetNotFoundException(id);
    }

    return assets[id].date;
  }
}
