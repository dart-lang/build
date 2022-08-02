// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Interface for a [MessageGrouper], which groups bytes in  delimited proto
/// format into the bytes for each message.
///
/// This interface should not generally be implemented directly, instead use
/// the [SyncMessageGrouper] or [AsyncMessageGrouper] implementations.
abstract class MessageGrouper {
  /// Returns either a [List<int>] or a [Future<List<int>>].
  dynamic get next;
}
