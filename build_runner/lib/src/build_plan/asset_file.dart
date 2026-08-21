// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

/// An asset with its physical location on disk: either in the source directory
/// or in the hidden cache directory.
class AssetFile {
  /// The logical asset identifier.
  final AssetId id;

  /// Whether the file is located in the hidden cache directory.
  final bool hidden;

  const AssetFile(this.id, {required this.hidden});

  /// An asset in the source directory.
  const AssetFile.source(this.id) : hidden = false;

  /// An asset in the hidden cache directory.
  const AssetFile.cache(this.id) : hidden = true;

  @override
  bool operator ==(Object other) =>
      other is AssetFile && other.id == id && other.hidden == hidden;

  @override
  int get hashCode => id.hashCode ^ hidden.hashCode;

  @override
  String toString() => hidden ? 'cache:$id' : 'source:$id';
}
