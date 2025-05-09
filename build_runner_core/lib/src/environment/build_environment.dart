// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:logging/logging.dart';

import '../asset/reader_writer.dart';
import '../asset/writer.dart';
import '../generate/build_directory.dart';
import '../generate/build_result.dart';
import '../generate/finalized_assets_view.dart';
import '../package_graph/package_graph.dart';
import 'create_merged_dir.dart';

final _logger = Logger('IOEnvironment');

/// The I/O and UI environment that the build runs in.
class BuildEnvironment {
  final AssetReader reader;
  final RunnerAssetWriter writer;

  final bool _isInteractive;

  final bool _outputSymlinksOnly;

  final PackageGraph _packageGraph;

  final void Function(LogRecord)? _onLogOverride;

  final Future<BuildResult> Function(
    BuildResult,
    FinalizedAssetsView,
    AssetReader,
    Set<BuildDirectory>,
  )?
  _finalizeBuildOverride;

  BuildEnvironment._(
    this.reader,
    this.writer,
    this._isInteractive,
    this._outputSymlinksOnly,
    this._packageGraph,
    this._onLogOverride,
    this._finalizeBuildOverride,
  );

  BuildEnvironment copyWith({
    void Function(LogRecord)? onLogOverride,
    RunnerAssetWriter? writer,
    AssetReader? reader,
  }) => BuildEnvironment._(
    reader ?? this.reader,
    writer ?? this.writer,
    _isInteractive,
    _outputSymlinksOnly,
    _packageGraph,
    onLogOverride ?? _onLogOverride,
    _finalizeBuildOverride,
  );

  factory BuildEnvironment(
    PackageGraph packageGraph, {
    AssetReader? reader,
    RunnerAssetWriter? writer,
    bool? assumeTty,
    bool outputSymlinksOnly = false,
    void Function(LogRecord)? onLogOverride,
    Future<BuildResult> Function(
      BuildResult,
      FinalizedAssetsView,
      AssetReader,
      Set<BuildDirectory>,
    )?
    finalizeBuildOverride,
  }) {
    if (outputSymlinksOnly && Platform.isWindows) {
      _logger.warning(
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
      assumeTty == true || _canPrompt(),
      outputSymlinksOnly,
      packageGraph,
      onLogOverride,
      finalizeBuildOverride,
    );
  }

  void onLog(LogRecord record) {
    if (_onLogOverride != null) {
      _onLogOverride(record);
      return;
    }
    if (record.level >= Level.SEVERE) {
      stderr.writeln(record);
    } else {
      stdout.writeln(record);
    }
  }

  /// Prompt the user for input.
  ///
  /// The message and choices are displayed to the user and the index of the
  /// chosen option is returned.
  ///
  /// If this environmment is non-interactive (such as when running in a test)
  /// this method should throw [NonInteractiveBuildException].
  Future<int> prompt(String message, List<String> choices) async {
    if (!_isInteractive) throw NonInteractiveBuildException();
    while (true) {
      stdout.writeln('\n$message');
      for (var i = 0, l = choices.length; i < l; i++) {
        stdout.writeln('${i + 1} - ${choices[i]}');
      }
      final input = stdin.readLineSync()!;
      final choice = int.tryParse(input) ?? -1;
      if (choice > 0 && choice <= choices.length) return choice - 1;
      stdout.writeln(
        'Unrecognized option $input, '
        'a number between 1 and ${choices.length} expected',
      );
    }
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
    Set<BuildDirectory> buildDirs,
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

bool _canPrompt() =>
    stdioType(stdin) == StdioType.terminal &&
    // Assume running inside a test if the code is running as a `data:` URI
    Platform.script.scheme != 'data';

BuildResult _convertToFailure(
  BuildResult previous, {
  FailureType? failureType,
}) => BuildResult(
  BuildStatus.failure,
  previous.outputs,
  performance: previous.performance,
  failureType: failureType,
);

/// Thrown when the build attempts to prompt the users but no prompt is
/// possible.
class NonInteractiveBuildException implements Exception {}
