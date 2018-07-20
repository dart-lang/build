// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import '../asset/file_based.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/optional_output_tracker.dart';
import '../generate/build_result.dart';
import '../package_graph/package_graph.dart';
import 'build_environment.dart';



/// A [BuildEnvironment] writing to disk and stdout.
class IOEnvironment implements BuildEnvironment {
  @override
  final RunnerAssetReader reader;

  @override
  final RunnerAssetWriter writer;

  final bool _isInteractive;

  IOEnvironment(PackageGraph packageGraph, bool assumeTty)
      : _isInteractive = assumeTty == true || _canPrompt(),
        reader = new FileBasedAssetReader(packageGraph),
        writer = new FileBasedAssetWriter(packageGraph);

  @override
  void onLog(LogRecord record) {
    if (record.level >= Level.SEVERE) {
      stderr.writeln(record);
    } else {
      stdout.writeln(record);
    }
  }

  @override
  Future<int> prompt(String message, List<String> choices) async {
    if (!_isInteractive) throw new NonInteractiveBuildException();
    while (true) {
      stdout.writeln('\n$message');
      for (var i = 0, l = choices.length; i < l; i++) {
        stdout.writeln('${i + 1} - ${choices[i]}');
      }
      final input = stdin.readLineSync();
      final choice = int.tryParse(input) ?? -1;
      if (choice > 0 && choice <= choices.length) return choice - 1;
      stdout.writeln('Unrecognized option $input, '
          'a number between 1 and ${choices.length} expected');
    }
  }

  @override
  Future<BuildResult> finalizeBuild(BuildResult buildResult, AssetGraph assetGraph, OptionalOutputTracker optionalOutputsTracker) {
    if (_outputMap != null && buildResult.status == BuildStatus.success) {
      AssetReader reader;
      reader = _reader;
      while (reader is DelegatingAssetReader &&
          reader is! PathProvidingAssetReader) {
        reader = (reader as DelegatingAssetReader).delegate;
      }
      if (reader is! PathProvidingAssetReader) {
        _logger.severe('Unable to create a merged output directory since no '
            'AssetReader implements PathProvidingAssetReader.');
        return _convertToFailure(buildResult, failureType: FailureType.cantCreate);
      } else {
        if (!await _environment.createOutputDirectories(
            _outputMap,
            _assetGraph,
            _packageGraph,
            reader as PathProvidingAssetReader,
            _environment,
            optionalOutputTracker,
            symlinkOnly: _outputSymlinksOnly)) {
          return _convertToFailure(buildResult, failureType: FailureType.cantCreate);
        }
      }
    }
    return buildResult;
  }
}

bool _canPrompt() =>
    stdioType(stdin) == StdioType.terminal &&
    // Assume running inside a test if the code is running as a `data:` URI
    Platform.script.scheme != 'data';


BuildResult _convertToFailure(BuildResult previous,
        {FailureType failureType}) =>
    new BuildResult(
      BuildStatus.failure,
      previous.outputs,
      performance: previous.performance,
      failureType: failureType,
    );
