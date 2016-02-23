// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jakemac): Use the build_test package once that is available.

import 'dart:async';

import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:logging/logging.dart';

import 'in_memory_reader.dart';
import 'in_memory_writer.dart';

Future testPhases(PhaseGroup phases, String rootPackage,
    Map<String, String> inputs, Map<String, dynamic> outputs) async {
  var writer = new InMemoryAssetWriter();
  var reader = new InMemoryAssetReader(writer.assets);

  inputs.forEach((serializedId, contents) {
    writer.writeAsString(new Asset(new AssetId.parse(serializedId), contents));
  });

  var rootPackageNode = new PackageNode(rootPackage, null, null, null);
  var packageGraph = new PackageGraph.fromRoot(rootPackageNode);

  var result = await build(phases,
      reader: reader,
      writer: writer,
      packageGraph: packageGraph,
      logLevel: Level.OFF);

  expect(result.status, BuildStatus.Success,
      reason: 'Exception:\n${result.exception}\n'
          'Stack Trace:\n${result.stackTrace}');

  if (outputs != null) checkOutputs(outputs, result);
}

void checkOutputs(Map<String, dynamic> outputs, BuildResult result) {
  var remainingOutputIds =
      new List.from(result.outputs.map((asset) => asset.id));
  outputs.forEach((serializedId, contentsMatcher) {
    var id = new AssetId.parse(serializedId);
    remainingOutputIds.remove(id);

    /// Check that the assets exist in [result.outputs].
    var actual = result.outputs
        .firstWhere((output) => output.id == id, orElse: () => null);
    expect(actual, isNotNull,
        reason: 'Expected to find ${id} in ${result.outputs}.');
    expect(actual.stringContents, contentsMatcher);
  });

  expect(remainingOutputIds, isEmpty,
      reason: 'Unexpected outputs found `$remainingOutputIds`.');
}
