// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';

import '../environment/io_environment.dart';
import 'reader.dart';
import 'writer.dart';

/// Runs [inner] in a zone that indicates to compatible [RunnerAssetWriter]s
/// that written assets should not be written to the underlying file system
/// directly, but rather in a batch after [inner] has completed.
///
/// This solves a common issue when `build_runner` and other tools such as an
/// analysis server are running concurrently: During a build, generated assets
/// are written one-by-one. The analyzer will discover these changes while the
/// build is running and report lints for a partial state of the workspace where
/// not all generated files are present, leading to a subpar experience.
///
/// [runWithFileSystemBatch] is intended to wrap a single build run. Instead of
/// writing assets directly, they are first cached in memory and then written at
/// once after the build has completed. This causes fewer invalidations for
/// external tools. The [writer] will be used to complete the writes collected
/// while running [inner].
///
/// The underlying asset readers and writes both need to support file system
/// batches (reader support is crucial to report changed assets that have not
/// been flushed to the file system yet). The default [IOEnvironment] will use
/// batch-aware readers and writers when not in low-resources mode.
Future<T> runWithFileSystemBatch<T>(
  Future<T> Function() inner,
  RunnerAssetWriter writer,
) async {
  final batch = FileSystemWriteBatch._();
  final result =
      await runZoned(inner, zoneValues: {FileSystemWriteBatch._key: batch});
  await batch._completeWrites(writer);
  return result;
}

/// A batch of file system writes that should be committed at once instead of
/// when [AssetWriter.writeAsBytes] or [AssetWriter.writeAsString] is called.
///
/// During a typical build run emitting generated files one-by-one, it's
/// possible that other running tools such as an analysis server will have to
/// re-analyze incomplete states multiple times.
/// By storing pending outputs in memory first and then committing them at the
/// end of the build, we have a better view over that needs to happen.
///
/// The default [IOEnvironment] uses readers and writes that are batch-aware
/// outside of low-memory mode.
@internal
final class FileSystemWriteBatch {
  final Map<AssetId, _PendingFileState> _pendingWrites = {};

  FileSystemWriteBatch._();

  Future<void> _completeWrites(RunnerAssetWriter writer) async {
    await Future.wait(_pendingWrites.entries.map((e) async {
      if (e.value.content case final content?) {
        await writer.writeAsBytes(e.key, content);
      } else {
        await writer.delete(e.key);
      }
    }));

    _pendingWrites.clear();
  }

  static FileSystemWriteBatch? get current {
    return Zone.current[_key] as FileSystemWriteBatch?;
  }

  static final _key = Object();
}

final class _PendingFileState {
  final List<int>? content;

  const _PendingFileState(this.content);

  bool get isDeleted => content == null;
}

@internal
final class BatchAwareReader extends AssetReader
    implements RunnerAssetReader, PathProvidingAssetReader {
  final RunnerAssetReader _inner;
  final PathProvidingAssetReader _innerPathProviding;

  BatchAwareReader(this._inner, this._innerPathProviding);

  _PendingFileState? _stateFor(AssetId id) {
    if (FileSystemWriteBatch.current case final batch?) {
      return batch._pendingWrites[id];
    } else {
      return null;
    }
  }

  @override
  Future<bool> canRead(AssetId id) async {
    if (_stateFor(id) case final state?) {
      return !state.isDeleted;
    } else {
      return await _inner.canRead(id);
    }
  }

  @override
  Stream<AssetId> findAssets(Glob glob, {String? package}) {
    return _inner
        .findAssets(glob, package: package)
        .where((asset) => _stateFor(asset)?.isDeleted != true);
  }

  @override
  String pathTo(AssetId id) {
    return _innerPathProviding.pathTo(id);
  }

  @override
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

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    final bytes = await readAsBytes(id);
    return encoding.decode(bytes);
  }
}

@internal
final class BatchAwareWriter extends RunnerAssetWriter {
  final RunnerAssetWriter _inner;

  BatchAwareWriter(this._inner);

  FileSystemWriteBatch? _batchFor(AssetId id) {
    // Don't batch writes for hidden files unlikely to be consumed by other
    // tools.
    if (id.pathSegments case ['.dart_tool', ...]) {
      return null;
    }

    return FileSystemWriteBatch.current;
  }

  @override
  Future delete(AssetId id) async {
    if (_batchFor(id) case final batch?) {
      batch._pendingWrites[id] = const _PendingFileState(null);
    } else {
      await _inner.delete(id);
    }
  }

  @override
  Future<void> writeAsBytes(AssetId id, List<int> bytes) async {
    if (_batchFor(id) case final batch?) {
      batch._pendingWrites[id] = _PendingFileState(bytes);
    } else {
      await _inner.writeAsBytes(id, bytes);
    }
  }

  @override
  Future<void> writeAsString(AssetId id, String contents,
      {Encoding encoding = utf8}) async {
    if (_batchFor(id) case final batch?) {
      batch._pendingWrites[id] = _PendingFileState(encoding.encode(contents));
    } else {
      await _inner.writeAsString(id, contents, encoding: encoding);
    }
  }
}
