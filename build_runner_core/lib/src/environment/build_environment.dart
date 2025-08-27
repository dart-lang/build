// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';

import '../asset/reader_writer.dart';
import '../asset/writer.dart';
import '../generate/build_directory.dart';
import '../generate/build_result.dart';
import '../generate/finalized_assets_view.dart';
import '../logging/build_log.dart';
import '../package_graph/package_graph.dart';
import 'create_merged_dir.dart';

/// The I/O environment that the build runs in.
///
/// TODO(davidmorgan): merge into `BuildOptions` and `TestOverrides`.
class BuildEnvironment {
  final AssetReader reader;
  final RunnerAssetWriter writer;

  final bool _outputSymlinksOnly;

  final PackageGraph _packageGraph;

  final Future<BuildResult> Function(
    BuildResult,
    FinalizedAssetsView,
    AssetReader,
    BuiltSet<BuildDirectory>,
  )?
  _finalizeBuildOverride;

  BuildEnvironment._(
    this.reader,
    this.writer,
    this._outputSymlinksOnly,
    this._packageGraph,
    this._finalizeBuildOverride,
  );

  BuildEnvironment copyWith({RunnerAssetWriter? writer, AssetReader? reader}) =>
      BuildEnvironment._(
        reader ?? this.reader,
        writer ?? this.writer,
        _outputSymlinksOnly,
        _packageGraph,
        _finalizeBuildOverride,
      );

  factory BuildEnvironment(
    PackageGraph packageGraph, {
    AssetReader? reader,
    RunnerAssetWriter? writer,
    bool outputSymlinksOnly = false,
    Future<BuildResult> Function(
      BuildResult,
      FinalizedAssetsView,
      AssetReader,
      BuiltSet<BuildDirectory>,
    )?
    finalizeBuildOverride,
  }) {
    if (outputSymlinksOnly && Platform.isWindows) {
      buildLog.warning(
        'Symlinks to files are not yet working on Windows, you '
        'may experience issues using this mode. Follow '
        'https://github.com/dart-lang/sdk/issues/33966 for updates.',
      );
    }

    if (reader == null || writer == null) {
      final readerWriter = ReaderWriter(packageGraph);
      reader ??= readerWriter;
      writer ??= readerWriter;
    }

    return BuildEnvironment._(
      reader,
      writer,
      outputSymlinksOnly,
      packageGraph,
      finalizeBuildOverride,
    );
  }

  /// Invoked after each build, can modify the [BuildResult] in any way, even
  /// converting it to a failure.
  ///
  /// The [finalizedAssetsView] can only be used until the returned [Future]
  /// completes, it will expire afterwords since it can no longer guarantee a
  /// consistent state.
  ///
  /// By default this returns the original result.
  ///
  /// Any operation may be performed, as determined by environment.
  Future<BuildResult> finalizeBuild(
    BuildResult buildResult,
    FinalizedAssetsView finalizedAssetsView,
    AssetReader reader,
    BuiltSet<BuildDirectory> buildDirs,
  ) async {
    if (_finalizeBuildOverride != null) {
      return _finalizeBuildOverride(
        buildResult,
        finalizedAssetsView,
        reader,
        buildDirs,
      );
    }
    if (buildDirs.any(
          (target) => target.outputLocation?.path.isNotEmpty ?? false,
        ) &&
        buildResult.status == BuildStatus.success) {
      if (!await createMergedOutputDirectories(
        buildDirs,
        _packageGraph,
        this,
        reader,
        finalizedAssetsView,
        _outputSymlinksOnly,
      )) {
        return _convertToFailure(
          buildResult,
          failureType: FailureType.cantCreate,
        );
      }
    }
    return buildResult;
  }
}

BuildResult _convertToFailure(
  BuildResult previous, {
  FailureType? failureType,
}) => BuildResult(
  BuildStatus.failure,
  previous.outputs,
  performance: previous.performance,
  failureType: failureType,
);
