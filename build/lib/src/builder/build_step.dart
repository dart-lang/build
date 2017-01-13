// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import '../analyzer/resolver.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import 'build_step_impl.dart';

/// A single step in the build processes. This represents a single input and
/// it also handles tracking of dependencies.
abstract class BuildStep implements AssetReader, AssetWriter {
  /// The primary input id for this build step.
  AssetId get inputId;

  /// A [Logger] for this [BuildStep].
  Logger get logger;

  /// Checks if an [Asset] by [id] exists as an input for this [BuildStep].
  @override
  Future<bool> hasInput(AssetId id);

  @override
  Future<List<int>> readAsBytes(AssetId id);

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8});


  /// **NOTE**: Most `Builder` implementations should not need to `await` this
  /// Future since the runner will be responsible for waiting until all outputs
  /// are written.
  @override
  Future writeAsBytes(AssetId id, List<int> bytes);

  /// **NOTE**: Most `Builder` implementations should not need to `await` this
  /// Future since the runner will be responsible for waiting until all outputs
  /// are written.
  @override
  Future writeAsString(AssetId id, String contents, {Encoding encoding: UTF8});

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

abstract class ManagedBuildStep implements BuildStep {
  /// Mark the build step as finished and wait for any side effects to settle.
  Future complete();

  factory ManagedBuildStep(
      AssetId inputId,
      Iterable<AssetId> expectedOutputs,
      AssetReader reader,
      AssetWriter writer,
      String packageName,
      Resolvers resolvers,
      {Logger logger}) = BuildStepImpl;
}
