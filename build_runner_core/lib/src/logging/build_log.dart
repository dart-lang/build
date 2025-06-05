// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:build/build.dart'
    show AssetId, SyntaxErrorInAssetException, UnresolvableAssetException;
import 'package:logging/logging.dart';

import '../generate/phase.dart';
import 'ansi_buffer.dart';
import 'build_log_activities.dart';
import 'build_log_configuration.dart';
import 'build_log_logger.dart';
import 'build_log_messages.dart';
import 'build_log_stage.dart';
import 'log_display.dart';
import 'phase_progress.dart';

final BuildLog buildLog = BuildLog._();

enum BuildLogMode { simple, build, buildOfSeries, watch, daemon }

/// The `build_runner` log.
///
/// The `package:logging` APIs are used in three distinct ways.
///
/// First: builders can log info, warnings and errors, via the `log` top-level
/// variable in `package:build` that returns a `Logger`.
///
/// This `Logger` is scoped to the current builder:
///
///  - a severe log message marks the build step as failed
///  - prints by the builder are logged as warnings instead of printed
///  - exceptions thrown by the builder are logged as severe instead of printed
///
/// Second: the user-visible `build_runner` output passes through the root
/// `Logger` as log messages.
///
///  - info, warnings and errors from `build_runner` setup and cleanup are
///   logged as "info", "warning" or "severe", respectively
///  - log output from scoped builder loggers is passed through to the root
///   logger after prefixing it with the builder name and primary input
///
/// So, code calling `build_runner` as a library can access the log streams
/// using the `Logger` APIs; in some cases a log listener can be passed in.
///
/// Where a console with ANSI control codes is available, the `Logger`output is
/// _not_ displayed. Instead, no log listener is attached, and output is written
/// directly to the console taking advantage of the capability to overwrite
/// previous lines and the capability to write in color.
///
/// Configuration:
///
///  - By default, only builder logs of level `WARNING` and above are displayed.
///    The `verbose` flag will show all builder logs.
class BuildLog {
  static final String successPattern = 'succeeded';
  static final String failurePattern = 'failed';

  BuildLogConfiguration _configuration = BuildLogConfiguration();
  final BuildLogMessages _messages = BuildLogMessages();
  final BuildLogActivities _activities = BuildLogActivities();

  late final LogDisplay _display;
  final Stopwatch _stopwatch = Stopwatch()..start();
  // ignore: unused_field
  BuildLogMode _mode = BuildLogMode.simple;

  final Map<String, Stage> _stagesByName = {};
  Stage _currentStage = Stage.setup();

  final Map<InBuildPhase, PhaseProgress> _phaseProgress = {};
  InBuildPhase? _currentPhase;
  Duration _totalDuration = Duration.zero;
  List<String> _status = [];

  String loaded = '';

  bool? buildResult;
  int? outputs;
  BuildType buildType = BuildType.clean;

  BuildLogConfiguration get configuration => _configuration;
  set configuration(BuildLogConfiguration configuration) {
    _configuration = configuration;
    _display.onLog = _configuration.onLog;
  }

  /// Runs [function] with all output sent to [logger] instead of the default
  /// display.
  ///
  /// If [logger] is `null`, just runs [function].
  Future<T> runWithLoggerDisplay<T>(
    Logger? logger,
    Future<T> Function() function,
  ) async {
    final previousOnLog = configuration.onLog;
    if (logger != null) {
      _configuration = configuration.rebuild((b) {
        b.onLog =
            (record) => logger.log(
              record.level,
              record.message,
              record.error,
              record.stackTrace,
              record.zone,
            );
      });
    }
    try {
      return await function();
    } finally {
      if (logger != null) {
        configuration = configuration.rebuild((b) => b..onLog = previousOnLog);
      }
    }
  }

  /// Runs [function] adding the time spent to the measure of the specified
  /// [activity] of the currently-running [Stage].
  Future<T> runActivityAsync<T>(
    ActivityType activity,
    Future<T> Function() function,
  ) => _activities.runActivityAsync(
    phase: _currentPhase,
    activity: activity,
    function: function,
  );

  /// Runs [function] adding the time spent to the measure of the specified
  /// [activity] of the currently-running [Stage].
  T runActivity<T>(ActivityType activity, T Function() function) =>
      _activities.runActivity(
        phase: _currentPhase,
        activity: activity,
        function: function,
      );

  void reset() {
    _display.displayedLines = 0;
    _stopwatch.reset();
    _stopwatch.start();
    _stagesByName.clear();
    _currentStage = Stage.setup();
    buildResult = null;

    configuration = BuildLogConfiguration();
  }

  BuildLog._() {
    _display = LogDisplay();
  }

  void start(BuildLogMode mode) {
    _display.severeToStderr = mode == BuildLogMode.daemon;
    _mode = mode;

    if (mode == BuildLogMode.buildOfSeries) {
      _display.displayedLines = 0;
    }
  }

