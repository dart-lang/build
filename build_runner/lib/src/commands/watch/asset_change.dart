// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:watcher/watcher.dart';

import '../../asset_location.dart';
import '../../build_plan/build_package.dart';

/// Represents an asset [location] that was modified on disk as a result of
/// [type].
class AssetChange {
  /// Asset location that was changed.
  final AssetLocation location;

  /// Asset that was changed.
  AssetId get id => location.id;

  /// What caused the asset to be detected as changed.
  final ChangeType type;

  const AssetChange(this.location, this.type);

  /// Creates a new change record in [package] from an existing watcher [event].
  AssetChange.fromEvent(BuildPackage package, WatchEvent event)
    : this(AssetLocation.fromPath(package, event.path), event.type);

  @override
  int get hashCode => location.hashCode ^ type.hashCode;

  @override
  bool operator ==(Object other) =>
      other is AssetChange && other.location == location && other.type == type;

  @override
  String toString() => 'AssetChange {location: $location, type: $type}';
}
