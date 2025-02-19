// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

import 'assets.dart';
import 'in_memory_reader_writer.dart';
import 'written_asset_reader.dart';

AssetId _passThrough(AssetId id) => id;

/// Validates that [actualAssets] matches the expected [outputs].
///
/// The keys in [outputs] should be serialized [AssetId]s in the form
/// `'package|path'`. The values should match the expected content for the
/// written asset and may be a `String` which will match against the utf8
/// decoded bytes, a `List<int>` matching the raw bytes, or a [Matcher] for a
/// `List<int>` of  bytes. For writing a [Matcher] against the `String`
/// contents, you can wrap your [Matcher] in a call to `decodedMatches`.
///
/// [actualAssets] are the IDs that were recorded as written during the build.
///
/// Assets are checked against those that were written to [writer]. If other
/// assets were written through the writer, but not as part of the build
/// process, they will be ignored. Only the IDs in [actualAssets] are checked.
///
/// If assets are written to a location that does not match their logical
/// association to a package pass [mapAssetIds] to translate from the logical
/// location to the actual written location.
void checkOutputs(
    Map<String, /*List<int>|String|Matcher<List<int>>*/ Object>? outputs,
    Iterable<AssetId> actualAssets,
    InMemoryAssetReaderWriter writer,
    {AssetId Function(AssetId id) mapAssetIds = _passThrough}) {
  var modifiableActualAssets = Set.of(actualAssets);
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
      var actual = writer.assets[mapAssetIds(assetId)]!;
      Object expected;
      if (contentsMatcher is String) {
        expected = utf8.decode(actual);
      } else if (contentsMatcher is List<int>) {
        expected = actual;
      } else if (contentsMatcher is Matcher) {
        expected = actual;
      } else {
        throw ArgumentError('Expected values for `outputs` to be of type '
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
/// under test.
///
/// [outputs] may be optionally provided to verify that the builders
/// produce the expected output, see [checkOutputs] for a full description of
/// the [outputs] map and how to use it. If [outputs] is omitted the only
/// validation this method provides is that the build did not `throw`.
///
/// Either [generateFor] or the [isInput] callback can specify which assets
/// should be given as inputs to the builder. These can be omitted if every
/// asset in [sourceAssets] should be considered an input. [generateFor] is
/// ignored if both [isInput] and [generateFor] are provided.
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
/// Callers may optionally provide an [onLog] callback to do validaiton on the
/// logging output of the builder.
///
/// An optional [packageConfig] may be supplied to set the language versions of
/// certain packages. It will only be used for this purpose and not for reading
/// of files or converting uris.
///
/// Enabling of language experiments is supported through the
/// `withEnabledExperiments` method from package:build.
///
/// Returns a [TestBuilderResult] with the [InMemoryAssetReaderWriter] used for
/// the build, which can be used for further checks.
Future<TestBuilderResult> testBuilder(
    Builder builder, Map<String, /*String|List<int>*/ Object> sourceAssets,
    {Set<String>? generateFor,
    bool Function(String assetId)? isInput,
    String? rootPackage,
    Map<String, /*String|List<int>|Matcher<List<int>>*/ Object>? outputs,
    void Function(LogRecord log)? onLog,
    void Function(AssetId, Iterable<AssetId>)? reportUnusedAssetsForInput,
    PackageConfig? packageConfig}) async {
  onLog ??= (log) => printOnFailure('$log');

  var inputIds = {
    for (var descriptor in sourceAssets.keys) makeAssetId(descriptor)
  };
  var allPackages = {for (var id in inputIds) id.package};
  if (allPackages.length == 1) rootPackage ??= allPackages.first;

  inputIds.addAll([
    for (var package in allPackages) AssetId(package, r'lib/$lib$'),
    if (rootPackage != null) ...[
      AssetId(rootPackage, r'$package$'),
      AssetId(rootPackage, r'test/$test$'),
      AssetId(rootPackage, r'web/$web$'),
    ]
  ]);

  final readerWriter = InMemoryAssetReaderWriter(rootPackage: rootPackage);

  sourceAssets.forEach((serializedId, contents) {
    var id = makeAssetId(serializedId);
    if (contents is String) {
      readerWriter.filesystem.writeAsStringSync(id, contents);
    } else if (contents is List<int>) {
      readerWriter.filesystem.writeAsBytesSync(id, contents);
    }
  });

  final inputFilter = isInput ?? generateFor?.contains ?? (_) => true;
  inputIds.retainWhere((id) => inputFilter('$id'));

  var writerSpy = AssetWriterSpy(readerWriter);
  var logger = Logger('testBuilder');
  var logSubscription = logger.onRecord.listen(onLog);
  var resolvers = packageConfig == null && enabledExperiments.isEmpty
      ? AnalyzerResolvers.sharedInstance
      : AnalyzerResolvers.custom(packageConfig: packageConfig);

  final startingFiles = readerWriter.assets.keys.toList();
  for (var input in inputIds) {
    // Create a reader that can read initial files plus anything written by the
    // builder during the step; outputs by other builders during the step are
    // not readable.
    final spyForStep = AssetWriterSpy(writerSpy);
    final readerForStep = WrittenAssetReader(readerWriter, spyForStep)
      ..allowReadingAll(startingFiles);

    await runBuilder(builder, {input}, readerForStep, spyForStep, resolvers,
        logger: logger, reportUnusedAssetsForInput: reportUnusedAssetsForInput);
  }

  await logSubscription.cancel();
  var actualOutputs = writerSpy.assetsWritten;
  checkOutputs(outputs, actualOutputs, readerWriter);
  return TestBuilderResult(readerWriter: readerWriter);
}

class TestBuilderResult {
  final InMemoryAssetReaderWriter readerWriter;

  TestBuilderResult({required this.readerWriter});
}
