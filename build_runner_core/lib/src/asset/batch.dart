// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';

import 'writer.dart';

/// A batch of file system writes that should be committed at once instead of
/// when [AssetWriter.writeAsBytes] or [AssetWriter.writeAsString] is called.
///
/// During a typical build run emitting generated files one-by-one, it's
/// possible that other running tools such as an analysis server will have to
/// re-analyze incomplete states multiple times.
/// By storing pending outputs in memory first and then committing them at the
/// end of the build, we have a better view over that needs to happen.
///
/// TODO(davidmorgan): this is not currently used, refactor into `Filesystem`.
final class _FileSystemWriteBatch {
  final Map<AssetId, _PendingFileState> _pendingWrites = {};

  _FileSystemWriteBatch._();

  Future<void> completeWrites(RunnerAssetWriter writer) async {
    await Future.wait(
      _pendingWrites.keys.map((id) async {
        final pending = _pendingWrites[id]!;

        if (pending.content case final content?) {
          await writer.writeAsBytes(id, content);
        } else {
          await writer.delete(id);
        }
      }),
    );

    _pendingWrites.clear();
  }
}

/// Wraps a pair of a [AssetReader] with path-providing capabilities and
/// a [RunnerAssetWriter] into a pair of readers and writers that will
/// internally buffer writes and only flush them in
/// [RunnerAssetWriter.completeBuild].
///
/// The returned reader will see pending writes by the returned writer before
/// they are flushed to the file system.
(BatchReader, BatchWriter) wrapInBatch({
  required AssetReader reader,
  required RunnerAssetWriter writer,
}) {
  final batch = _FileSystemWriteBatch._();

  return (BatchReader(reader, batch), BatchWriter(writer, batch));
}

final class _PendingFileState {
  final List<int>? content;

  const _PendingFileState(this.content);

  bool get isDeleted => content == null;
}

@internal
final class BatchReader {
  late final AssetFinder assetFinder = FunctionAssetFinder(_findAssets);

  final AssetReader _inner;
  final _FileSystemWriteBatch _batch;

  BatchReader(this._inner, this._batch);

  _PendingFileState? _stateFor(AssetId id) {
    return _batch._pendingWrites[id];
  }

  Future<bool> canRead(AssetId id) async {
    if (_stateFor(id) case final state?) {
      return !state.isDeleted;
    } else {
      return await _inner.canRead(id);
    }
  }

  // This is only for generators, so only `BuildStep` needs to implement it.
  Stream<AssetId> findAssets(Glob glob) => throw UnimplementedError();

  Stream<AssetId> _findAssets(Glob glob, String? package) {
    return _inner.assetFinder
        .find(glob, package: package)
        .where((asset) => _stateFor(asset)?.isDeleted != true);
  }

  Future<List<int>> readAsBytes(AssetId id) async {
    if (_stateFor(id) case final state?) {
      if (state.isDeleted) {
        throw AssetNotFoundException(id);
      } else {
        return state.content!;
      }
    } else {
      return await _inner.readAsBytes(id);
    }
  }

  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    if (_stateFor(id) case final state?) {
      if (state.isDeleted) {
        throw AssetNotFoundException(id);
      } else {
        return encoding.decode(state.content!);
      }
    } else {
      return await _inner.readAsString(id, encoding: encoding);
    }
  }
}

@internal
final class BatchWriter extends RunnerAssetWriter {
  final RunnerAssetWriter _inner;
  final _FileSystemWriteBatch _batch;

  BatchWriter(this._inner, this._batch);

  @override
  Future delete(AssetId id) async {
    _batch._pendingWrites[id] = const _PendingFileState(null);
  }

  @override
  Future<void> writeAsBytes(AssetId id, List<int> bytes) async {
    _batch._pendingWrites[id] = _PendingFileState(bytes);
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) async {
    _batch._pendingWrites[id] = _PendingFileState(encoding.encode(contents));
  }

  @override
  Future<void> completeBuild() async {
    await _batch.completeWrites(_inner);
  }
}
