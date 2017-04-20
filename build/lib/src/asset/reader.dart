// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:glob/glob.dart';

import 'id.dart';

/// Standard interface for reading an asset within in a package.
///
/// An [AssetReader] is required when calling the `runBuilder` method.
abstract class AssetReader {
  /// Returns a [Future] that completes with the bytes of a binary asset.
  ///
  /// * Throws a `PackageNotFoundException` if `id.package` is not found.
  /// * Throws a `AssetNotFoundException` if `id.path` is not found.
  Future<List<int>> readAsBytes(AssetId id);

  /// Returns a [Future] that completes with the contents of a text asset.
  ///
  /// When decoding as text uses [encoding], or [UTF8] is not specified.
  ///
  /// * Throws a `PackageNotFoundException` if `id.package` is not found.
  /// * Throws a `AssetNotFoundException` if `id.path` is not found.
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8});

  /// Indicates whether asset at [id] is readable.
  FutureOr<bool> canRead(AssetId id);

  /// Returns all readable assets matching [glob] under the root package.
  Iterable<AssetId> findAssets(Glob glob);
}
