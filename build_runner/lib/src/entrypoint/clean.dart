// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset_graph/graph.dart';

import 'base_command.dart';

class CleanCommand extends Command<int> {
  @override
  final argParser = ArgParser(usageLineLength: lineLength);

  @override
  String get name => 'clean';

  @override
  String get description =>
      'Cleans up output from previous builds. Does not clean up --output '
      'directories.';

  @override
  Future<int> run() async {
    await cleanFor(assetGraphPath);
    return 0;
  }
}

Future<void> cleanFor(String assetGraphPath) async {
  buildLog.warning(
    'Deleting cache and generated source files.\n'
    'This shouldn\'t be necessary for most applications, unless you have '
    'made intentional edits to generated files (i.e. for testing). '
    'Consider filing a bug at '
    'https://github.com/dart-lang/build/issues/new if you are using this '
    'to work around an apparent (and reproducible) bug.',
  );

  var assetGraphFile = File(assetGraphPath);
  if (!assetGraphFile.existsSync()) {
    buildLog.warning(
      'No asset graph found. '
      'Skipping cleanup of generated files in source directories.',
    );
    return;
  }
  AssetGraph assetGraph;
  try {
    assetGraph = AssetGraph.deserialize(await assetGraphFile.readAsBytes());
  } catch (_) {
    buildLog.warning(
      'Failed to deserialize AssetGraph. '
      'Skipping cleanup of generated files in source directories.',
    );
    return;
  }
  var packageGraph = await PackageGraph.forThisPackage();
  await _cleanUpSourceOutputs(assetGraph, packageGraph);
  await _cleanUpGeneratedDirectory();
}

Future<void> _cleanUpSourceOutputs(
  AssetGraph assetGraph,
  PackageGraph packageGraph,
) async {
  var writer = ReaderWriter(packageGraph);
  for (var id in assetGraph.outputs) {
    if (id.package != packageGraph.root.name) continue;
    var node = assetGraph.get(id)!;
    if (node.wasOutput) {
      // Note that this does a file.exists check in the root package and
      // only tries to delete the file if it exists. This way we only
      // actually delete to_source outputs, without reading in the build
      // actions.
      await writer.delete(id);
    }
  }
}

Future<void> _cleanUpGeneratedDirectory() async {
  var generatedDir = Directory(cacheDir);
  if (await generatedDir.exists()) {
    await generatedDir.delete(recursive: true);
  }
}
