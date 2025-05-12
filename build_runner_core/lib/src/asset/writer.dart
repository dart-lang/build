// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

abstract class RunnerAssetWriter implements AssetWriter {
  /// Delete [id].
  Future<void> delete(AssetId id);

  /// Delete the directory [id] recursively.
  ///
  /// Usually an `AssetId` points to a file, but here its `path` is a directory.
  ///
  /// Delete unconditionally and recursively: if the directory does not exist,
  /// do nothing.
  Future<void> deleteDirectory(AssetId id);
}
