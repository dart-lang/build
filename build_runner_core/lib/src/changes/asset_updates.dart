// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:watcher/watcher.dart';

import '../logging/log_renderer.dart';

/// Asset updates for an incremental build.
class AssetUpdates {
  final BuiltSet<AssetId> added;
  final BuiltSet<AssetId> modified;
  final BuiltSet<AssetId> removed;

  AssetUpdates({
    required this.added,
    required this.modified,
    required this.removed,
  });

  factory AssetUpdates.from(Map<AssetId, ChangeType> updates) {
    final added = <AssetId>[];
    final modified = <AssetId>[];
    final removed = <AssetId>[];
    for (final update in updates.entries) {
      switch (update.value) {
        case ChangeType.ADD:
          added.add(update.key);
          break;
        case ChangeType.MODIFY:
          modified.add(update.key);
          break;
        case ChangeType.REMOVE:
          removed.add(update.key);
          break;
      }
    }
    return AssetUpdates(
      added: (added..sort()).toBuiltSet(),
      modified: (modified..sort()).toBuiltSet(),
      removed: (removed..sort()).toBuiltSet(),
    );
  }

  bool get isEmpty => added.isEmpty && modified.isEmpty && removed.isEmpty;

  /// Explain what was updated, for logging.
  String render(LogRenderer renderer) {
    if (isEmpty) {
      return 'Updates: none.';
    }

    final result = <String>[];
    if (added.isNotEmpty) {
      result.add('added ${renderer.trimmedIds(added)}');
    }
    if (modified.isNotEmpty) {
      result.add('modified ${renderer.trimmedIds(modified)}');
    }
    if (removed.isNotEmpty) {
      result.add('removed ${renderer.trimmedIds(removed)}');
    }

    return 'Updates: ${result.join('; ')}.';
  }
}
