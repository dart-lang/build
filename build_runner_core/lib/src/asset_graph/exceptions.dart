// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

class DuplicateAssetNodeException implements Exception {
  final String rootPackage;
  final AssetId assetId;
  final String builder1;
  final String builder2;

  DuplicateAssetNodeException(
    this.rootPackage,
    this.assetId,
    this.builder1,
    this.builder2,
  );
  @override
  String toString() {
    final id = assetId.package == rootPackage ? assetId.path : assetId.uri;
    return 'Builders $builder1 and $builder2 outputs collide: $id';
  }
}

class AssetGraphCorruptedException implements Exception {}