  BuildLogEntry makeEntry({
    required LineSeverity severity,
    required String line,
  }) {
    return BuildLogEntry(lines: render(), message: line, severity: severity);
  }

  List<String> _renderStage(Stage stage, {bool forLine = false}) {
    var name = stage.name;
    if (forLine && stage.note != null) {
      name = '$name ${stage.note}';
    }

    final progress = stage.progress;
    final length = stage.length;

    final time =
        stage.duration == null
            ? '    '
            : stage.duration!.inMilliseconds < 1000
            ? '<1s'.padLeft(4)
            : '${(stage.duration!.inMilliseconds / 1000).round()}s'.padLeft(4);

    //////////

    var attrs = <String>[];

    if (progress != null && length != 0 && progress != length) {
      var progressLine = '       $progress/$length';
      if (stage.note != null) progressLine += ' ${stage.note}';
      attrs.add(progressLine);
    }

    final entries = stage.attributions.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    for (final entry in entries) {
      if (entry.value.inMilliseconds < 1000) continue;
      final time = '${(entry.value.inMilliseconds / 1000).round()}s';

      attrs.add('       ${entry.key} $time');
    }

    return ['$time $name', ...attrs];
  }

  List<String> render() {
    final result = AnsiBuffer();

    final maxProgressWidth = _stagesByName.values
        //.where((value) => !value.isHidden)
        .map((value) => value.renderProgress.length)
        .followedBy([renderDuration(_totalDuration).length])
        .reduce(max);
    final indent = maxProgressWidth + 1;

    for (final entry in _phaseProgress.entries) {
      final phase = entry.key;
      final progress = entry.value;

      if (progress.isOptional) continue;

      final activities = _activities.render(phase: phase);

      var firstSeparator = true;
      String separator() {
        if (firstSeparator) {
          firstSeparator = false;
          return ': ';
        }
        return ', ';
      }

      result.writeLine([
        renderDuration(progress.duration).padLeft(maxProgressWidth),
        ' ',
        AnsiBuffer.bold,
        phase.builderLabel,
        AnsiBuffer.reset,
        if (progress.inputs != 0) ' on ${progress.inputs.renderNamed('input')}',
        if (progress.skipped != 0) '${separator()}${progress.skipped} skipped',
        if (progress.builtNew != 0) '${separator()}${progress.builtNew} output',
        if (progress.builtSame != 0) '${separator()}${progress.builtSame} same',
        if (progress.builtNothing != 0)
          '${separator()}${progress.builtNothing} no-op',
        if (progress.nextInput != null)
          '${separator()}${renderId(progress.nextInput!)}',
        if (activities.isNotEmpty) '; $activities',
      ], hangingIndent: indent);

      if (buildResult == null) {
        for (final line in _messages.renderInline(
          phase: phase,
          indent: indent,
        )) {
          result.write(line);
        }
      }
    }

    result.writeLine([]);
    result.writeLine([
      renderDuration(_totalDuration).padLeft(maxProgressWidth),
      ' ',
      ..._status,
    ]);

    if (buildResult != null) {
      /*final totalTime = renderDuration(
        _stagesByName.values
            .where((stage) => stage.length != 0)
            .map((stage) => stage.duration ?? Duration.zero)
            .reduce((a, b) => a + b),
      );

      result.writeLine([
        buildType.status,
        ' ',
        AnsiBuffer.bold,
        if (buildResult!) successPattern else failurePattern,
        AnsiBuffer.reset,
        ' in $totalTime.',
      ]);*/

      final renderedMessages = _messages.render([..._phaseProgress.keys, null]);
      if (renderedMessages.isNotEmpty) {
        result.writeLine([]);
        for (final line in renderedMessages) {
          result.write(line);
        }
      }
    }

    return result.lines;
  }

  void setBuildType(BuildType buildType) {
    this.buildType = buildType;
    _display.display(
      makeEntry(severity: LineSeverity.info, line: buildType.message),
    );
  }

  void info(
    String message, {
    InBuildPhase? phase,
    String? context,
    bool fromBuilder = false,
  }) {
    if (fromBuilder && !_configuration.verbose) return;
    _messages.add(
      phase: phase,
      context: context,
      severity: BuildLogSeverity.info,
      message,
    );
    _display.display(makeEntry(severity: LineSeverity.info, line: message));
  }

  void warning(String message, {InBuildPhase? phase, String? context}) {
    _messages.add(
      phase: phase,
      context: context,
      severity: BuildLogSeverity.info,
      message,
    );
    _display.display(makeEntry(severity: LineSeverity.warning, line: message));
  }

  void error(String message, {InBuildPhase? phase, String? context}) {
    _messages.add(
      phase: phase,
      context: context,
      severity: BuildLogSeverity.error,
      message,
    );
    _display.display(makeEntry(severity: LineSeverity.error, line: message));
  }

