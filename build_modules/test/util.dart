// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

/// Forwards to [testBuilder], and adds all output assets to [assets].
Future<void> testBuilderAndCollectAssets(
  Builder builder,
  Map<String, Object> assets, {
  Set<String>? generateFor,
  Map<String, /*String|List<int>|Matcher<String|List<int>>*/ Object>? outputs,
  void Function(LogRecord log)? onLog,
  void Function(AssetId, Iterable<AssetId>)? reportUnusedAssetsForInput,
}) async {
  onLog ??= (log) => printOnFailure('${log.level}: ${log.message}');
  final result = await testBuilder(
    builder,
    assets,
    generateFor: generateFor,
    outputs: outputs,
    onLog: onLog,
    reportUnusedAssetsForInput: reportUnusedAssetsForInput,
  );
  for (var id in result.readerWriter.testing.assets) {
    final value = result.readerWriter.testing.readBytes(id);
    assets['${id.package}|${id.path}'] = value;
  }
}
