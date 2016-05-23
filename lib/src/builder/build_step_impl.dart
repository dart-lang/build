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
import '../asset/exceptions.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../util/barback.dart';
import 'build_step.dart';
import 'exceptions.dart';

/// A single step in the build processes. This represents a single input and
/// its expected and real outputs. It also handles tracking of dependencies.
class BuildStepImpl implements BuildStep {
  /// Single `resolvers` instance for all [BuildStepImpl]s
  static code_transformers.Resolvers resolvers =
      new code_transformers.Resolvers(code_transformers.dartSdkDirectory,
          useSharedSources: true);

  /// The primary input for this build step.
  @override
  final Asset input;

  /// The list of all outputs which are expected/allowed to be output from this
  /// step.
  final List<AssetId> expectedOutputs;

  /// The [Logger] for this [BuildStep].
  @override
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

  /// The current root package, used for input/output validation.
  final String _rootPackage;

  BuildStepImpl(this.input, Iterable<AssetId> expectedOutputs, this._reader,
      this._writer, this._rootPackage)
      : expectedOutputs = new List.unmodifiable(expectedOutputs) {
    /// The [input] is always a dependency.
    _dependencies.add(input.id);
  }

  /// Checks if an [Asset] by [id] exists as an input for this [BuildStep].
  @override
  Future<bool> hasInput(AssetId id) {
    _checkInput(id);
    _dependencies.add(id);
    return _reader.hasInput(id);
  }

  /// Reads an [Asset] by [id] as a [String] using [encoding].
  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) {
    _checkInput(id);
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
    _checkOutput(asset);
    _outputs.add(asset);
    var done = _writer.writeAsString(asset, encoding: encoding);
    _outputsCompleted = _outputsCompleted.then((_) => done);
  }

  /// Resolves [id] and returns a [Future<Resolver>] once that is done.
  @override
  Future<Resolver> resolve(AssetId id,
      {bool resolveAllConstants, List<AssetId> entryPoints}) async {
    entryPoints ??= [];
    if (!entryPoints.contains(id)) entryPoints.add(id);
    return new Resolver(await resolvers.get(toBarbackTransform(this),
        entryPoints.map(toBarbackAssetId).toList(), resolveAllConstants));
  }

  /// Should be called after `build` has completed. This will wait until for
  /// [_outputsCompleted].
  Future complete() async {
    await _outputsCompleted;
  }

  /// Checks that [id] is a valid input, and throws an [InvalidInputException]
  /// if its not.
  void _checkInput(AssetId id) {
    if (id.package != _rootPackage && !id.path.startsWith('lib/')) {
      throw new InvalidInputException(id);
    }
  }

  /// Checks that [asset] is a valid output, and throws an
  /// [InvalidOutputException] or [UnexpectedOutputException] if it's not.
  void _checkOutput(Asset asset) {
    if (asset.id.package != _rootPackage) {
      throw new InvalidOutputException(
          asset, 'Files may only be output in the root (application) package.');
    }
    if (!expectedOutputs.any((id) => id == asset.id)) {
      throw new UnexpectedOutputException(asset);
    }
  }
}
