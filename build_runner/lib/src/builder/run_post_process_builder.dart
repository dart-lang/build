// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';
// TODO: expose this from package:build
import 'package:build/src/builder/logging.dart';
import 'package:logging/logging.dart';

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import 'post_process_build_step.dart';
import 'post_process_builder.dart';

/// Run [builder] with [inputId] as the primary input.
Future<Null> runPostProcessBuilder(
    PostProcessBuilder builder,
    AssetId inputId,
    AssetReader reader,
    AssetWriter writer,
    Logger logger,
    AssetGraph assetGraph,
    PostProcessAnchorNode anchorNode,
    int phaseNum) async {
  await scopeLogAsync(() async {
    var buildStep = new PostProcessBuildStep(
        inputId, reader, writer, assetGraph, anchorNode, phaseNum);
    try {
      await builder.build(buildStep);
    } finally {
      await buildStep.complete();
    }
  }, logger);
}
