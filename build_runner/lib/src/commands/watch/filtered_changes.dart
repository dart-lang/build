// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'asset_change.dart';

/// The result of filtering changes in `BuildSeries.filterChanges`.
///
/// `accepted` changes trigger a rebuild. `rejected` changes are changes to
/// files that do not affect any build outputs, but they can nevertheless be of
/// interest to consumers of the output source.
class FilteredChanges {
  /// Changes that trigger a rebuild.
  final List<AssetChange> accepted;

  /// Changes that do not trigger a rebuild.
  final List<AssetChange> rejected;

  FilteredChanges({required this.accepted, required this.rejected});

  bool get isEmpty => accepted.isEmpty && rejected.isEmpty;

  bool get isNotEmpty => !isEmpty;
}
