// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';

/// Describes if and how a [SingleStepReader] should read an [AssetId].
class Readability {
  final bool canRead;
  final bool inSamePhase;

  const Readability({required this.canRead, required this.inSamePhase});

  /// Determines readability for a node written in a previous build phase, which
  /// means that [ownOutput] is impossible.
  factory Readability.fromPreviousPhase(bool readable) =>
      readable ? Readability.readable : Readability.notReadable;

  static const Readability notReadable = Readability(
    canRead: false,
    inSamePhase: false,
  );
  static const Readability readable = Readability(
    canRead: true,
    inSamePhase: false,
  );
  static const Readability ownOutput = Readability(
    canRead: true,
    inSamePhase: true,
  );
}

typedef IsReadable =
    FutureOr<Readability> Function(
      AssetNode node,
      int phaseNum,
      AssetWriterSpy? writtenAssets,
    );

/// Signature of a function throwing an [InvalidInputException] if the given
/// asset [id] is an invalid input in a build.
typedef CheckInvalidInput = void Function(AssetId id);

/// An [AssetReader] with a lifetime equivalent to that of a single step in a
/// build.
///
/// A step is a single Builder and primary input (or package for package
/// builders) combination.
///
/// Limits reads to the assets which are sources or were generated by previous
/// phases.
///
/// Tracks the assets and globs read during this step for input dependency
/// tracking.
class SingleStepReader extends AssetReader implements AssetReaderState {
  @override
  late final AssetFinder assetFinder = FunctionAssetFinder(_findAssets);

  @override
  final InputTracker inputTracker = InputTracker();

  final AssetGraph _assetGraph;
  final AssetReader _delegate;
  final int _phaseNumber;
  final String _primaryPackage;
  final AssetWriterSpy? _writtenAssets;
  final IsReadable _isReadableNode;
  final CheckInvalidInput _checkInvalidInput;
  final Future<GlobAssetNode> Function(Glob glob, String package, int phaseNum)?
  _getGlobNode;

  SingleStepReader(
    this._delegate,
    this._assetGraph,
    this._phaseNumber,
    this._primaryPackage,
    this._isReadableNode,
    this._checkInvalidInput, [
    this._getGlobNode,
    this._writtenAssets,
  ]);

  @override
  SingleStepReader copyWith({
    AssetPathProvider? assetPathProvider,
    FilesystemCache? cache,
  }) => SingleStepReader(
    _delegate.copyWith(assetPathProvider: assetPathProvider, cache: cache),
    _assetGraph,
    _phaseNumber,
    _primaryPackage,
    _isReadableNode,
    _checkInvalidInput,
    _getGlobNode,
    _writtenAssets,
  );

  @override
  Filesystem get filesystem => _delegate.filesystem;

  @override
  FilesystemCache get cache => _delegate.cache;

  @override
  AssetPathProvider get assetPathProvider => _delegate.assetPathProvider;

  /// Checks whether [id] can be read by this step - attempting to build the
  /// asset if necessary.
  ///
  /// If [catchInvalidInputs] is set to true and [_checkInvalidInput] throws an
  /// [InvalidInputException], this method will return `false` instead of
  /// throwing.
  Future<bool> _isReadable(
    AssetId id, {
    bool catchInvalidInputs = false,
  }) async {
    try {
      _checkInvalidInput(id);
    } on InvalidInputException {
      if (catchInvalidInputs) return false;
      rethrow;
    } on PackageNotFoundException {
      if (catchInvalidInputs) return false;
      rethrow;
    }

    final node = _assetGraph.get(id);
    if (node == null) {
      inputTracker.assetsRead.add(id);
      _assetGraph.add(SyntheticSourceAssetNode(id));
      return false;
    }

    final readability = await _isReadableNode(
      node,
      _phaseNumber,
      _writtenAssets,
    );
    if (!readability.inSamePhase) {
      inputTracker.assetsRead.add(id);
    }

    return readability.canRead;
  }

  @override
  Future<bool> canRead(AssetId id) async {
    final isReadable = await _isReadable(id, catchInvalidInputs: true);
    if (!isReadable) return false;

    var node = _assetGraph.get(id);
    // No need to check readability for [GeneratedAssetNode], they are always
    // readable.
    if (node is! GeneratedAssetNode && !await _delegate.canRead(id)) {
      return false;
    }
    await _ensureDigest(id);
    return true;
  }

  @override
  Future<Digest> digest(AssetId id) async {
    final isReadable = await _isReadable(id);

    if (!isReadable) {
      throw AssetNotFoundException(id);
    }
    return _ensureDigest(id);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    final isReadable = await _isReadable(id);
    if (!isReadable) {
      throw AssetNotFoundException(id);
    }
    await _ensureDigest(id);
    return _delegate.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    final isReadable = await _isReadable(id);
    if (!isReadable) {
      throw AssetNotFoundException(id);
    }
    await _ensureDigest(id);
    return _delegate.readAsString(id, encoding: encoding);
  }

  // This is only for generators, so only `BuildStep` needs to implement it.
  @override
  Stream<AssetId> findAssets(Glob glob) => throw UnimplementedError();

  Stream<AssetId> _findAssets(Glob glob, String? _) {
    if (_getGlobNode == null) {
      throw StateError('this reader does not support `findAssets`');
    }
    var streamCompleter = StreamCompleter<AssetId>();

    _getGlobNode(glob, _primaryPackage, _phaseNumber).then((globNode) {
      inputTracker.assetsRead.add(globNode.id);
      streamCompleter.setSourceStream(Stream.fromIterable(globNode.results!));
    });
    return streamCompleter.stream;
  }

  /// Returns the `lastKnownDigest` of [id], computing and caching it if
  /// necessary.
  ///
  /// Note that [id] must exist in the asset graph.
  FutureOr<Digest> _ensureDigest(AssetId id) {
    var node = _assetGraph.get(id)!;
    if (node.lastKnownDigest != null) return node.lastKnownDigest!;
    return _delegate.digest(id).then((digest) => node.lastKnownDigest = digest);
  }
}
