import 'dart:async';

import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:build/build.dart';

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
      reason: 'Unexpected outputs found `$actualAssets`. Only expected $outputs');
}

/// Runs [builder] in a test environment.
///
/// The test environment supplies in-memory build [inputs] to the builders under
/// test. [outputs] may be optionally provided to verify that the builders
/// produce the expected output.
///
/// The keys in [inputs] and [outputs] are paths to file assets and the values
/// are file contents. The paths must use the following format:
///
///     PACKAGE_NAME:PATH_WITHIN_PACKAGE
///
/// Where `PACKAGE_NAME` is the name of the package, and `PATH_WITHIN_PACKAGE`
/// is the path to a file relative to the package. `PATH_WITHIN_PACKAGE` must
/// include `lib`, `web`, `bin` or `test`. Example: "myapp|lib/utils.dart".
///
///
/// [status] optionally indicates the desired outcome. [exceptionMatcher]
/// optionally allows you to expect a specific exception.
///
/// [writer] can optionally be provided to capture assets written by the
/// builders (e.g. when [outputs] is not sufficient).
///
/// [logLevel] sets the builder log level and [onLog] can optionally capture
/// build log messages.
Future testBuilder(Builder builder, Map<String, String> inputs,
    {bool deleteFilesByDefault,
    Map<String, String> outputs,
    InMemoryAssetWriter writer,
    Level logLevel: Level.OFF,
    onLog(LogRecord record)}) async {
  writer ??= new InMemoryAssetWriter();
  final reader = new InMemoryAssetReader(writer.assets);

  var inputIds = <AssetId>[];
  inputs.forEach((serializedId, contents) {
    var asset = makeAsset(serializedId, contents);
    writer.writeAsString(asset);
    inputIds.add(asset.id);
  });
  // TODO(nbosch) resolvers?
  await runBuilder(builder, inputIds, reader, writer, null);
  var actualOutputs = <AssetId,DatedString>{}..addAll(writer.assets);
  for(var assetId in inputIds) {
    actualOutputs.remove(assetId);
  }
  _checkOutputs(outputs, actualOutputs);
}
