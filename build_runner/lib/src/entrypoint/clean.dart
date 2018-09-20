// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:logging/logging.dart';

import '../logging/std_io_logging.dart';

class CleanCommand extends Command<int> {
  @override
  String get name => 'clean';

  @override
  String get description =>
      'Cleans up output from previous builds. Does not clean up --output '
      'directories.';

  Logger get logger => Logger(name);

  @override
  Future<int> run() async {
    var logSubscription = Logger.root.onRecord.listen(stdIOLogListener());

    logger.warning('Deleting cache and generated source files.\n'
        'This shouldn\'t be necessary for most applications, unless you have '
        'made intentional edits to generated files (i.e. for testing). '
        'Consider filing a bug at '
        'https://github.com/dart-lang/build/issues/new if you are using this '
        'to work around an apparent (and reproducible) bug.');

    await logTimedAsync(logger, 'Cleaning up source outputs', () async {
      var assetGraphFile = File(assetGraphPath);
      if (!assetGraphFile.existsSync()) {
        logger.warning('No asset graph found. '
            'Skipping cleanup of generated files in source directories.');
        return;
      }
      AssetGraph assetGraph;
      try {
        assetGraph = AssetGraph.deserialize(await assetGraphFile.readAsBytes());
      } catch (_) {
        logger.warning('Failed to deserialize AssetGraph. '
            'Skipping cleanup of generated files in source directories.');
        return;
      }
      var packageGraph = PackageGraph.forThisPackage();
      var writer = FileBasedAssetWriter(packageGraph);
      for (var id in assetGraph.outputs) {
        if (id.package != packageGraph.root.name) continue;
        var node = assetGraph.get(id) as GeneratedAssetNode;
        if (node.wasOutput) {
          // Note that this does a file.exists check in the root package and
          // only tries to delete the file if it exists. This way we only
          // actually delete to_source outputs, without reading in the build
          // actions.
          await writer.delete(id);
        }
      }
    });

    await logTimedAsync(logger, 'Cleaning up cache directory', () async {
      var generatedDir = Directory(cacheDir);
      if (await generatedDir.exists()) {
        await generatedDir.delete(recursive: true);
      }
    });

    await logSubscription.cancel();

    return 0;
  }
}
