// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';

import '../../build_plan/build_packages.dart';
import '../../build_plan/placeholders.dart';
import 'build_step_id.dart';
import 'build_step_result.dart';
import 'glob_id.dart';
import 'glob_result.dart';
import 'post_process_build_step_id.dart';
import 'post_process_build_step_result.dart';
import 'serializers.dart';
import 'sources.dart';

part 'serialization.dart';

/// Build state that is updated during the build then serialized to allow a
/// follow-on incremental build.
///
/// - Sources and their digests; missing sources.
/// - Glob results.
/// - Post process build step results.
class BuildState {
  /// Sources and missing sources.
  final Sources _sources;

  /// All standard build step execution results by [AssetId] then phase number.
  final Map<AssetId, Map<int, BuildStepResult>> _buildStepResultsByPrimaryInput;

  /// Globs evaluated during the build.
  final Map<GlobId, GlobResult> _globResults;

  /// All post process build steps results by [AssetId] then action number.
  final Map<AssetId, Map<int, PostProcessBuildStepResult>>
  _postProcessResultsByInput;

  /// All post process build step outputs.
  final Set<AssetId> _postProcessOutputs;

  @visibleForTesting
  BuildState.empty()
    : _sources = Sources(),
      _postProcessResultsByInput = {},
      _postProcessOutputs = {},
      _buildStepResultsByPrimaryInput = {},
      _globResults = {};

  /// Creates from sources.
  factory BuildState.create({required Set<AssetId> sources}) {
    final result = BuildState.empty();
    result._sources.addAll(sources);
    return result;
  }

  // --  Predicates over IDs and iterables over IDs.

  /// Whether [id] is a placeholder.
  ///
  /// Placeholders are virtual files that exist in every package. They can't be
  /// read, but they can be matched as inputs. This allows builders to generate
  /// a fixed list of outputs for any package.
  bool isPlaceholder(AssetId id) => Placeholders.isPlaceholderPath(id.path);

  /// Files that are in [package] and match [glob].
  ///
  /// To match declared outputs as well as sources, pass `declaredOutputs`. The
  /// declared outputs that match might not exist yet if their build step hasn't
  /// run, or might never exist if it runs but decides not to output them.
  ///
  /// Does not match post process outputs.
  Iterable<AssetId> findFiles({
    required String package,
    required Iterable<AssetId> declaredOutputs,
    Glob? glob,
  }) => _sources.findFiles(package, declaredOutputs, glob: glob);

  /// Sources.
  ///
  /// Files that were on disk in all packages in the build when the build
  /// started, excluding any that were matched as prior `build_runner` outputs.
  Iterable<AssetId> get sources => _sources.sourceIds;

  /// Whether [id] is a source file.
  bool isSource(AssetId id) => _sources.isSource(id);

  /// Whether [id] is a source file that has never been read.
  ///
  /// That means it is not a primary input and has never been read by any
  /// builder as an additional input.
  bool isUnreadSource(AssetId id) => _sources.isUnreadSource(id);

  /// Whether [id] is a source file that was accessed but did not exist.
  bool isMissingSource(AssetId id) => _sources.isMissingSource(id);

  /// Missing sources.
  Set<AssetId> get missingSources => _sources.missingSources.toSet();

  /// Actual build step outputs.
  ///
  /// A subset of the declared outputs.
  Iterable<AssetId> get actualOutputs => _buildStepResultsByPrimaryInput.values
      .expand((map) => map.values.expand((result) => result.outputs.keys));

  /// Post process outputs.
  ///
  /// Note that post process outputs happen after the main build, so during the
  /// main build this is either empty or is the post process outputs from the
  /// previous build.
  Iterable<AssetId> get actualPostOutputs => _postProcessOutputs;

  /// Whether [id] is a post process build output that was actually generated.
  bool isActualPostOutput(AssetId id) => _postProcessOutputs.contains(id);

  // -- Digests.

  /// Updates a source file digest.
  ///
  /// Does nothing for generated files, their digest is set when the build step
  /// result is written.
  void updateSourceDigest(AssetId id, Digest? digest) {
    _sources.updateDigestIfPresent(id, digest);
  }

  /// The digest of source [id], or `null` if it has not been read.
  ///
  /// Throws if it is not a source.
  Digest? digestOfSource(AssetId id) => _sources.digestOfSource(id);

  // -- Missing sources.

  /// Adds a source that a builder tried to access but was missing.
  ///
  /// The builder must check and find there is no declared output or
  /// source before calling this.
  void addMissingSource(AssetId id) => _sources.addMissing(id);

  // -- Build steps.

  /// The result of [buildStep].
  BuildStepResult stepResult(BuildStepId buildStep) =>
      stepResultOrNull(buildStep)!;

