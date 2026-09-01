// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';

import '../build/asset_content.dart';

/// The result of reading an asset from a `BuildOutputReader`.
class BuildOutputReadResult {
  final AssetId id;
  final UnreadableReason? unreadableReason;
  final AssetContent? _content;

  BuildOutputReadResult.unreadable(
    this.id,
    UnreadableReason this.unreadableReason,
  ) : _content = null;

  BuildOutputReadResult.available(this.id, AssetContent content)
    : unreadableReason = null,
      _content = content;

  /// Whether the asset can be read.
  bool get canRead => unreadableReason == null;

  /// The bytes of the asset.
  ///
  /// Throws [AssetNotFoundException] if [canRead] is false.
  List<int> get bytes {
    if (unreadableReason != null) {
      throw AssetNotFoundException(id);
    }
    return _content!.bytes;
  }

  /// Returns the digest of the asset.
  ///
  /// Throws [AssetNotFoundException] if [canRead] is false.
  Digest get digest {
    if (unreadableReason != null) {
      throw AssetNotFoundException(id);
    }
    return _content!.digest;
  }

  /// Returns the string contents of the asset.
  ///
  /// Throws [AssetNotFoundException] if [canRead] is false.
  String readAsString({Encoding encoding = utf8}) {
    if (unreadableReason != null) {
      throw AssetNotFoundException(id);
    }
    return _content!.stringValue(encoding: encoding);
  }
}

/// The reason an asset could not be read from a `BuildOutputReader`.
enum UnreadableReason { notFound, notOutput, deleted, failed }
