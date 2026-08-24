// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import '../build/asset_content.dart';
import '../build/build_state/finished_build_state.dart';
import '../build/build_state/sources.dart';
import '../build_plan/build_packages.dart';
import '../build_plan/build_step_plan.dart';
import 'reader_writer.dart';

/// A view of the build output.
///
/// If [canRead] returns false, [unreadableReason] explains why the file is
/// missing; for example, it might say that generation failed.
///
/// Files are only visible if they were a required part of the build, even if
/// they exist on disk from a previous build.
class BuildOutputReader {
  final BuildPackages buildPackages;
  final ReaderWriter readerWriter;
  final FinishedBuildState buildState;

  BuildStepPlan get buildStepPlan => buildState.buildStepPlan;

  late final Sources _sources = Sources({
    for (final s in buildState.sources) s: null,
  });

  /// Sources that were read or digested but only outside the build, for example
  /// by an asset server.
  ///
  /// Changes to these files trigger build notifications even when no build step
  /// consumes them as inputs.
  final Set<AssetId> _sourcesConsumedOutsideBuild = {};

  /// Sources that were read or digested through this reader but only outside
  /// the build.
  Set<AssetId> get sourcesConsumedOutsideBuild => _sourcesConsumedOutsideBuild;

  /// Whether [id] was read or digested through this reader but only outside
  /// the build.
  bool wasSourceConsumedOutsideBuild(AssetId id) =>
      _sourcesConsumedOutsideBuild.contains(id);

  BuildOutputReader({
    required this.buildPackages,
    required this.readerWriter,
    required this.buildState,
  });

  String pathFor(AssetId id) {
    return readerWriter.assetPathProvider.pathFor(
      id,
      hide: buildState.isHidden(id),
    );
  }

  /// Returns a reason why [id] is not readable, or null if it is readable.
  Future<UnreadableReason?> unreadableReason(AssetId id) async {
    if (buildState.assetsDeletedByPostProcess.contains(id)) {
      return UnreadableReason.deleted;
    }

    if (buildState.isActualPostOutput(id)) {
      return null;
    }
    final step = buildStepPlan.stepForDeclaredOutputOrNull(id);
    if (step != null) {
      final stepResult = buildState.stepResultOrNull(step);
      if (stepResult == null) {
        // The generated output was not considered for building because its
        // transitive inputs did not match build dirs and/or build filters.
        return UnreadableReason.notOutput;
      }
      if (stepResult.failed) {
        return UnreadableReason.failed;
      }
      if (!stepResult.outputs.containsKey(id)) {
        return UnreadableReason.notOutput;
      }

      // No need to explicitly check readability for generated files, their
      // readability is recorded in the build state.
      return null;
    }

    if (buildState.isSource(id) &&
        await readerWriter.canRead(id, hidden: buildState.isHidden(id))) {
      return null;
    }
    return UnreadableReason.notFound;
  }

  Future<bool> canRead(AssetId id) async =>
      (await unreadableReason(id)) == null;

  Future<Digest> digest(AssetId id) async {
    final unreadableReason = await this.unreadableReason(id);
    // Do provide digests for generated files that are known but not output
    // or known to be deleted. `build serve` uses these digests, which
    // reflect that the file is missing.
    if (unreadableReason != null &&
        unreadableReason != UnreadableReason.notOutput &&
        unreadableReason != UnreadableReason.deleted) {
      throw AssetNotFoundException(id);
    }
    final digest = await _ensureDigest(id);
    _recordSourceConsumedOutsideBuild(id);
    return digest;
  }

  Future<List<int>> readAsBytes(AssetId id) async {
    final cached = buildState.contentOf(id);
    if (cached != null && cached.hasContent) {
      _recordSourceConsumedOutsideBuild(id);
      return cached.bytes;
    }

    if (!buildState.isSource(id) &&
        !buildState.isActualOutput(id) &&
        !buildState.isActualPostOutput(id)) {
      throw AssetNotFoundException(id);
    }

    final bytes = await readerWriter.readAsBytes(
      id,
      hidden: buildState.isHidden(id),
    );
    _recordSourceConsumedOutsideBuild(id);
    return cached != null ? cached.withBytes(bytes).bytes : bytes;
  }

  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    final cached = buildState.contentOf(id);
    if (cached != null && cached.hasContent) {
      _recordSourceConsumedOutsideBuild(id);
      return cached.stringValue(encoding: encoding);
    }

    final bytes = await readAsBytes(id);
    return cached != null
        ? cached.withBytes(bytes).stringValue(encoding: encoding)
        : encoding.decode(bytes);
  }

  void _recordSourceConsumedOutsideBuild(AssetId id) {
    if (buildState.isSource(id) && buildState.contentOfSource(id) == null) {
      _sourcesConsumedOutsideBuild.add(id);
    }
  }

  Stream<AssetId> findAssets(Glob glob, {required String package}) async* {
    for (final id in _sources.findFiles(
      package,
      buildStepPlan.declaredOutputs,
      glob: glob,
    )) {
      if (await canRead(id)) {
        yield id;
      }
    }
  }

  /// Returns the digest of [id], computing it if necessary.
  ///
  /// Note that [id] must exist in the asset graph.
  FutureOr<Digest> _ensureDigest(AssetId id) async {
    final content = buildState.contentOf(id);
    if (content != null) return content.digest;
    final bytes = await readAsBytes(id);
    return AssetContent.bytes(bytes).digest;
  }

  /// A lazily computed view of all the assets available after a build.
  List<AssetId> allAssets({String? rootDir}) {
    final result = <AssetId>[];
    for (final id in buildState.sources) {
      if (!_shouldSkipId(id, rootDir)) {
        result.add(id);
      }
    }
    for (final id in buildStepPlan.declaredOutputs) {
      if (!_shouldSkipId(id, rootDir)) {
        result.add(id);
      }
    }
    for (final id in buildState.actualPostOutputs) {
      if (!_shouldSkipId(id, rootDir)) {
        result.add(id);
      }
    }
    return result;
  }

  bool _shouldSkipId(AssetId id, String? rootDir) {
    if (buildState.assetsDeletedByPostProcess.contains(id)) return true;

    // Exclude non-lib assets if they're outside of the root directory or not
    // an output package of the build.
    if (!id.path.startsWith('lib/')) {
      if (rootDir != null && !p.isWithin(rootDir, id.path)) return true;
      if (!buildPackages.outputPackages.contains(id.package)) {
        return true;
      }
    }

    if (buildState.isActualPostOutput(id)) {
      return false;
    }
    final step = buildStepPlan.stepForDeclaredOutputOrNull(id);
    if (step != null) {
      final stepResult = buildState.stepResultOrNull(step);
      if (stepResult == null ||
          stepResult.failed ||
          !stepResult.outputs.containsKey(id)) {
        return true;
      }
      return false;
    }
    if (id.path == '.packages') return true;
    if (id.path == '.dart_tool/package_config.json') return true;
    return false;
  }
}

enum UnreadableReason { notFound, notOutput, deleted, failed }
