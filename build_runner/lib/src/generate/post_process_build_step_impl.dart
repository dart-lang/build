// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:crypto/crypto.dart' show Digest;

import 'single_step_reader_writer.dart';

class PostProcessBuildStepImpl implements PostProcessBuildStep {
  @override
  final AssetId inputId;

  final SingleStepReaderWriter _readerWriter;
  final void Function(AssetId) _addAsset;
  final void Function(AssetId) _deleteAsset;

  /// The result of any writes which are starting during this step.
  final _writeResults = <Future<Result<void>>>[];

  PostProcessBuildStepImpl(
    this.inputId,
    this._readerWriter,
    this._addAsset,
    this._deleteAsset,
  );

  @override
  Future<Digest> digest(AssetId id) =>
      inputId == id
          ? _readerWriter.digest(id)
          : Future.error(InvalidInputException(id));

  @override
  Future<List<int>> readInputAsBytes() => _readerWriter.readAsBytes(inputId);

  @override
  Future<String> readInputAsString({Encoding encoding = utf8}) =>
      _readerWriter.readAsString(inputId, encoding: encoding);

  @override
  Future<void> writeAsBytes(AssetId id, FutureOr<List<int>> bytes) {
    _addAsset(id);
    var done = _futureOrWrite(
      bytes,
      (List<int> b) => _readerWriter.writeAsBytes(id, b),
    );
    _writeResults.add(Result.capture(done));
    return done;
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    FutureOr<String> content, {
    Encoding encoding = utf8,
  }) {
    _addAsset(id);
    var done = _futureOrWrite(
      content,
      (String c) => _readerWriter.writeAsString(id, c, encoding: encoding),
    );
    _writeResults.add(Result.capture(done));
    return done;
  }

  /// Marks an asset for deletion in the post process step.
  @override
  void deletePrimaryInput() {
    _deleteAsset(inputId);
  }

  /// Waits for work to finish and cleans up resources.
  ///
  /// This method should be called after a build has completed. After the
  /// returned [Future] completes then all outputs have been written.
  @override
  Future<void> complete() async {
    await Future.wait(_writeResults.map(Result.release));
  }
}

Future<void> _futureOrWrite<T>(
  FutureOr<T> content,
  Future<void> Function(T content) write,
) => (content is Future<T>) ? content.then(write) : write(content);
