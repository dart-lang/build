// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import '../build/asset_content.dart';
import '../build/build_file_index.dart';
import '../build/build_state/finished_build_state.dart';
import '../build_plan/build_packages.dart';
import '../build_plan/build_step_plan.dart';
import 'build_output_read_result.dart';
import 'reader_writer.dart';

/// A view of the build inputs and output.
///
/// Build inputs that were used and all outputs are returned from memory.
///
/// Build inputs that were not used in the build are not in memory and are
/// returned directly from disk with no caching.
class BuildOutputReader {
  final BuildPackages buildPackages;
  final ReaderWriter readerWriter;
  final FinishedBuildState buildState;

  BuildStepPlan get buildStepPlan => buildState.buildStepPlan;

  late final BuildFileIndex _fileIndex = BuildFileIndex(
    buildState.sources.followedBy(buildStepPlan.declaredOutputs),
  );

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
      inArtifactTree: buildState.isInArtifactTree(id),
    );
  }

  /// Returns a reason why [id] is not readable, or null if it is readable.
  Future<UnreadableReason?> _unreadableReason(AssetId id) async {
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
      if (!stepResult.outputs.contains(id)) {
        return UnreadableReason.notOutput;
      }

      // No need to explicitly check readability for generated files, their
      // readability is recorded in the build state.
      return null;
    }

    if (buildState.isSource(id) &&
        await readerWriter.canRead(
          id,
          inArtifactTree: buildState.isInArtifactTree(id),
        )) {
      return null;
    }
    return UnreadableReason.notFound;
  }

  /// Reads [id] from the build output, returning a [BuildOutputReadResult].
  Future<BuildOutputReadResult> read(AssetId id) async {
    final reason = await _unreadableReason(id);
    if (reason != null) {
      return BuildOutputReadResult.unreadable(id, reason);
    }

    final cached = buildState.contentOf(id);
    if (cached != null) {
      _recordSourceConsumedOutsideBuild(id);
      return BuildOutputReadResult.available(id, cached);
    }

    final bytes = await readerWriter.readAsBytes(
      id,
      inArtifactTree: buildState.isInArtifactTree(id),
    );
    _recordSourceConsumedOutsideBuild(id);
    return BuildOutputReadResult.available(id, AssetContent.bytes(bytes));
  }

  Future<bool> canRead(AssetId id) async =>
      (await _unreadableReason(id)) == null;

  void _recordSourceConsumedOutsideBuild(AssetId id) {
    if (buildState.isSource(id) && buildState.contentOf(id) == null) {
      _sourcesConsumedOutsideBuild.add(id);
    }
  }

  Stream<AssetId> findAssets(Glob glob, {required String package}) async* {
    for (final id in _fileIndex.findFiles(package, glob: glob)) {
      if (await canRead(id)) {
        yield id;
      }
    }
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
          !stepResult.outputs.contains(id)) {
        return true;
      }
      return false;
    }
    if (id.path == '.packages') return true;
    if (id.path == '.dart_tool/package_config.json') return true;
    return false;
  }
}
