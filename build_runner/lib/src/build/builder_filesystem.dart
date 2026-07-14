import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';

import 'package:glob/glob.dart';

import '../bootstrap/processes.dart';
import '../build_plan/build_configs.dart';
import '../build_plan/build_packages.dart';
import '../build_plan/build_step_plan.dart';
import '../build_plan/placeholders.dart';
import '../io/reader_writer.dart';
import 'asset_content.dart';
import 'build_state/build_state.dart';
import 'build_state/build_step_id.dart';
import 'build_state/build_step_result.dart';
import 'build_state/glob_id.dart';
import 'library_cycle_graph/phased_value.dart';
import 'resolver/asset_ids.dart';

/// The filesystem from the point of view of a build step.
///
/// Restricts visibility based on build phase; triggers evaluation of earlier
/// phase build steps and of globs as needed.
class BuilderFilesystem {
  final BuildPackages buildPackages;
  final BuildConfigs buildConfigs;
  final BuildState buildState;
  final BuildStepPlan buildStepPlan;
  final ReaderWriter readerWriter;
  final AssetBuilder? assetBuilder;
  final GlobEvaluator? globEvaluator;

  BuilderFilesystem({
    required this.buildPackages,
    required this.buildConfigs,
    required this.buildState,
    required this.buildStepPlan,
    required this.readerWriter,
    this.assetBuilder,
    this.globEvaluator,
  });

  /// Returns a copy without in-build hooks: [assetBuilder], [globEvaluator],
  /// content update listener.
  BuilderFilesystem forAfterBuild() => BuilderFilesystem(
    buildPackages: buildPackages,
    buildConfigs: buildConfigs,
    buildState: buildState,
    buildStepPlan: buildStepPlan,
    readerWriter: readerWriter,
  );

  void Function(AssetId, AssetContent?)? _onUpdateContent;
  void Function(AssetId, int, AssetContent?, AssetContent?)? _onUpdatePartContributions;

  /// Listens to content updates: source files read for the first time,
  /// generated outputs, generated outputs that are not written.
  ///
  /// Throws if called more than once.
  void listenToContentUpdates(
    void Function(AssetId, AssetContent?) onUpdateContent,
  ) {
    if (_onUpdateContent != null) {
      throw StateError('Already listening to content updates.');
    }
    _onUpdateContent = onUpdateContent;
  }

  /// Listens to part contributions.
  ///
  /// Throws if called more than once.
  void listenToPartContributions(
    void Function(AssetId, int, AssetContent?, AssetContent?) onUpdatePartContributions,
  ) {
    if (_onUpdatePartContributions != null) {
      throw StateError('Already listening to part contributions.');
    }
    _onUpdatePartContributions = onUpdatePartContributions;
  }

  /// Updates the content of [id] and notifies update listener.
  ///
  /// Throws if not a source.
  void updateSourceContent(AssetId id, AssetContent? content) {
    buildState.updateSourceContent(id, content);
    _onUpdateContent?.call(id, content);
  }

  /// Updates the result of [buildStepId] and notifies update listener.
  void updateBuildStepResult(BuildStepId buildStepId, BuildStepResult result) {
    buildState.updateBuildStepResult(buildStepId, result);

    for (final entry in result.outputs.entries) {
      _onUpdateContent?.call(entry.key, entry.value);
    }

    _onUpdatePartContributions?.call(
      buildStepId.primaryInput,
      buildStepId.phaseNumber,
      result.partImports,
      result.partContribution,
    );

    final declaredOutputsForStep =
        buildStepPlan.declaredOutputsByStep[buildStepId];
    for (final declaredOutput in declaredOutputsForStep) {
      if (!result.outputs.containsKey(declaredOutput)) {
        _onUpdateContent?.call(declaredOutput, null);
      }
    }
  }

