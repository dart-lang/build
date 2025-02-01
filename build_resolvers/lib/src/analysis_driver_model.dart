// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/memory_file_system.dart';
// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:build/build.dart';

/// Manages analysis driver and related build state.
///
/// - Tracks the import graph of all sources needed for analysis.
/// - Given a set of entrypoints, adds them to known sources, optionally with
///   their transitive imports.
/// - Given a set of entrypoints, informs a `BuildStep` which inputs it now
///   depends on because of analysis.
/// - Maintains an in-memory filesystem that is the analyzer's view of the
///   build.
/// - Notifies the analyzer of changes to that in-memory filesystem.
abstract class AnalysisDriverModel {
  /// In-memory filesystem for the analyzer.
  abstract final MemoryResourceProvider resourceProvider;

  /// Notifies that [step] has completed.
  ///
  /// All build steps must complete before [reset] is called.
  void notifyComplete(BuildStep step);

  /// Clear cached information specific to an individual build.
  void reset();

  /// Attempts to parse [uri] into an [AssetId] and returns it if it is cached.
  ///
  /// Handles 'package:' or 'asset:' URIs, as well as 'file:' URIs of the form
  /// `/$packageName/$assetPath`.
  ///
  /// Returns null if the Uri cannot be parsed or is not cached.
  AssetId? lookupCachedAsset(Uri uri);

  /// Updates [resourceProvider] and the analysis driver given by
  /// `withDriverResource`  with updated versions of [entryPoints].
  ///
  /// If [transitive], then all the transitive imports from [entryPoints] are
  /// also updated.
  Future<void> performResolve(
      BuildStep buildStep,
      List<AssetId> entryPoints,
      Future<void> Function(
              FutureOr<void> Function(AnalysisDriverForPackageBuild))
          withDriverResource,
      {required bool transitive});
}
