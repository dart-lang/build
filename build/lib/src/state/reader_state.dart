// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../asset/reader.dart';
import 'input_tracker.dart';

/// Provides access to the state backing an [AssetReader].
extension AssetReaderStateExtension on AssetReader {
  InputTracker? get inputTracker =>
      this is AssetReaderState ? (this as AssetReaderState).inputTracker : null;

  /// Gets [inputTracker] or throws a descriptive error if it is `null`.
  InputTracker get requireInputTracker {
    final result = inputTracker;
    if (result == null) {
      _requireIsAssetReaderState();
      throw StateError(
          '`AssetReader` is missing required `inputTracker`: $this');
    }
    return result;
  }

  /// Throws if `this` is not an [AssetReaderState].
  void _requireIsAssetReaderState() {
    if (this is! AssetReaderState) {
      throw StateError(
          '`AssetReader` must implement `AssetReaderState`: $this');
    }
  }
}

/// The state backing an [AssetReader].
abstract interface class AssetReaderState {
  /// The [InputTracker] that this reader records reads to; or `null` if it does
  /// not have one.
  InputTracker? get inputTracker;
}