  @Deprecated('Only for printf debugging, do not submit.')
  void debug(String message) {
    stdout.writeln('BuildLog.debug:$message');
    _display.displayedLines = 0;
  }

  void startPhases(Map<InBuildPhase, List<AssetId>> primaryInputsByPhase) {
    _phaseProgress.clear();
    for (final entry in primaryInputsByPhase.entries) {
      final phase = entry.key;
      final primaryInputs = entry.value;
      _phaseProgress[phase] = PhaseProgress(inputs: primaryInputs.length);
    }
  }

  void builders(Map<String, int> buildSteps) {
    // print('declare: $names $buildSteps');
    for (final entry in buildSteps.entries) {
      final name = entry.key;
      final length = entry.value;
      _stagesByName[name] = Stage(name: name, length: length);
    }
    _stagesByName['build_runner cleanup'] = Stage.cleanup();
  }

  Stage stageNamed(String name) =>
      _stagesByName[name] ??= Stage(name: name, length: 0);

  void startStep(InBuildPhase phase, AssetId id) {
    _phaseProgress[phase]!.nextInput = id;
    tick(phase: phase);
  }

  void skipStep(InBuildPhase phase) {
    _phaseProgress[phase]!.skipped++;
  }

  void finishStep(
    InBuildPhase phase, {
    required bool anyOutputs,
    required bool anyChangedOutputs,
  }) {
    final progress = _phaseProgress[phase]!;
    progress.nextInput = null;
    if (anyChangedOutputs) {
      progress.builtNew++;
    } else if (anyOutputs) {
      progress.builtSame++;
    } else {
      progress.builtNothing++;
    }

    if (progress.isFinished) {
      tick(phase: null);
    }
  }

  void tick({InBuildPhase? phase}) {
    final duration = _stopwatch.elapsed;
    _stopwatch.reset();
    final previousPhase = _currentPhase;
    _currentPhase = phase;

    _totalDuration += duration;
    if (previousPhase != null) {
      _phaseProgress[previousPhase]!.duration += duration;
    }

    _display.display(
      makeEntry(
        severity: LineSeverity.info,
        line: _renderStage(_currentStage, forLine: true).first,
      ),
      // TODO: changed note?
      force: _currentPhase != previousPhase || buildResult != null,
    );
  }

  void doing(String task) {
    _status = ['build_runner ', task];
    tick(phase: null);
  }

  // TODO(davidmorgan): move reset to start.
  void buildDone({required bool result, required int outputs}) {
    buildResult = result;
    this.outputs = outputs;

    /*final conclusion = finalStatus;
    _display.display(
      makeEntry(severity: LineSeverity.info, line: '--- $conclusion'),
    );*/

    /*_display.finish();
    _stagesByName.clear();
    _stagesByName['setup'] = Stage.setup();*/
  }

  /// Creates a logger that logs to the [BuildLog] stage for [phase] on
  /// [input].
  BuildLogLogger loggerForPhase(InBuildPhase phase, AssetId input) =>
      BuildLogLogger(phase: phase, context: renderId(input));

  /// Creates a logger that logs to the [BuildLog] for work other than building
  /// described by [context].
  BuildLogLogger loggerForOther(String context) =>
      BuildLogLogger(context: context);

  String renderThrowable(
    Object? message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    var result = message?.toString() ?? '';
    if (error != null) result += '\n$error';

    // TODO drop frames.

    // Drop stack traces for exception types that can be caused by normal
    // user input; render stack traces for everything else as they can point to
    // bugs in generators or in build_runner.
    if (stackTrace != null &&
        error is! SyntaxErrorInAssetException &&
        error is! UnresolvableAssetException) {
      result += '\n$stackTrace';
    }
    return result;
  }

  String renderDuration(Duration duration) =>
      '${(duration.inMilliseconds / 1000).round()}s';

  /// Renders [id].
  ///
  /// Like `AssetId.toString`, except the package name is omitted if it matches
  /// [configuration] `rootPackageName`.
  String renderId(AssetId id) {
    if (id.package == configuration.rootPackageName) {
      return id.path;
    } else {
      return id.toString();
    }
  }
}

enum BuildType {
  clean('Clean build.', 'Full build'),
  incremental('Incremental build.', 'Incremental build'),
  incompatibleScript(
    'Builder code changed, doing a full build.',
    'Full build (builders changed)',
  ),
  incompatibleAssetGraph(
    'Could not load asset graph, doing a full build.',
    'Full build (no valid asset graph)',
  ),
  incompatibleBuild(
    'Build changed, doing a full build.',
    'Full build (target changed)',
  );

  const BuildType(this.message, this.status);

  final String message;
  final String status;
}

extension _IntExtension on int {
  String renderNamed(String name) => '$this $name${this == 1 ? '' : 's'}';
}
