// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';

import 'reader.dart';

@Deprecated('No longer used')
typedef OnDelete = void Function(AssetId id);

abstract class RunnerAssetWriter implements AssetWriter {
  Future delete(AssetId id);

  /// Potentially runs pending work that needs to happen just before the build
  /// completes, after all other interactions with this [AssetWriter] have
  /// already been completed.
  @mustCallSuper
  FutureOr<void> onBuildComplete();
}

/// A [RunnerAssetWriter] implementation that performs all writes at once in
/// [onBuildComplete].
///
/// This write behavior may reduce load on external tools doing work on each
/// file system change (like the analysis server).
class DelayedAssetWriter implements RunnerAssetWriter {
  final RunnerAssetWriter _delegate;

  /// A map of asset ids to content that has been written with the [AssetWriter]
  /// API but not yet been flushed to the underlying delegate (in [onBuildComplete]).
  ///
  /// The values are non-null if the contents of the file have been overwritten,
  /// or null if the asset has been deleted.
  final Map<AssetId, List<int>?> overlay = {};

  DelayedAssetWriter(this._delegate);

  /// Obtain a [RunnerAssetReader] capable of reading pending writes of this
  /// writer (before they are persisted with [onBuildComplete]).
  RunnerAssetReader reader(RunnerAssetReader delegate, String rootPackage) {
    return _DelayAwareReader(delegate, this, rootPackage);
  }

  @override
  Future delete(AssetId id) async {
    overlay[id] = null;
  }

  @override
  Future<void> onBuildComplete() async {
    await Future.wait(overlay.entries.map((entry) {
      final value = entry.value;
      if (value == null) {
        return _delegate.delete(entry.key);
      } else {
        return _delegate.writeAsBytes(entry.key, value);
      }
    }));

    await _delegate.onBuildComplete();
    overlay.clear();
  }

  @override
  Future<void> writeAsBytes(AssetId id, List<int> bytes) async {
    overlay[id] = bytes;
  }

  @override
  Future<void> writeAsString(AssetId id, String contents,
      {Encoding encoding = utf8}) {
    final encoded = encoding.encode(contents);
    return writeAsBytes(id, encoded);
  }
}

class _DelayAwareReader extends AssetReader implements RunnerAssetReader {
  final RunnerAssetReader _delegate;
  final DelayedAssetWriter _delayed;
  final String _rootPackage;

  _DelayAwareReader(this._delegate, this._delayed, this._rootPackage);

  @override
  Future<bool> canRead(AssetId id) async {
    if (_delayed.overlay.containsKey(id)) {
      return _delayed.overlay[id] != null;
    }

    return await _delegate.canRead(id);
  }

  @override
  Stream<AssetId> findAssets(Glob glob, {String? package}) async* {
    package ??= _rootPackage;

    await for (final assetId in _delegate.findAssets(glob, package: package)) {
      if (!_delayed.overlay.containsKey(assetId)) {
        // Overlay ids are reported afterwards
        yield assetId;
      }
    }

    for (final entry in _delayed.overlay.entries) {
      final assetId = entry.key;
      if (assetId.package == package &&
          glob.matches(assetId.path) &&
          entry.value != null) {
        yield entry.key;
      }
    }
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    if (_delayed.overlay.containsKey(id)) {
      final fromOverlay = _delayed.overlay[id];
      if (fromOverlay == null) {
        throw AssetNotFoundException(id);
      }

      return fromOverlay;
    }

    return await _delegate.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    return encoding.decode(await readAsBytes(id));
  }
}
