// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:pedantic/pedantic.dart';
import 'package:pool/pool.dart';

import 'util.dart';

/// Pool for async file writes, we don't want to use too many file handles.
final _descriptorPool = Pool(32);

/// An on-disk temporary environment for running executables that don't have
/// a standard Dart library API.
class ScratchSpace {
  /// Whether or not this scratch space still exists.
  bool exists = true;

  /// The `packages` directory under the temp directory.
  final Directory packagesDir;

  /// The temp directory at the root of this [ScratchSpace].
  final Directory tempDir;

  // Assets which have a file created but are still being written to.
  final _pendingWrites = <AssetId, Future<void>>{};

  final _digests = <AssetId, Digest>{};

  ScratchSpace._(this.tempDir)
      : packagesDir = Directory(p.join(tempDir.path, 'packages'));

  factory ScratchSpace() {
    var tempDir = Directory(Directory.systemTemp
        .createTempSync('scratch_space')
        .resolveSymbolicLinksSync());
    return ScratchSpace._(tempDir);
  }

  /// Copies [id] from the tmp dir and writes it back using the [writer].
  ///
  /// Note that [BuildStep] implements [AssetWriter] and that is typically
  /// what you will want to pass in.
  ///
  /// This must be called for all outputs which you want to be included as a
  /// part of the actual build (any other outputs will be deleted with the
  /// tmp dir and won't be available to other [Builder]s).
  ///
  /// If [requireContent] is true and the file is empty an
  /// [EmptyOutputException] is thrown.
  Future<void> copyOutput(AssetId id, AssetWriter writer,
      {bool requireContent = false}) async {
    var file = fileFor(id);
    var bytes = await _descriptorPool.withResource(file.readAsBytes);
    if (requireContent && bytes.isEmpty) throw EmptyOutputException(id);
    await writer.writeAsBytes(id, bytes);
  }

  /// Deletes the temp directory for this environment.
  ///
  /// This class is no longer valid once the directory is deleted, you must
  /// create a new [ScratchSpace].
  Future<void> delete() async {
    if (!exists) {
      throw StateError(
          'Tried to delete a ScratchSpace which was already deleted');
    }
    exists = false;
    _digests.clear();
    if (_pendingWrites.isNotEmpty) {
      try {
        await Future.wait(_pendingWrites.values);
      } catch (_) {
        // Ignore any errors, we are essentially just draining this queue
        // of pending writes but don't care about the result.
      }
    }
    return tempDir.delete(recursive: true);
  }

  /// Copies [assetIds] to [tempDir] if they don't exist, using [reader] to
  /// read assets and mark dependencies.
  ///
  /// Note that [BuildStep] implements [AssetReader] and that is typically
  /// what you will want to pass in.
  ///
  /// Any asset that is under a `lib` dir will be output under a `packages`
  /// directory corresponding to its package, and any other assets are output
  /// directly under the temp dir using their unmodified path.
  Future<void> ensureAssets(Iterable<AssetId> assetIds, AssetReader reader) {
    if (!exists) {
      throw StateError('Tried to use a deleted ScratchSpace!');
    }

    var futures = assetIds.map((id) async {
      var digest = await reader.digest(id);
      var existing = _digests[id];
      if (digest == existing) {
        await _pendingWrites[id];
        return;
      }
      _digests[id] = digest;

      try {
        await _pendingWrites.putIfAbsent(
            id,
            () => _descriptorPool.withResource(() async {
                  var file = fileFor(id);
                  if (await file.exists()) {
                    await file.delete();
                  }
                  await file.create(recursive: true);
                  await file.writeAsBytes(await reader.readAsBytes(id));
                }));
      } finally {
        unawaited(_pendingWrites.remove(id));
      }
    }).toList();

    return Future.wait(futures);
  }

  /// Returns the actual [File] in this environment corresponding to [id].
  ///
  /// The returned [File] may or may not already exist. Call [ensureAssets]
  /// with [id] to make sure it is actually present.
  File fileFor(AssetId id) =>
      File(p.join(tempDir.path, p.normalize(_relativePathFor(id))));
}

/// Returns a canonical uri for [id].
///
/// If [id] is under a `lib` directory then this returns a `package:` uri,
/// otherwise it just returns [id#path].
String canonicalUriFor(AssetId id) {
  if (topLevelDir(id.path) == 'lib') {
    var packagePath =
        p.url.join(id.package, p.url.joinAll(p.url.split(id.path).skip(1)));
    return 'package:$packagePath';
  } else {
    return id.path;
  }
}

/// The path relative to the root of the environment for a given [id].
String _relativePathFor(AssetId id) =>
    canonicalUriFor(id).replaceFirst('package:', 'packages/');

/// An indication that an output file which was expect to be non-empty had no
/// content.
class EmptyOutputException implements Exception {
  final AssetId id;
  EmptyOutputException(this.id);
}
