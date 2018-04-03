// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:crypto/src/digest.dart';

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';

/// A simplified [BuildStep] which can only read its primary input, and can't
/// get a [Resolver] or any [Resource]s, at least for now.
class PostProcessBuildStep {
  final AssetId inputId;

  final PostProcessAnchorNode _anchorNode;
  final AssetGraph _assetGraph;
  final int _phaseNum;
  final AssetReader _reader;
  final AssetWriter _writer;

  /// The result of any writes which are starting during this step.
  final _writeResults = <Future<Result>>[];

  PostProcessBuildStep(this.inputId, this._reader, this._writer,
      this._assetGraph, this._anchorNode, this._phaseNum);

  Future<Digest> digest(AssetId id) => inputId == id
      ? _reader.digest(id)
      : new Future.error(new InvalidInputException(id));

  Future<List<int>> readInputAsBytes() => _reader.readAsBytes(inputId);

  Future<String> readInputAsString({Encoding encoding: utf8}) =>
      _reader.readAsString(inputId, encoding: encoding);

  Future writeAsBytes(AssetId id, FutureOr<List<int>> bytes) {
    _checkOutput(id);
    _addNode(id);
    var done =
        _futureOrWrite(bytes, (List<int> b) => _writer.writeAsBytes(id, b));
    _writeResults.add(Result.capture(done));
    return done;
  }

  Future writeAsString(AssetId id, FutureOr<String> content,
      {Encoding encoding: utf8}) {
    _checkOutput(id);
    _addNode(id);
    var done = _futureOrWrite(content,
        (String c) => _writer.writeAsString(id, c, encoding: encoding));
    _writeResults.add(Result.capture(done));
    return done;
  }

  /// Marks an asset for deletion in the post process step.
  void deletePrimaryInput() {
    var node = _assetGraph.get(inputId);
    node.isDeleted = true;
  }

  /// Waits for work to finish and cleans up resources.
  ///
  /// This method should be called after a build has completed. After the
  /// returned [Future] completes then all outputs have been written.
  Future complete() async {
    await Future.wait(_writeResults.map(Result.release));
  }

  void _addNode(AssetId id) {
    var node = new GeneratedAssetNode(id,
        primaryInput: inputId,
        builderOptionsId: _anchorNode.builderOptionsId,
        isHidden: true,
        phaseNumber: _phaseNum,
        wasOutput: true,
        isFailure: false,
        state: GeneratedNodeState.upToDate);
    _assetGraph.add(node);
    _anchorNode.outputs.add(id);
  }

  /// Checks if [id] is a valid output id.
  void _checkOutput(AssetId id) {
    if (_assetGraph.contains(id)) {
      throw new InvalidOutputException(id, 'Asset already exists');
    }
  }
}

Future _futureOrWrite<T>(FutureOr<T> content, Future write(T content)) =>
    (content is Future<T>) ? content.then(write) : write(content as T);
