// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import '../package_graph/package_graph.dart';

/// Represents an [id] that was modified on disk as a result of [type].
class AssetChange {
  /// Asset that was changed.
  final AssetId id;

  /// What caused the asset to be detected as changed.
  final ChangeType type;

  const AssetChange(this.id, this.type);

  /// Creates a new change record in [package] from an existing watcher [event].
  factory AssetChange.fromEvent(PackageNode package, WatchEvent event) {
    return new AssetChange(
      new AssetId(
        package.name,
        _normalizeRelativePath(package, event),
      ),
      event.type,
    );
  }

  static String _normalizeRelativePath(PackageNode package, WatchEvent event) {
    final pkgPath = package.path;
    if (path.isAbsolute(event.path)) {
      if (!path.isWithin(pkgPath, event.path)) {
        throw new ArgumentError('"${event.path}" is not in "$pkgPath".');
      }
      return event.path.substring(pkgPath.length + 1);
    }
    return event.path;
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  bool operator ==(o) => o is AssetChange && o.id == id && o.type == type;

  @override
  String toString() => 'AssetChange {asset: $id, type: $type}';
}