  /// Updates [id] with [content].
  ///
  /// It must be a source, declared output or post process output.
  void updateContent({required AssetId id, required AssetContent content}) {
    if (buildState.isSource(id)) {
      updateSourceContent(id, content);
      return;
    }
    final step = buildStepPlan.stepForDeclaredOutputOrNull(id);
    if (step != null) {
      buildState.updateDeclaredOutputContent(
        step: step,
        id: id,
        content: content,
      );
      _onUpdateContent?.call(id, content);
      return;
    }
    final postProcessStep = buildState.postProcessStepFor(id);
    if (postProcessStep != null) {
      buildState.updatePostProcessOutputContent(
        step: postProcessStep,
        id: id,
        content: content,
      );
      _onUpdateContent?.call(id, content);
      return;
    }
    throw StateError('Cannot update content for unknown asset $id.');
  }

  void checkInvalidInput(AssetId id) {
    final package = buildPackages[id.package];
    if (package == null) {
      throw PackageNotFoundException(id.package);
    }

    // The id is an invalid input if it's not part of the build.
    if (!buildConfigs.isVisibleInBuild(id, package)) {
      final allowed = buildConfigs.validInputsFor(package);

      throw InvalidInputException(id, allowedGlobs: allowed);
    }
  }

  bool isFile(AssetId id) {
    return buildState.isFile(id: id, buildStepPlan: buildStepPlan);
  }

  /// Returns the content of [id].
  ///
  /// It must be a known source or output.
  ///
  /// If it hasn't yet been read it will be read from the filesystem and stored
  /// in memory.
  Future<AssetContent> contentOf(AssetId id) async {
    final maybeResult = buildState.contentOf(
      id: id,
      buildStepPlan: buildStepPlan,
    );
    if (maybeResult != null && maybeResult.hasContent) return maybeResult;

    if (!isFile(id)) {
      throw StateError('Cannot read $id, it is not a known source or output.');
    }

    List<int> bytes;
    try {
      bytes = await readerWriter.readAsBytes(
        id,
        hidden: id.isHidden(
          buildStepPlan: buildStepPlan,
          buildState: buildState,
        ),
      );
    } on AssetNotFoundException {
      await ChildProcess.exitDueToAssetDeleted(id);
    }
    final content = maybeResult != null
        ? maybeResult.withBytes(bytes)
        : AssetContent.bytes(bytes);
    updateContent(id: id, content: content);
    return content;
  }

  Future<String?> readOldPartFile(AssetId id) async {
    try {
      final bytes = await readerWriter.readAsBytes(
        id,
        hidden: id.isHidden(
          buildStepPlan: buildStepPlan,
          buildState: buildState,
        ),
      );
      return utf8.decode(bytes);
    } on AssetNotFoundException {
      return null;
    }
  }

  /// Checks whether [id] can be read by this step - attempting to build the
  /// asset if necessary.
  ///
  /// If [catchInvalidInputs] is set to true and [checkInvalidInput] throws an
  /// [InvalidInputException], this method will return `false` instead of
  /// throwing.
  Future<bool> isReadable(
    AssetId id,
    int phase, {
    bool catchInvalidInputs = false,
  }) async {
    try {
      checkInvalidInput(id);
    } on InvalidInputException {
      if (catchInvalidInputs) return false;
      rethrow;
    } on PackageNotFoundException {
      if (catchInvalidInputs) return false;
      rethrow;
    }

    if (Placeholders.isPlaceholderPath(id.path)) return false;
    if (!isFile(id)) {
      buildState.addMissingSource(id);
      return false;
    }

    return isReadableId(id, phase);
  }

  /// Checks whether [id] can be read by this step.
  ///
  /// If it's a declared output from an earlier phase, wait for it to be built.
  Future<bool> isReadableId(AssetId id, int phase) async {
    if (buildState.isActualPostOutput(id)) {
      // Post process outputs are not readable until after the build.
      return false;
    }
    if (buildStepPlan.isDeclaredOutput(id)) {
      final step = buildStepPlan.stepForDeclaredOutput(id);
      if (step.phaseNumber >= phase) {
        // Parallel outputs (or own outputs not caught earlier) are hidden.
        return false;
      }

      // If a build is running: build the asset if needed.
      await assetBuilder?.call(id);

      return buildState.isActualSuccessfulOutput(
        buildStepPlan: buildStepPlan,
        id: id,
      );
    }
    return buildState.isSource(id);
  }

