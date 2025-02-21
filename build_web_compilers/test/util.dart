// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

/// Forwards to [testBuilder], and adds all output assets to [assets].
Future<void> testBuilderAndCollectAssets(
  Builder builder,
  Map<String, Object> assets,
) async {
  final result = await testBuilder(
    builder,
    assets,
    onLog: (log) => printOnFailure('${log.level}: ${log.message}'),
  );
  for (var id in result.readerWriter.testing.assets) {
    final value = result.readerWriter.testing.readBytes(id);
    assets['${id.package}|${id.path}'] = value;
  }
}
