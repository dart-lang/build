// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:logging/logging.dart';

import 'assets.dart';
import 'in_memory_reader.dart';
import 'in_memory_writer.dart';
import 'matchers.dart';

export 'package:build/src/util/constants.dart';

export 'assets.dart';
export 'copy_builder.dart';
export 'fake_watcher.dart';
export 'file_combiner_builder.dart';
export 'generic_builder_transformer.dart';
export 'in_memory_reader.dart';
export 'in_memory_writer.dart';
export 'matchers.dart';
export 'stub_reader.dart';
export 'stub_writer.dart';

Future wait(int milliseconds) =>
    new Future.delayed(new Duration(milliseconds: milliseconds));

void checkOutputs(Map<String, String> outputs, BuildResult result,
    [Map<AssetId, DatedString> actualAssets]) {
  if (outputs != null) {
    var remainingOutputIds =
        new List.from(result.outputs.map((asset) => asset.id));
    outputs.forEach((serializedId, contents) {
      var asset = makeAsset(serializedId, contents);
      remainingOutputIds.remove(asset.id);

      /// Check that the writer wrote the assets
      if (actualAssets != null) {
        expect(actualAssets, contains(asset.id));
        expect(actualAssets[asset.id].value, asset.stringContents);
      }

      /// Check that the assets exist in [result.outputs].
      var actual = result.outputs
          .firstWhere((output) => output.id == asset.id, orElse: () => null);
      expect(actual, isNotNull,
          reason: 'Expected to find ${asset.id} in ${result.outputs}.');
      expect(asset, equalsAsset(actual));
    });

    expect(remainingOutputIds, isEmpty,
        reason: 'Unexpected outputs found `$remainingOutputIds`.');
  }
}

Future<BuildResult> nextResult(results) {
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

testPhases(PhaseGroup phases, Map<String, String> inputs,
    {bool deleteFilesByDefault,
    Map<String, String> outputs,
    PackageGraph packageGraph,
    BuildStatus status: BuildStatus.Success,
    exceptionMatcher,
    InMemoryAssetWriter writer}) async {
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
      logLevel: Level.OFF);
  expect(result.status, status,
      reason: 'Exception:\n${result.exception}\n'
          'Stack Trace:\n${result.stackTrace}');
  if (exceptionMatcher != null) {
    expect(result.exception, exceptionMatcher);
  }

  checkOutputs(outputs, result, actualAssets);
}