  /// Returns all readable assets matching [glob] under [package].
  ///
  /// Throws if a build is not running.
  Stream<AssetId> findAssets(
    Glob glob, {
    required String package,
    required int phase,
    void Function(GlobId)? trackGlob,
  }) {
    final streamCompleter = StreamCompleter<AssetId>();
    final globId = GlobId(
      package: package,
      glob: glob.pattern,
      phaseNumber: phase,
    );

    globEvaluator!(globId).then((_) {
      if (trackGlob != null) trackGlob(globId);
      final globResult = buildState.globResultFor(globId)!;
      streamCompleter.setSourceStream(Stream.fromIterable(globResult.results));
    });
    return streamCompleter.stream;
  }

  /// Reads [id] at [phase] as a [PhasedValue].
  ///
  /// If the asset is missing, returns a [PhasedValue.fixed] with an empty
  /// string.
  ///
  /// If the asset is a source file, returns a [PhasedValue.fixed] with its
  /// content.
  ///
  /// If the asset is generated, but has not yet been generated at [phase],
  /// returns a [PhasedValue.unavailable] saying when it will be generated.
  ///
  /// If the asset is generated and _has_ already been generated, returns
  /// a [PhasedValue.generated] specifying both when it was generated and
  /// its content. Note that generation might output nothing, in which case an
  /// empty string is returned for its content.
  Future<PhasedValue<String>> readPhased(int phase, AssetId id) async {
    if (!isFile(id)) {
      buildState.addMissingSource(id);
      return PhasedValue.fixed('');
    } else if (buildState.isMissingSource(id)) {
      return PhasedValue.fixed('');
    }

    if (buildStepPlan.isDeclaredOutput(id)) {
      final step = buildStepPlan.stepForDeclaredOutput(id);
      final stepPhase = step.phaseNumber;
      if (stepPhase >= phase) {
        return PhasedValue.unavailable(before: '', expiresAfter: stepPhase);
      } else {
        if (!buildState.isProcessedOutput(
          buildStepPlan: buildStepPlan,
          id: id,
        )) {
          await assetBuilder?.call(id);
        }
        final isSuccessOutput = buildState.isActualSuccessfulOutput(
          buildStepPlan: buildStepPlan,
          id: id,
        );
        return PhasedValue.generated(
          atPhase: stepPhase,
          before: '',
          isSuccessOutput
              ? (await contentOf(id)).dartStringValueOrEmptyFail(id: id)
              : '',
        );
      }
    }

    return PhasedValue.fixed(
      await readerWriter.canRead(
            id,
            hidden: id.isHidden(
              buildStepPlan: buildStepPlan,
              buildState: buildState,
            ),
          )
          ? (await contentOf(id)).dartStringValueOrEmptyFail(id: id)
          : '',
    );
  }
}

/// Builds an asset.
typedef AssetBuilder = Future<void> Function(AssetId);

/// Evaluates all assets matching a glob.
typedef GlobEvaluator = Future<void> Function(GlobId);

extension AssetContentExtension on AssetContent {
  /// Returns [stringValue] based on utf8 encoding, or an empty string if
  /// decoding fails.
  ///
  /// Logs an error if decoding fails. Pass [id] for the log message.
  String dartStringValueOrEmptyFail({required AssetId id}) {
    try {
      return stringValue();
    } on FormatException {
      // Use the `package:build` log so it counts as a fail for the
      // currently-running builder.
      log.severe('Dart source $id is not valid utf8.');
      return '';
    }
  }
}
