// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:build/build.dart';
import 'package:build_barback/build_barback.dart';
import 'package:logging/logging.dart';

import 'assets.dart';
import 'in_memory_reader.dart';
import 'in_memory_writer.dart';

AssetId _passThrough(AssetId id) => id;

/// Validates that [actualAssets] matches the expected [outputs].
///
/// The keys in [outputs] should be serialized AssetIds in the form
/// `'package|path'`. The values should match the expected content for the
/// written asset and may be a String (for `writeAsString`), a `List<int>` (for
/// `writeAsBytes`) or a [Matcher] for a String or bytes.
///
/// [actualAssets] are the IDs that were recorded as written during the build.
///
/// Assets are checked against those that were written to [writer]. If other
/// assets were written through the writer, but not as part of the build
/// process, they will be ignored. Only the IDs in [actualAssets] are checked.
///
/// If assets are written to a location that does not match their logical
/// association to a package pass `[mapAssetIds]` to translate from the logical
/// location to the actual written location.
void checkOutputs(
    Map<String, /*List<int>|String|Matcher<String|List<int>>*/ dynamic> outputs,
    Iterable<AssetId> actualAssets,
    RecordingAssetWriter writer,
    {AssetId mapAssetIds(AssetId id): _passThrough}) {
  var modifiableActualAssets = new Set.from(actualAssets);
  if (outputs != null) {
    outputs.forEach((serializedId, contentsMatcher) {
      assert(contentsMatcher is String ||
          contentsMatcher is List<int> ||
          contentsMatcher is Matcher);

      var assetId = makeAssetId(serializedId);

      // Check that the asset was produced.
      expect(modifiableActualAssets, contains(assetId),
          reason: 'Builder failed to write asset $assetId');
      modifiableActualAssets.remove(assetId);
      var actual = writer.assets[mapAssetIds(assetId)];
      Object expected;
      if (contentsMatcher is String) {
        expected = UTF8.decode(actual);
      } else if (contentsMatcher is List<int>) {
        expected = actual;
      } else if (contentsMatcher is Matcher) {
        expected = actual;
      } else {
        throw new ArgumentError('Expected values for `outputs` to be of type '
            '`String`, `List<int>`, or `Matcher`, but got `$contentsMatcher`.');
      }
      expect(expected, contentsMatcher,
          reason: 'Unexpected content for $assetId in result.outputs.');
    });
    // Check that no extra assets were produced.
    expect(modifiableActualAssets, isEmpty,
        reason:
            'Unexpected outputs found `$actualAssets`. Only expected $outputs');
  }
}

/// Runs [builder] in a test environment.
///
/// The test environment supplies in-memory build [sourceAssets] to the builders
/// under test. [outputs] may be optionally provided to verify that the builders
/// produce the expected output. If outputs is omitted the only validation this
/// method provides is that the build did not `throw`.
///
/// [generateFor] or the [isInput] call back can specify which assets should be
/// given as inputs to the builder. These can be omitted if every asset in
/// [sourceAssets] should be considered an input. [isInput] precedent over
/// [generateFor] if both are provided.
///
/// The keys in [sourceAssets] and [outputs] are paths to file assets and the
/// values are file contents. The paths must use the following format:
///
///     PACKAGE_NAME|PATH_WITHIN_PACKAGE
///
/// Where `PACKAGE_NAME` is the name of the package, and `PATH_WITHIN_PACKAGE`
/// is the path to a file relative to the package. `PATH_WITHIN_PACKAGE` must
/// include `lib`, `web`, `bin` or `test`. Example: "myapp|lib/utils.dart".
///
/// Callers may optionally provide a [writer] to stub different behavior or do
/// more complex validation than what is possible with [outputs].
///
/// Callers may optionally provide an [onLog] callback to do validaiton on the
/// logging output of the builder.
Future testBuilder(
    Builder builder, Map<String, /*String|List<int>*/ dynamic> sourceAssets,
    {Set<String> generateFor,
    bool isInput(String assetId),
    String rootPackage,
    RecordingAssetWriter writer,
    Map<String, /*String|List<int>|Matcher<String|List<int>>*/ dynamic> outputs,
    void onLog(LogRecord log)}) async {
  writer ??= new InMemoryAssetWriter();
  final reader = new InMemoryAssetReader(rootPackage: rootPackage);

  var inputIds = <AssetId>[];
  sourceAssets.forEach((serializedId, contents) {
    var id = makeAssetId(serializedId);
    if (contents is String) {
      reader.cacheStringAsset(id, contents);
    } else if (contents is List<int>) {
      reader.cacheBytesAsset(id, contents);
    }
    inputIds.add(id);
  });

  isInput ??= generateFor?.contains ?? (_) => true;
  inputIds = inputIds.where((id) => isInput('$id')).toList();

  var writerSpy = new AssetWriterSpy(writer);
  var logger = new Logger('testBuilder');
  var logSubscription = logger.onRecord.listen(onLog);
  await runBuilder(
      builder, inputIds, reader, writerSpy, const BarbackResolvers(),
      logger: logger);
  await logSubscription.cancel();
  var actualOutputs = writerSpy.assetsWritten;
  checkOutputs(outputs, actualOutputs, writer);
}
