// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:glob/glob.dart';

import 'id.dart';

/// Abstract interface for reading assets.
abstract class AssetReader {
  Future<List<int>> readAsBytes(AssetId id);

  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8});

  /// Whether an asset at [id] is readable.
  Future<bool> hasInput(AssetId id);

  /// Finds all of the assets which match [glob] and are readable under the root
  /// package.
  Iterable<AssetId> findAssets(Glob glob);
}
