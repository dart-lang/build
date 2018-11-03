// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';

/// Forwards to [testBuilder], and adds all output assets to [assets].
Future<Null> testBuilderAndCollectAssets(
    Builder builder, Map<String, dynamic> assets) async {
  var writer = InMemoryAssetWriter();
  await testBuilder(builder, assets, writer: writer);
  writer.assets.forEach((id, value) {
    assets['${id.package}|${id.path}'] = value;
  });
}