  /// The result of [buildStep], or `null` if it is not a known step or there is
  /// no result yet.
  BuildStepResult? stepResultOrNull(BuildStepId buildStep) =>
      _buildStepResultsByPrimaryInput[buildStep.primaryInput]?[buildStep
          .phaseNumber];

  /// Whether the build state has a result for [buildStep].
  bool hasStepResult(BuildStepId buildStep) =>
      _buildStepResultsByPrimaryInput[buildStep.primaryInput]?.containsKey(
        buildStep.phaseNumber,
      ) ??
      false;

  /// Updates a build step result after the step runs.
  void updateBuildStepResult(BuildStepId buildStepId, BuildStepResult result) {
    _buildStepResultsByPrimaryInput.putIfAbsent(
          buildStepId.primaryInput,
          () => {},
        )[buildStepId.phaseNumber] =
        result;
  }

  // -- Globs.

  GlobResult? globResultFor(GlobId globId) => _globResults[globId];

  void updateGlobResult(GlobId globId, GlobResult result) {
    _globResults[globId] = result;
  }

  // -- Post process build steps.

  void addPostProcessBuildStepResult(
    PostProcessBuildStepId step,
    PostProcessBuildStepResult result,
  ) {
    final results = _postProcessResultsByInput.putIfAbsent(
      step.input,
      () => {},
    );
    if (results.containsKey(step.actionNumber)) {
      throw StateError('Already had post process result for $step.');
    }
    results[step.actionNumber] = result;
    _postProcessOutputs.addAll(result.outputs);
  }

  void removePostProcessBuildResult(PostProcessBuildStepId step) {
    final results = _postProcessResultsByInput[step.input];
    if (results == null) return;
    final oldResult = results.remove(step.actionNumber);
    if (oldResult != null) {
      _postProcessOutputs.removeAll(oldResult.outputs);
    }
    if (results.isEmpty) {
      _postProcessResultsByInput.remove(step.input);
    }
  }

  PostProcessBuildStepResult? postProcessBuildStepResultFor(
    PostProcessBuildStepId step,
  ) => _postProcessResultsByInput[step.input]?[step.actionNumber];

  /// Whether the build state has a result for [step].
  bool hasPostProcessResult(PostProcessBuildStepId step) =>
      _postProcessResultsByInput[step.input]?.containsKey(step.actionNumber) ??
      false;

  Iterable<PostProcessBuildStepId> get failedPostProcessSteps {
    final results = <PostProcessBuildStepId>[];
    for (final outer in _postProcessResultsByInput.entries) {
      final input = outer.key;
      for (final inner in outer.value.entries) {
        if (inner.value.errors.isNotEmpty) {
          results.add(
            PostProcessBuildStepId(input: input, actionNumber: inner.key),
          );
        }
      }
    }
    return results;
  }

  Set<AssetId> get assetsDeletedByPostProcess {
    final result = <AssetId>{};
    for (final outer in _postProcessResultsByInput.entries) {
      final input = outer.key;
      for (final inner in outer.value.values) {
        if (inner.deletedPrimaryInput) {
          result.add(input);
          break;
        }
      }
    }
    return result;
  }

  /// Returns outputs that were written to the source tree.
  Iterable<AssetId> outputsToDelete(BuildPackages buildPackages) {
    // Checks if `id` is in a known package. If so, returns it.
    //
    // If not, and a single package is being built, returns `id` moved to that
    // package. This allows old generated output to be deleted if the package
    // was renamed since the last build.
    //
    // If `id` is not in a known package and a single package is not being
    // built, returns `null`.
    AssetId? checkAndMoveId(AssetId id) {
      if (buildPackages[id.package] != null) {
        return id;
      }
      final singleOutputPackage = buildPackages.singleOutputPackage;
      if (singleOutputPackage == null) return null;
      return AssetId(singleOutputPackage, id.path);
    }

    final result = <AssetId>[];
    // Delete all the non-hidden outputs.
    for (final map in _buildStepResultsByPrimaryInput.values) {
      for (final stepResult in map.values) {
        if (!stepResult.isHidden) {
          for (final id in stepResult.outputs.keys) {
            final idToDelete = checkAndMoveId(id);
            if (idToDelete != null) result.add(idToDelete);
          }
        }
      }
    }
    for (final results in _postProcessResultsByInput.values) {
      for (final postProcessResults in results.values) {
        if (!postProcessResults.hidden) {
          for (final id in postProcessResults.outputs) {
            final idToDelete = checkAndMoveId(id);
            if (idToDelete != null) result.add(idToDelete);
          }
        }
      }
    }
    return result;
  }

  // -- Creation of the state and updates for incremental builds.

  // -- Testing.

  @visibleForTesting
  void addSourceForTest(AssetId id, {Digest? digest}) =>
      _sources.add(id, digest: digest);
}
