// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../asset/reader.dart';
import 'asset_finder.dart';
import 'asset_path_provider.dart';
import 'filesystem.dart';
import 'filesystem_cache.dart';
import 'input_tracker.dart';

/// Provides access to the state backing an [AssetReader].
extension AssetReaderStateExtension on AssetReader {
  /// Returns a new instance with optionally updated [cache].
  AssetReader copyWith({
    AssetPathProvider? assetPathProvider,
    FilesystemCache? cache,
  }) {
    _requireIsAssetReaderState();
    return (this as AssetReaderState).copyWith(
      assetPathProvider: assetPathProvider,
      cache: cache,
    );
  }

  Filesystem get filesystem {
    _requireIsAssetReaderState();
    return (this as AssetReaderState).filesystem;
  }

  FilesystemCache get cache {
    _requireIsAssetReaderState();
    return (this as AssetReaderState).cache;
  }

  AssetFinder get assetFinder {
    _requireIsAssetReaderState();
    return (this as AssetReaderState).assetFinder;
  }

  bool get handlesInputTracking {
    _requireIsAssetReaderState();
    return (this as AssetReaderState).handlesInputTracking;
  }

  InputTracker get inputTracker {
    _requireIsAssetReaderState();
    return (this as AssetReaderState).inputTracker;
  }

  AssetPathProvider get assetPathProvider {
    _requireIsAssetReaderState();
    return (this as AssetReaderState).assetPathProvider;
  }

  /// Throws if `this` is not an [AssetReaderState].
  void _requireIsAssetReaderState() {
    if (this is! AssetReaderState) {
      throw StateError(
        '`AssetReader` must implement `AssetReaderState`: $this',
      );
    }
  }
}

/// The state backing an [AssetReader].
abstract interface class AssetReaderState {
  /// Returns a new instance with optionally updated [assetPathProvider] and/or [cache].
  AssetReader copyWith({
    AssetPathProvider? assetPathProvider,
    FilesystemCache? cache,
  });

  /// The [Filesystem] that this reader reads from.
  ///
  /// Warning: this access to the filesystem bypasses reader functionality
  /// such as read tracking, caching and visibility restriction.
  Filesystem get filesystem;

  /// The [FilesystemCache] that this reader uses for caching.
  FilesystemCache get cache;

  /// The [AssetFinder] associated with this reader.
  ///
  /// All readers have an [AssetFinder], but the functionality it provides,
  /// globbing in arbitrary packages, is hidden from generators.
  AssetFinder get assetFinder;

  /// Whether this reader does input tracking.
  ///
  /// Readers that do not know the primary input ID of the current build step
  /// can't do tracking. If they delegate to another reader they return its
  /// `handlesInputTracking` value, or they return false.
  ///
  /// A reader that does know the primary input ID of the current build step
  /// must decide whether to do tracking. If it delegates to another reader
  /// that already does tracking, there is nothing more to do: it returns
  /// `true`. Otherwise, it does tracking: it notifes [inputTracker] of reads,
  /// and likewise returns `true`.
  ///
  /// So, of all the readers working together, exactly one reader does tracking:
  /// the one closest to the underlying filesystem that knows the primary input
  /// ID. This is the reader that has the most information about what the build
  /// actually intends to read.
  bool get handlesInputTracking;

  /// The [InputTracker] that this reader records reads to.
  ///
  /// See [handlesInputTracking].
  InputTracker get inputTracker;

  /// The [AssetPathProvider] associated with this reader.
  AssetPathProvider get assetPathProvider;
}
