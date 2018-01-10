// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'package:build_runner/src/asset/build_cache.dart';
import 'package:build_runner/src/asset/file_based.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/generate/create_merged_dir.dart';
import 'package:build_runner/src/package_graph/package_graph.dart';
import 'package:build_runner/src/util/constants.dart';
import 'package:build_runner/src/logging/logging.dart';
import 'package:build_runner/src/logging/std_io_logging.dart';
import 'package:logging/logging.dart';

AssetGraph assetGraph;
PackageGraph packageGraph;
final logger = new Logger('CreateMergedDir');

Future main(List<String> args) async {
  Logger.root.onRecord.listen(stdIOLogListener);
  logger.warning('This tool is deprecated, please use the --output=dir option '
      'from the normal build/serve/watch commands.');

  var parsedArgs = argParser.parse(args);

  var scriptPath = parsedArgs['script'] as String;
  if (scriptPath == null) {
    logger.severe('Missing required arg --script');
    exit(1);
  }

  var scriptFile = new File(scriptPath);
  if (!scriptFile.existsSync()) {
    logger
        .severe('Expected a build script at $scriptPath but didn\'t find one.');
    exit(1);
  }

  var assetGraphFile = new File(assetGraphPathFor(p.absolute(scriptPath)));
  if (!assetGraphFile.existsSync()) {
    logger.severe(
        'Unable to find AssetGraph for $scriptPath at ${assetGraphFile.path}');
    exit(1);
  }

  await logTimedAsync(logger, 'Loading asset graph at ${assetGraphFile.path}',
      () async {
    assetGraph = new AssetGraph.deserialize(
        JSON.decode(await assetGraphFile.readAsString()) as Map);
  });

  packageGraph = new PackageGraph.forThisPackage();
  var reader = new BuildCacheReader(new FileBasedAssetReader(packageGraph),
      assetGraph, packageGraph.root.name);

  await createMergedOutputDir(
      parsedArgs['output-dir'] as String, assetGraph, packageGraph, reader);
}

final argParser = new ArgParser()
  ..addFlag('help', negatable: false)
  ..addOption('script', help: 'The build script to load the asset graph for.')
  ..addOption('output-dir',
      abbr: 'o', help: 'The output directory.', defaultsTo: 'build');
