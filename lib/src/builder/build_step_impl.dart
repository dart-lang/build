// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:code_transformers/resolver.dart' as code_transformers;
import 'package:logging/logging.dart';

import '../analyzer/resolver.dart';
import '../asset/asset.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../util/barback.dart';
import 'build_step.dart';
import 'exceptions.dart';

/// A single step in the build processes. This represents a single input and
/// its expected and real outputs. It also handles tracking of dependencies.
class BuildStepImpl implements BuildStep {
  static code_transformers.Resolvers _resolvers =
      new code_transformers.Resolvers(code_transformers.dartSdkDirectory);

  /// The primary input for this build step.
  @override
  final Asset input;

  /// The list of all outputs which are expected/allowed to be output from this
  /// step.
  final List<AssetId> expectedOutputs;

  /// The [Logger] for this [BuildStep].
  Logger get logger {
    _logger ??= new Logger(input.id.toString());
    return _logger;
  }
  Logger _logger;

  /// The actual outputs of this build step.
  UnmodifiableListView<Asset> get outputs => new UnmodifiableListView(_outputs);
  final List<Asset> _outputs = [];

  /// A future that completes once all outputs current are done writing.
  Future _outputsCompleted = new Future(() {});

  /// The dependencies read in during this build step.
  UnmodifiableListView<AssetId> get dependencies =>
      new UnmodifiableListView(_dependencies);
  final Set<AssetId> _dependencies = new Set<AssetId>();

  /// Used internally for reading files.
  final AssetReader _reader;

  /// Used internally for writing files.
  final AssetWriter _writer;

  BuildStepImpl(
      this.input, Iterable<AssetId> expectedOutputs, this._reader, this._writer)
      : expectedOutputs = new List.unmodifiable(expectedOutputs) {
    /// The [input] is always a dependency.
    _dependencies.add(input.id);
  }

  /// Checks if an [Asset] by [id] exists as an input for this [BuildStep].
  Future<bool> hasInput(AssetId id) {
    _dependencies.add(id);
    return _reader.hasInput(id);
  }

  /// Reads an [Asset] by [id] as a [String] using [encoding].
  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) {
    _dependencies.add(id);
    return _reader.readAsString(id, encoding: encoding);
  }

  /// Outputs an [Asset] using the current [AssetWriter], and adds [asset] to
  /// [outputs].
  ///
  /// Throws an [UnexpectedOutputException] if [asset] is not in
  /// [expectedOutputs].
  @override
  void writeAsString(Asset asset, {Encoding encoding: UTF8}) {
    if (!expectedOutputs.any((id) => id == asset.id)) {
      throw new UnexpectedOutputException(asset);
    }
    _outputs.add(asset);
    var done = _writer.writeAsString(asset, encoding: encoding);
    _outputsCompleted = _outputsCompleted.then((_) => done);
  }

  /// Resolves [id] and returns a [Future<Resolver>] once that is done.
  Future<Resolver> resolve(AssetId id) async => new Resolver(
      await _resolvers.get(toBarbackTransform(this), [toBarbackAssetId(id)]));

  /// Should be called after `build` has completed. This will wait until for
  /// [_outputsCompleted] and will also close the [logger].
  Future complete() async {
    await _outputsCompleted;
    await _logger?.clearListeners();
  }
}
