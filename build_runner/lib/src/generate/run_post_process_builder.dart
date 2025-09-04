// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:logging/logging.dart';

import '../logging/build_log_logger.dart';
import 'post_process_build_step_impl.dart';

/// Run [builder] with [inputId] as the primary input.
///
/// [addAsset] should update the build systems knowledge of what assets exist.
/// If an asset should not be written this function should throw.
/// [deleteAsset] should remove the asset from the build system, it will not be
/// deleted on disk since the `writer` has no mechanism for delete.
Future<void> runPostProcessBuilder(
  PostProcessBuilder builder,
  AssetId inputId,
  AssetReader reader,
  AssetWriter writer,
  Logger logger, {
  required void Function(AssetId) addAsset,
  required void Function(AssetId) deleteAsset,
}) async {
  await BuildLogLogger.scopeLogAsync(() async {
    var buildStep = PostProcessBuildStepImpl(
      inputId,
      reader,
      writer,
      addAsset,
      deleteAsset,
    );
    try {
      await builder.build(buildStep);
    } finally {
      await buildStep.complete();
    }
  }, logger);
}
