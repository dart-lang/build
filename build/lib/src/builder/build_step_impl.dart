// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:glob/glob.dart';

import '../analyzer/resolver.dart';
import '../asset/exceptions.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import 'build_step.dart';
import 'exceptions.dart';

/// A single step in the build processes.
///
/// This represents a single input and its expected and real outputs. It also
/// handles tracking of dependencies.
class BuildStepImpl implements BuildStep {
  final Resolvers _resolvers;

  /// The primary input id for this build step.
  @override
  final AssetId inputId;

  @override
  Future<LibraryElement> get inputLibrary async =>
      (await resolver).getLibrary(inputId);

  /// The list of all outputs which are expected/allowed to be output from this
  /// step.
  final List<AssetId> _expectedOutputs;

  /// A future that completes once all outputs current are done writing.
  Future _outputsCompleted = new Future(() {});

  /// Used internally for reading files.
  final AssetReader _reader;

  /// Used internally for writing files.
  final AssetWriter _writer;

  /// The current root package, used for input/output validation.
  final String _rootPackage;

  BuildStepImpl(this.inputId, Iterable<AssetId> expectedOutputs, this._reader,
      this._writer, this._rootPackage, this._resolvers)
      : _expectedOutputs = expectedOutputs.toList();

  @override
  Future<Resolver> get resolver => _resolver ??= _resolvers.get(this);

  Future<ReleasableResolver> _resolver;

  @override
  Future<bool> hasInput(AssetId id) {
    var result = canRead(id);
    return new Future.value(result);
  }

  @override
  FutureOr<bool> canRead(AssetId id) {
    _checkInput(id);
    return new Future.value(_reader.canRead(id));
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) {
    _checkInput(id);
    return _reader.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) {
    _checkInput(id);
    return _reader.readAsString(id, encoding: encoding);
  }

  @override
  Iterable<AssetId> findAssets(Glob glob) => _reader.findAssets(glob);

  @override
  Future writeAsBytes(AssetId id, FutureOr<List<int>> bytes) {
    _checkOutput(id);
    var done = _futureOrWrite(bytes, (b) => _writer.writeAsBytes(id, b));
    _outputsCompleted = _outputsCompleted.then((_) => done);
    return done;
  }

  @override
  Future writeAsString(AssetId id, FutureOr<String> content,
      {Encoding encoding: UTF8}) {
    _checkOutput(id);
    var done = _futureOrWrite(
        content, (c) => _writer.writeAsString(id, c, encoding: encoding));
    _outputsCompleted = _outputsCompleted.then((_) => done);
    return done;
  }

  Future _futureOrWrite<T>(FutureOr<T> content, Future write(T content)) =>
      (content is Future<T>) ? content.then(write) : write(content);

  /// Waits for work to finish and cleans up resources.
  ///
  /// This method should be called after a build has completed. After the
  /// returned [Future] completes then all outputs have been written and the
  /// [Resolver] for this build step - if any - has been released.
  Future complete() async {
    await _outputsCompleted;
    (await _resolver)?.release();
  }

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
