import 'dart:async';

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
import 'build_state/post_process_build_step_id.dart';
import 'build_state/post_process_build_step_result.dart';
import 'library_cycle_graph/phased_value.dart';

/// The filesystem from the point of view of a build step.
///
/// Restricts visibility based on build phase; triggers evaluation of earlier
/// phase build steps and of globs as needed.
class BuilderFilesystem {
  final BuildPackages buildPackages;
  final BuildConfigs buildConfigs;
  final BuildState buildState;
  final ReaderWriter readerWriter;
  final AssetBuilder assetBuilder;
  final GlobEvaluator globEvaluator;

  BuilderFilesystem({
    required this.buildPackages,
    required this.buildConfigs,
    required this.buildState,
    required this.readerWriter,
    required this.assetBuilder,
    required this.globEvaluator,
  });

  BuildStepPlan get buildStepPlan => buildState.buildStepPlan;

  void Function(AssetId, AssetContent?)? _onUpdateContent;

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

  /// Records the result and contents of [step] and notifies update listener.
  void addBuildStepResult({
    required BuildStepId step,
    required BuildStepResult result,
    Map<AssetId, AssetContent> contents = const {},
  }) {
    buildState.addBuildStepResult(
      step: step,
      result: result,
      contents: contents,
    );

    final declaredOutputsForStep = buildStepPlan.declaredOutputsByStep[step];
    for (final declaredOutput in declaredOutputsForStep) {
      _onUpdateContent?.call(declaredOutput, contents[declaredOutput]);
    }
  }

  /// Records the result and contents of [step] and notifies update listener.
  void addPostProcessBuildStepResult({
    required PostProcessBuildStepId step,
    required PostProcessBuildStepResult result,
    Map<AssetId, AssetContent> contents = const {},
  }) {
    buildState.addPostProcessBuildStepResult(
      step: step,
      result: result,
      contents: contents,
    );

    for (final entry in contents.entries) {
      _onUpdateContent?.call(entry.key, entry.value);
    }
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
    return buildState.isFile(id);
  }

  /// Returns the content of [id].
  ///
  /// It must be a known source or an output that has already been generated.
  ///
  /// If it's an unread source it will be read from the filesystem and stored in
  /// memory.
  Future<AssetContent> contentOf(AssetId id) async {
    final maybeResult = buildState.contentOf(id);
    if (maybeResult != null) return maybeResult;

    if (!buildState.isSource(id)) {
      throw StateError(
        'Cannot read $id, it is not a known source or generated output.',
      );
    }

    List<int> bytes;
    try {
      bytes = await readerWriter.readAsBytes(
        id,
        inArtifactTree: buildState.isInArtifactTree(id),
      );
    } on AssetNotFoundException {
      await ChildProcess.exitDueToAssetDeleted(id);
    }
    final content = AssetContent.bytes(bytes);
    buildState.updateSourceContent(id, content);
    _onUpdateContent?.call(id, content);
    return content;
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
        // Parallel outputs, or own outputs not caught earlier, are not
        // readable.
        return false;
      }

      // Build the asset if needed.
      await assetBuilder(id);

      return buildState.isActualSuccessfulOutput(id);
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

    globEvaluator(globId).then((_) {
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
        if (!buildState.isProcessedOutput(id)) {
          await assetBuilder(id);
        }
        final isSuccessOutput = buildState.isActualSuccessfulOutput(id);
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
            inArtifactTree: buildState.isInArtifactTree(id),
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
