// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';

import 'assets.dart';
import 'in_memory_reader.dart';
import 'in_memory_writer.dart';

Future wait(int milliseconds) =>
    new Future.delayed(new Duration(milliseconds: milliseconds));

void checkOutputs(
    Map<String, /*String|Matcher*/ dynamic> outputs, BuildResult result,
    [Map<AssetId, DatedString> actualAssets]) {
  if (outputs != null) {
    var remainingOutputIds =
        new List.from(result.outputs.map((asset) => asset.id));
    outputs.forEach((serializedId, contentsMatcher) {
      assert(contentsMatcher is String || contentsMatcher is Matcher);

      var assetId = makeAssetId(serializedId);
      remainingOutputIds.remove(assetId);

      /// Check that the writer wrote the assets
      if (actualAssets != null) {
        expect(actualAssets, contains(assetId));
        expect(actualAssets[assetId].value, contentsMatcher,
            reason: 'Unexpected content for $assetId.');
      }

      /// Check that the assets exist in [result.outputs].
      var actual = result.outputs
          .firstWhere((output) => output.id == assetId, orElse: () => null);
      expect(actual, isNotNull,
          reason: 'Expected to find $assetId in ${result.outputs}.');
      expect(actual.id, assetId);
      expect(actual.stringContents, contentsMatcher,
          reason: 'Unexpected content for $assetId in result.outputs.');
    });

    expect(remainingOutputIds, isEmpty,
        reason: 'Unexpected outputs found `$remainingOutputIds`.');
  }
}

Future<BuildResult> nextResult(List results) {
  var done = new Completer<BuildResult>();
  var startingLength = results.length;
  () async {
    while (results.length == startingLength) {
      await wait(10);
    }
    expect(results.length, startingLength + 1,
        reason: 'Got two build results but only expected one');
    done.complete(results.last);
  }();
  return done.future;
}

/// Runs build [phases] in a test environment.
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
/// [packageGraph] supplies the root package into which the outputs are to be
/// written.
///
/// [status] optionally indicates the desired outcome. [exceptionMatcher]
/// optionally allows you to expect a specific exception.
///
/// [writer] can optionally be provided to capture assets written by the
/// builders (e.g. when [outputs] is not sufficient).
///
/// [logLevel] sets the builder log level and [onLog] can optionally capture
/// build log messages.
///
/// Example:
///
///     main() {
///       test('LineCounterBuilder', () {
///         var p = new Phase()
///           ..addAction(new LineCounterBuilder(),
///             new InputSet('a', ['lib/utils.dart']));
///         var g = new PhaseGroup()..addPhase(p);
///         await testPhases(g, {
///           'a|lib/utils.dart': '',
///         }, outputs: {
///           'a|lib/utils_linecount.txt': '50',
///         });
///       });
///     }
///
Future testPhases(PhaseGroup phases, Map<String, String> inputs,
    {bool deleteFilesByDefault,
    Map<String, String> outputs,
    PackageGraph packageGraph,
    BuildStatus status: BuildStatus.success,
    Matcher exceptionMatcher,
    InMemoryAssetWriter writer,
    Level logLevel: Level.OFF,
    onLog(LogRecord record)}) async {
  writer ??= new InMemoryAssetWriter();
  final actualAssets = writer.assets;
  final reader = new InMemoryAssetReader(actualAssets);

  inputs.forEach((serializedId, contents) {
    writer.writeAsString(makeAsset(serializedId, contents));
  });

  if (packageGraph == null) {
    var rootPackage = new PackageNode('a', null, null, null);
    packageGraph = new PackageGraph.fromRoot(rootPackage);
  }

  var result = await build(phases,
      deleteFilesByDefault: deleteFilesByDefault,
      reader: reader,
      writer: writer,
      packageGraph: packageGraph,
      logLevel: logLevel,
      onLog: onLog);
  expect(result.status, status,
      reason: 'Exception:\n${result.exception}\n'
          'Stack Trace:\n${result.stackTrace}');
  if (exceptionMatcher != null) {
    expect(result.exception, exceptionMatcher);
  }

  checkOutputs(outputs, result, actualAssets);
}
