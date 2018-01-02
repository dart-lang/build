// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

import 'util.dart';

/// Pool for async file writes, we don't want to use too many file handles.
final _descriptorPool = new Pool(32);

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
  final _pendingWrites = <AssetId, Future<Null>>{};

  ScratchSpace._(Directory tempDir)
      : packagesDir = new Directory(p.join(tempDir.path, 'packages')),
        this.tempDir = tempDir;

  factory ScratchSpace() {
    var tempDir = new Directory(Directory.systemTemp
        .createTempSync('scratch_space')
        .resolveSymbolicLinksSync());
    return new ScratchSpace._(tempDir);
  }

  /// Copies [id] from the tmp dir and writes it back using the [writer].
  ///
  /// Note that [BuildStep] implements [AssetWriter] and that is typically
  /// what you will want to pass in.
  ///
  /// This must be called for all outputs which you want to be included as a
  /// part of the actual build (any other outputs will be deleted with the
  /// tmp dir and won't be available to other [Builder]s).
  Future copyOutput(AssetId id, AssetWriter writer) async {
    var file = fileFor(id);
    var bytes = await _descriptorPool.withResource(file.readAsBytes);
    await writer.writeAsBytes(id, bytes);
  }

  /// Deletes the temp directory for this environment.
  ///
  /// This class is no longer valid once the directory is deleted, you must
  /// create a new [ScratchSpace].
  Future delete() {
    if (!exists) {
      throw new StateError(
          'Tried to delete a ScratchSpace which was already deleted');
    }
    exists = false;
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
  Future ensureAssets(Iterable<AssetId> assetIds, AssetReader reader) {
    if (!exists) {
      throw new StateError('Tried to use a deleted ScratchSpace!');
    }

    var futures = <Future>[];
    for (var id in assetIds) {
      // Always track `id` as a dependency, we do this by just calling
      // `canRead` for now.
      //
      // ignore: unawaited_futures
      reader.canRead(id);
      var file = fileFor(id);
      if (file.existsSync()) {
        var pending = _pendingWrites[id];
        if (pending != null) futures.add(pending);
      } else {
        file.createSync(recursive: true);
        var done = () async {
          var bytes = await reader.readAsBytes(id);
          await _descriptorPool.withResource(() async {
            await file.writeAsBytes(bytes);
            // ignore: unawaited_futures
            _pendingWrites.remove(id);
          });
        }();
        _pendingWrites[id] = done;
        futures.add(done);
      }
    }
    return Future.wait(futures);
  }

  /// Returns the actual [File] in this environment corresponding to [id].
  ///
  /// The returned [File] may or may not already exist. Call [ensureAssets]
  /// with [id] to make sure it is actually present.
  File fileFor(AssetId id) =>
      new File(p.join(tempDir.path, _relativePathFor(id)));
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
