// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:glob/glob.dart';

import '../asset/id.dart';

abstract interface class AssetFinder {
  /// Returns all readable assets matching [glob] under [package].
  ///
  /// `Reader.findAssets` exposes this funcionality without allowing controlling
  /// [package].
  Stream<AssetId> find(Glob glob, {String? package});
}

class FunctionAssetFinder implements AssetFinder {
  final Stream<AssetId> Function(Glob, String?) function;

  FunctionAssetFinder(this.function);

  @override
  Stream<AssetId> find(Glob glob, {String? package}) => function(glob, package);
}
