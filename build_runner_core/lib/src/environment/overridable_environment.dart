// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:logging/logging.dart';

import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../changes/build_script_updates.dart';
import '../generate/build_result.dart';
import '../generate/finalized_assets_view.dart';
import '../package_graph/package_graph.dart';
import 'build_environment.dart';

/// A [BuildEnvironment] which can have individual features overridden.
class OverrideableEnvironment implements BuildEnvironment {
  final BuildEnvironment _default;

  final RunnerAssetReader _reader;
  final RunnerAssetWriter _writer;

  final void Function(LogRecord) _onLog;

  final Future<BuildResult> Function(
      BuildResult result,
      FinalizedAssetsView finalizedAssetsView,
      AssetReader reader) _finalizeBuild;

  final Future<BuildScriptUpdates> Function(
    RunnerAssetReader assetReader,
    PackageGraph packageGraph,
    AssetGraph graph,
  ) _buildScriptUpdates;

  OverrideableEnvironment(
    this._default, {
    RunnerAssetReader reader,
    RunnerAssetWriter writer,
    void Function(LogRecord) onLog,
    Future<BuildResult> Function(BuildResult result,
            FinalizedAssetsView finalizedAssetsView, AssetReader reader)
        finalizeBuild,
    Future<BuildScriptUpdates> Function(
    AssetReader assetReader,
    PackageGraph packageGraph,
    AssetGraph graph,
      ) buildScriptUpdates,
  })  : _reader = reader,
        _writer = writer,
        _onLog = onLog,
        _buildScriptUpdates = buildScriptUpdates,
        _finalizeBuild = finalizeBuild;

  @override
  RunnerAssetReader get reader => _reader ?? _default.reader;

  @override
  RunnerAssetWriter get writer => _writer ?? _default.writer;

  @override
  Future<BuildResult> finalizeBuild(BuildResult buildResult,
          FinalizedAssetsView finalizedAssetsView, AssetReader reader) =>
      (_finalizeBuild ?? _default.finalizeBuild)(
          buildResult, finalizedAssetsView, reader);

  @override
  void onLog(LogRecord record) {
    if (_onLog != null) {
      _onLog(record);
    } else {
      _default.onLog(record);
    }
  }

  @override
  Future<int> prompt(String message, List<String> choices) =>
      _default.prompt(message, choices);

  @override
  Future<BuildScriptUpdates> buildScriptUpdates(PackageGraph packageGraph, AssetGraph graph) {
    if (_buildScriptUpdates != null) {
      return _buildScriptUpdates(reader, packageGraph, graph);
    }
    return _default.buildScriptUpdates(packageGraph, graph);
  }
}
