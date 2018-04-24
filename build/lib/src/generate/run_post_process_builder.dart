// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../builder/logging.dart';
import '../builder/post_process_build_step.dart';
import '../builder/post_process_builder.dart';

/// Run [builder] with [inputId] as the primary input.
Future<Null> runPostProcessBuilder(
  PostProcessBuilder builder,
  AssetId inputId,
  AssetReader reader,
  AssetWriter writer,
  Logger logger,
  void Function(AssetId) addAsset,
  void Function(AssetId) deleteAsset,
) async {
  await scopeLogAsync(() async {
    var buildStep =
        postProcessBuildStep(inputId, reader, writer, addAsset, deleteAsset);
    try {
      await builder.build(buildStep);
    } finally {
      await buildStep.complete();
    }
  }, logger);
}
