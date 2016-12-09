// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import '../analyzer/resolver.dart';
import '../asset/asset.dart';
import '../asset/exceptions.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import 'build_step.dart';
import 'exceptions.dart';

/// A single step in the build processes. This represents a single input and
/// its expected and real outputs. It also handles tracking of dependencies.
class BuildStepImpl implements ManagedBuildStep {
  final Resolvers _resolvers;

  /// The primary input for this build step.
  @override
  final Asset input;

  @override
  final Logger logger;

  /// The list of all outputs which are expected/allowed to be output from this
  /// step.
  final List<AssetId> _expectedOutputs = [];

  /// A future that completes once all outputs current are done writing.
  Future _outputsCompleted = new Future(() {});

  /// Used internally for reading files.
  final AssetReader _reader;

  /// Used internally for writing files.
  final AssetWriter _writer;

  /// The current root package, used for input/output validation.
  final String _rootPackage;

  BuildStepImpl(Asset input, Iterable<AssetId> expectedOutputs, this._reader,
      this._writer, this._rootPackage, this._resolvers,
      {Logger logger})
      : this.input = input,
        this.logger = logger ?? new Logger('${input.id}') {
    _expectedOutputs.addAll(expectedOutputs);
  }

  @override
  Future<bool> hasInput(AssetId id) {
    _checkInput(id);
    return _reader.hasInput(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) {
    _checkInput(id);
    return _reader.readAsString(id, encoding: encoding);
  }

  @override
  Future writeAsString(Asset asset, {Encoding encoding: UTF8}) {
    _checkOutput(asset.id);
    var done = _writer.writeAsString(asset, encoding: encoding);
    _outputsCompleted = _outputsCompleted.then((_) => done);
    return done;
  }

  /// Synchronously record [id] as an asset that needs to be written and
  /// asynchronously write it.
  ///
  /// [id] needs to be passed separately from [asset] so that a check for
  /// allowed outputs can be performed sychronously.
  Future writeFromFuture(AssetId id, Future<Asset> asset) {
    _checkOutput(id);
    var done = asset.then((asset) => _writer.writeAsString(asset));
    _outputsCompleted = _outputsCompleted.then((_) => done);
    return done;
  }

  @override
  Future<Resolver> resolve(AssetId id,
      {bool resolveAllConstants, List<AssetId> entryPoints}) async {
    entryPoints ??= [];
    if (!entryPoints.contains(id)) entryPoints.add(id);
    return _resolvers.get(this, entryPoints, resolveAllConstants);
  }

  /// Should be called after `build` has completed. This will wait until for
  /// [_outputsCompleted].
  @override
  Future complete() => _outputsCompleted;

  /// Checks that [id] is a valid input, and throws an [InvalidInputException]
  /// if its not.
  void _checkInput(AssetId id) {
    if (id.package != _rootPackage && !id.path.startsWith('lib/')) {
      throw new InvalidInputException(id);
    }
  }

  /// Checks that [id] is a valid output, and throws an
  /// [InvalidOutputException] or [UnexpectedOutputException] if it's not.
  void _checkOutput(AssetId id) {
    if (id.package != _rootPackage) {
      throw new InvalidOutputException(
          id,
          'Files may only be output in the root (application) package. '
          'Attempted to output "$id" but the root package is '
          '"$_rootPackage".');
    }
    if (!_expectedOutputs.any((check) => check == id)) {
      throw new UnexpectedOutputException(id);
    }
  }
}
