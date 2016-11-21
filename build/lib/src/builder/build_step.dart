// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import '../analyzer/resolver.dart';
import '../asset/asset.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import 'build_step_impl.dart';

/// A single step in the build processes. This represents a single input and
/// it also handles tracking of dependencies.
abstract class BuildStep {
  /// The primary input for this build step.
  Asset get input;

  /// A [Logger] for this [BuildStep].
  Logger get logger;

  /// Checks if an [Asset] by [id] exists as an input for this [BuildStep].
  Future<bool> hasInput(AssetId id);

  /// Reads an [Asset] by [id] as a [String] using [encoding].
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8});

  /// Outputs an [Asset] using the current [AssetWriter], and adds [asset] to
  /// [outputs].
  void writeAsString(Asset asset, {Encoding encoding: UTF8});

  /// Gives a [Resolver] for [id]. This must be released when it is done being
  /// used.
  ///
  /// If you pass a value of [false] for [resolveAllConstants], then constants
  /// will only be resolved in [id], and not any other libraries. This gives a
  /// significant speed boost, at the cost of not being able to assume all
  /// constants are already resolved.
  Future<Resolver> resolve(AssetId id,
      {bool resolveAllConstants, List<AssetId> entryPoints});
}

abstract class ManagedBuildStep extends BuildStep {
  /// Mark the build step as finished and wait for any side effects to settle.
  Future complete();

  factory ManagedBuildStep(
      Asset input,
      Iterable<AssetId> expectedOutputs,
      AssetReader reader,
      AssetWriter writer,
      String packageName,
      Resolvers resolvers, {Logger logger}) = BuildStepImpl;
}
