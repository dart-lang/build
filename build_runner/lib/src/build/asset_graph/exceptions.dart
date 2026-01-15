// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

class DuplicateAssetNodeException implements Exception {
  final AssetId assetId;
  final String builder1;
  final String builder2;

  DuplicateAssetNodeException(this.assetId, this.builder1, this.builder2);
  @override
  String toString() =>
      'Builders $builder1 and $builder2 outputs collide: ${assetId.uri}';
}
