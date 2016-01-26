// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import '../asset/asset.dart';
import '../asset/id.dart';

/// A single step in the build processes. This represents a single input and
/// it also handles tracking of dependencies.
class BuildStep {
  /// The primary input for this build step.
  final Asset input;

  /// Reads an [Asset] by [id] as a [String] using [encoding].
  ///
  /// If [trackAsDependency] is true, then [id] will be marked as a dependency
  /// of all [expectedOutputs].
  Future<String> readAsString(AssetId id,
      {Encoding encoding: UTF8, bool trackAsDependency: true});

  /// Outputs an [Asset] using the current [AssetWriter], and adds [asset] to
  /// [outputs].
  void writeAsString(Asset asset, {Encoding encoding: UTF8});

  /// Explicitly adds [id] as a dependency of all [expectedOutputs]. This is
  /// not generally necessary unless forcing `trackAsDependency: false` when
  /// calling [readAsString].
  void addDependency(AssetId id);
}
