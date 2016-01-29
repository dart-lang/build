// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import '../asset/asset.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import 'build_step.dart';
import 'exceptions.dart';

/// A single step in the build processes. This represents a single input and
/// its expected and real outputs. It also handles tracking of dependencies.
class BuildStepImpl implements BuildStep {
  /// The primary input for this build step.
  @override
  final Asset input;

  /// The list of all outputs which are expected/allowed to be output from this
  /// step.
  final List<AssetId> expectedOutputs;

  /// The actual outputs of this build step.
  UnmodifiableListView<Asset> get outputs => new UnmodifiableListView(_outputs);
  final List<Asset> _outputs = [];

  /// A future that completes once all outputs current are done writing.
  Future get outputsCompleted => _outputsCompleted;
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
  ///
  /// If [trackAsDependency] is true, then [id] will be marked as a dependency
  /// of all [expectedOutputs].
  Future<bool> hasInput(AssetId id, {bool trackAsDependency: true}) {
    if (trackAsDependency) _dependencies.add(id);
    return _reader.hasInput(id);
  }

  /// Reads an [Asset] by [id] as a [String] using [encoding].
  ///
  /// If [trackAsDependency] is true, then [id] will be marked as a dependency
  /// of all [expectedOutputs].
  @override
  Future<String> readAsString(AssetId id,
      {Encoding encoding: UTF8, bool trackAsDependency: true}) {
    if (trackAsDependency) _dependencies.add(id);
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

  /// Explicitly adds [id] as a dependency of all [expectedOutputs]. This is
  /// not generally necessary unless forcing `trackAsDependency: false` when
  /// calling [readAsString].
  @override
  void addDependency(AssetId id) {
    _dependencies.add(id);
  }
}
