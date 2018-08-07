// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'assets/asset_reader.dart';
import 'assets/path_translation.dart';
import 'timing.dart';

/// Runs [builders] to generate files and fills in missing outputs with default
/// content.
///
/// When there are multiple builders, the outputs of each are assumed to be
/// primary inputs to the next builder sequentially.
///
/// The [timings] instance must already be started.
Future<Null> runBuilders(
    List<BuilderFactory> builders,
    String packagePath,
    Map<String, List<String>> buildExtensions,
    Map<String, String> defaultContent,
    List<String> srcPaths,
    Map<String, String> packageMap,
    CodegenTiming timings,
    AssetWriter writer,
    BazelAssetReader reader,
    Logger logger,
    Resolvers resolvers,
    BuilderOptions builderOptions,
    {bool isWorker = false,
    Set<String> validInputs}) async {
  assert(timings.isRunning);

  final srcAssets = findAssetIds(srcPaths, packagePath, packageMap)
      .where((id) => buildExtensions.keys.any(id.path.endsWith))
      .toList();

  var allWrittenAssets = Set<AssetId>();

  var inputSrcs = Set<AssetId>()..addAll(srcAssets);
  for (var builder in builders.map((f) => f(builderOptions))) {
    var writerSpy = AssetWriterSpy(writer);
    reader.startPhase(writerSpy);
    try {
      if (inputSrcs.isNotEmpty) {
        await timings.trackOperation(
            'Generating files: $builder',
            () => runBuilder(builder, inputSrcs, reader, writerSpy, resolvers,
                logger: logger));
      }
    } catch (e, s) {
      logger.severe(
          'Caught error during code generation step '
          '$builder on $packagePath',
          e,
          s);
    }

    // Set outputs as inputs into the next builder
    inputSrcs.addAll(writerSpy.assetsWritten);
    validInputs?.addAll(writerSpy.assetsWritten
        .map((id) => p.join(packageMap[id.package], id.path)));

    // Track and clear written assets.
    allWrittenAssets.addAll(writerSpy.assetsWritten);
  }

  timings.trackOperation('Resetting Resolvers', resolvers.reset);

  await timings.trackOperation('Checking outputs and writing defaults',
      () async {
    var writes = <Future>[];
    // Check all expected outputs were written or create w/provided default.
    for (var assetId in srcAssets) {
      for (var inputExtension in buildExtensions.keys) {
        for (var extension in buildExtensions[inputExtension]) {
          if (!assetId.path.endsWith(inputExtension)) continue;

          var expectedAssetId = AssetId(
              assetId.package,
              assetId.path.substring(
                      0, assetId.path.length - inputExtension.length) +
                  extension);
          if (allWrittenAssets.contains(expectedAssetId)) continue;

          if (defaultContent.containsKey(extension)) {
            writes.add(writer.writeAsString(
                expectedAssetId, defaultContent[extension]));
          } else {
            logger.warning('Missing expected output $expectedAssetId');
          }
        }
      }
    }
    await Future.wait(writes);
  });

  timings
    ..stop()
    ..writeLogSummary(logger);

  logger.info('Read ${reader.fileReadCount} files from disk');
}
