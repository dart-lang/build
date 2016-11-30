// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:test/test.dart';
import 'package:build/build.dart';
import 'package:build_barback/build_barback.dart';

import 'in_memory_writer.dart';
import 'in_memory_reader.dart';
import 'assets.dart';

void _checkOutputs(Map<String, /*String|Matcher*/ dynamic> outputs,
    [Map<AssetId, DatedString> actualAssets]) {
  if (outputs != null) {
    outputs.forEach((serializedId, contentsMatcher) {
      assert(contentsMatcher is String || contentsMatcher is Matcher);

      var assetId = makeAssetId(serializedId);

      /// Check that the writer wrote the assets
      if (actualAssets != null) {
        expect(actualAssets, contains(assetId));
        expect(actualAssets[assetId].value, contentsMatcher,
            reason: 'Unexpected content for $assetId.');
      }

      /// Check that the assets exist in [result.outputs].
      var actual = actualAssets.remove(assetId);
      expect(actual, isNotNull,
          reason: 'Expected to find $assetId in ${actualAssets}.');
      expect(actual.value, contentsMatcher,
          reason: 'Unexpected content for $assetId in result.outputs.');
    });
  }
  expect(actualAssets, isEmpty,
      reason:
          'Unexpected outputs found `$actualAssets`. Only expected $outputs');
}

/// Runs [builder] in a test environment.
///
/// The test environment supplies in-memory build [sourceAssets] to the builders
/// under test. [outputs] may be optionally provided to verify that the builders
/// produce the expected output.
///
/// [generateFor] specifies which assets should be given as inputs to the
/// builder, this can be omitted if every asset in [sourceAssets] should be
/// considered an input.
///
/// The keys in [sourceAssets] and [outputs] are paths to file assets and the
/// values are file contents. The paths must use the following format:
///
///     PACKAGE_NAME|PATH_WITHIN_PACKAGE
///
/// Where `PACKAGE_NAME` is the name of the package, and `PATH_WITHIN_PACKAGE`
/// is the path to a file relative to the package. `PATH_WITHIN_PACKAGE` must
/// include `lib`, `web`, `bin` or `test`. Example: "myapp|lib/utils.dart".
Future testBuilder(Builder builder, Map<String, String> sourceAssets,
    {Set<String> generateFor,
    Map<String, /*String|Matcher*/ dynamic> outputs}) async {
  var writer = new InMemoryAssetWriter();
  final reader = new InMemoryAssetReader(writer.assets);

  var inputIds = <AssetId>[];
  var sourceAssetIds = new Set<AssetId>();
  sourceAssets.forEach((serializedId, contents) {
    var asset = makeAsset(serializedId, contents);
    writer.writeAsString(asset);
    sourceAssetIds.add(asset.id);
    if (generateFor == null || generateFor.contains(serializedId)) {
      inputIds.add(asset.id);
    }
  });
  await runBuilder(builder, inputIds, reader, writer, const BarbackResolvers());
  var actualOutputs = <AssetId, DatedString>{}..addAll(writer.assets);
  for (var assetId in sourceAssetIds) {
    actualOutputs.remove(assetId);
  }
  _checkOutputs(outputs, actualOutputs);
}
