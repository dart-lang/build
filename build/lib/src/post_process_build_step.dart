// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../build.dart';

/// A simplified [BuildStep] which can only read its primary input, and can't
/// get a [Resolver] or any [Resource]s.
abstract class PostProcessBuildStep {
  AssetId get inputId;

  Future<Digest> digest(AssetId id);

  Future<List<int>> readInputAsBytes();

  Future<String> readInputAsString({Encoding encoding = utf8});

  Future<void> writeAsBytes(AssetId id, FutureOr<List<int>> bytes);

  Future<void> writeAsString(
    AssetId id,
    FutureOr<String> content, {
    Encoding encoding = utf8,
  });

  /// Marks an asset for deletion in the post process step.
  void deletePrimaryInput();

  /// Waits for work to finish and cleans up resources.
  ///
  /// This method should be called after a build has completed. After the
  /// returned [Future] completes then all outputs have been written.
  Future<void> complete();
}
