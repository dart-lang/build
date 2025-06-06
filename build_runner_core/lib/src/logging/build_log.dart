// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:build/build.dart'
    show AssetId, SyntaxErrorInAssetException, UnresolvableAssetException;
// ignore: implementation_imports
import 'package:build_runner/src/internal.dart';
import 'package:logging/logging.dart';

import '../generate/phase.dart';
import 'ansi_buffer.dart';
import 'build_log_configuration.dart';
import 'build_log_logger.dart';
import 'build_log_messages.dart';
import 'log_display.dart';
import 'phase_progress.dart';
import 'timed_activities.dart';

/// The `build_runner` log.
///
/// For the main `build_runner` build the mode `BuildLogMode.build` is used,
/// which means that if a console is available then ANSI control codes will be
/// used for output. In this case the `Logger` output is _not_ displayed
/// directly. Instead, a more sophisticated display takes advantage of the
/// capability to overwrite previous lines and to control text formatting.
///
/// In `BuildLogMode.simple` and `BuildLogMode.daemon` the output is
/// always line by line log output.
///
/// The `package:logging` APIs are used in two distinct ways.
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
final BuildLog buildLog = BuildLog._();

class BuildLog {
  /// The log output signalling success, for tests.
  static final String successPattern = 'succeeded';

  /// The log output signalling failure, for tests.
  static final String failurePattern = 'failed';

  BuildLogConfiguration configuration = BuildLogConfiguration();
  final TimedActivities activities = TimedActivities();
  final BuildLogMessages _messages = BuildLogMessages();
  final Map<InBuildPhase, PhaseProgress> _phaseProgress = {};
  final LogDisplay _display = LogDisplay();

  Duration processDuration = Duration.zero;

  /// Stopwatch used to update [processDuration] every [_tick].
  final Stopwatch _stopwatch = Stopwatch()..start();

  /// Amount of time since a progress update.
  final Stopwatch _progressStopwatch = Stopwatch()..start();

  InBuildPhase? _currentPhase;
  List<String> _status = [];

  BuildLog._() {
    // Sync configuration between spawned isolates and the host.
    buildProcessState.doBeforeSend(() {
      buildProcessState.elapsedMillis = processDuration.inMilliseconds;
      buildProcessState.buildLogMode = configuration.mode;
    });
    void updateFromProcessState() {
      processDuration = Duration(milliseconds: buildProcessState.elapsedMillis);
      configuration = configuration.rebuild((b) {
        b.mode = buildProcessState.buildLogMode;
      });
    }

    updateFromProcessState();
    buildProcessState.doAfterReceive(updateFromProcessState);
  }

  InBuildPhase? get currentPhase => _currentPhase;

  /// Creates a logger that logs to the [BuildLog] stage for [phase] on
  /// [input].
  BuildLogLogger loggerForPhase(InBuildPhase phase, AssetId input) =>
      BuildLogLogger(phase: phase, context: renderId(input));

  /// Creates a logger that logs to the [BuildLog] for work other than building
  /// described by [context].
  BuildLogLogger loggerForOther(String context) =>
      BuildLogLogger(context: context);

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
      configuration = configuration.rebuild((b) {
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

  void fullBuildBecause(FullBuildReason reason) {
    buildProcessState.fullBuildReason = reason;
    _tick(phase: null);
    if (_display.displayingBlocks) {
      _display.block(_render());
    }
  }

  /// Logs a prompt that will be followed by an interactive question to the
  /// user.
  ///
  /// In console mode this prints a message and resets tracking of displayed
  /// lines, so the next display will not erase and rewrite over the prompt.
  void prompt(String message) {
    _display.prompt(message);
  }

  /// Logs a `build_runner` info.
  void info(String message) {
    if (_display.displayingBlocks) {
      _messages.add(severity: BuildLogSeverity.info, message);
      _display.block(_render());
    } else {
      _display.message(BuildLogSeverity.info, message);
    }
  }

  /// Logs a `build_runner` warning.
  void warning(String message) {
    if (_display.displayingBlocks) {
      _messages.add(severity: BuildLogSeverity.warning, message);
      _display.block(_render());
    } else {
      _display.message(BuildLogSeverity.warning, message);
    }
  }

  /// Logs an `build_runner` error.
  void error(String message) {
    if (_display.displayingBlocks) {
      _messages.add(severity: BuildLogSeverity.error, message);
      _display.block(_render());
    } else {
      _display.message(BuildLogSeverity.error, message);
    }
  }

  void fromBuildLogLogger(
    String message, {
    required BuildLogSeverity severity,
    InBuildPhase? phase,
    String? context,
  }) {
    if (_display.displayingBlocks) {
      _messages.add(
        severity: severity,
        phase: phase,
        context: context,
        message,
      );
      _display.block(_render());
    } else {
      _display.message(
        severity,
        [
          if (phase != null) phase.builderLabel,
          if (phase != null && context != null) 'on $context:',
          message,
        ].join(' '),
      );
    }
  }

  @Deprecated('Only for printf debugging, do not submit.')
  void debug(String message) {
    _display.prompt('BuildLog.debug:$message');
  }

  void startPhases(Map<InBuildPhase, List<AssetId>> primaryInputsByPhase) {
    _phaseProgress.clear();
    for (final entry in primaryInputsByPhase.entries) {
      final phase = entry.key;
      final primaryInputs = entry.value;
      _phaseProgress[phase] = PhaseProgress(inputs: primaryInputs.length);
    }
  }

  void startStep(InBuildPhase phase, AssetId id) {
    final progress = _phaseProgress[phase]!;
    progress.nextInput = id;
    _tick(phase: phase);
    if (progress.isStarting || _shouldShowProgressNow) {
      if (_display.displayingBlocks) {
        _display.block(_render());
      } else {
        _display.message(BuildLogSeverity.info, _renderPhase(phase).join(''));
      }
    }
  }

  void skipStep(InBuildPhase phase) {
    _phaseProgress[phase]!.skipped++;
    _tick(phase: phase);
    if (_shouldShowProgressNow) {
      if (_display.displayingBlocks) {
        _display.block(_render());
      } else {
        _display.message(BuildLogSeverity.info, _renderPhase(phase).join(''));
      }
    }
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

    // Usually the next step will update the display; but if this is the last
    // one, display it.
    if (progress.isFinished) {
      _tick(phase: null);
      if (_display.displayingBlocks) {
        _display.block(_render());
      } else {
        _display.message(BuildLogSeverity.info, _renderPhase(phase).join(''));
      }
    }
  }

  /// Describe what `build_runner` is doing.
  ///
  /// Logs the task, or in console mode updates the status line.
  void doing(String task) {
    if (_display.displayingBlocks) {
      _status = [task];
      _tick(phase: null);
      _display.block(_render());
    } else {
      _display.message(BuildLogSeverity.info, task);
    }
  }

  void startBuild() {
    doing('Building, ${buildProcessState.fullBuildReason.message}.');
  }

  void finishBuild({required bool result, required int outputs}) {
    _tick(phase: null);
    final displayingBlocks = _display.displayingBlocks;
    _status = [
      buildProcessState.fullBuildReason == FullBuildReason.none
          ? 'Incremental build '
          : 'Full build ',
      if (displayingBlocks) AnsiBuffer.bold,
      if (displayingBlocks) result ? AnsiBuffer.green : AnsiBuffer.red,
      result ? successPattern : failurePattern,
      if (displayingBlocks) AnsiBuffer.reset,
      ' in ',
      renderDuration(processDuration),
      if (_messages.hasWarnings) ' with warnings',
      '.',
    ];

    if (displayingBlocks) {
      _display.block(_render(finished: true));
      _display.flush();
    } else {
      _display.message(BuildLogSeverity.info, _status.join(''));
    }
  }

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

  /// Updates timers and [_currentPhase].
  ///
  /// The time since the previous tick is attributed to the previous [phase].
  /// And, [processDuration] is updated.
  void _tick({InBuildPhase? phase}) {
    final duration = _stopwatch.elapsed;
    _stopwatch.reset();
    final previousPhase = _currentPhase;
    _currentPhase = phase;

    processDuration += duration;
    if (previousPhase != null) {
      _phaseProgress[previousPhase]!.duration += duration;
    }
  }

  List<String> _render({bool finished = false}) {
    final result = AnsiBuffer();

    final displayedProgressEntries = _phaseProgress.entries.where(
      (e) => !e.key.isOptional || _messages.hasMessages(phase: e.key),
    );
    final maxProgressWidth = displayedProgressEntries
        .map((entry) => renderDuration(entry.value.duration).length)
        .fold(0, max);
    final indent = maxProgressWidth + 1;

    for (final entry in displayedProgressEntries) {
      final phase = entry.key;
      final progress = entry.value;

      if (progress.isOptional) continue;

      result.writeLine(_renderPhase(phase), hangingIndent: indent);

      if (!finished) {
        for (final line in _messages.renderInline(
          phase: phase,
          indent: indent,
        )) {
          result.write(line);
        }
      }
    }

    if (displayedProgressEntries.isNotEmpty) {
      result.writeLine([]);
    }
    result.writeLine(_status);

    if (!finished) {
      for (final line in _messages.renderInline(phase: null, indent: indent)) {
        result.write(line);
      }
    }

    if (finished) {
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

  List<String> _renderPhase(InBuildPhase phase, {int maxProgressWidth = 0}) {
    final activities = this.activities.render(phase: phase);

    var firstSeparator = true;
    String separator() {
      if (firstSeparator) {
        firstSeparator = false;
        return ': ';
      }
      return ', ';
    }

    final useAnsi = _display.displayingBlocks;
    final progress = _phaseProgress[phase]!;
    return [
      renderDuration(progress.duration).padLeft(maxProgressWidth),
      ' ',
      if (useAnsi) AnsiBuffer.bold,
      phase.builderLabel,
      if (useAnsi) AnsiBuffer.reset,
      if (progress.inputs != 0) ' on ${progress.inputs.renderNamed('input')}',
      if (progress.skipped != 0) '${separator()}${progress.skipped} skipped',
      if (progress.builtNew != 0) '${separator()}${progress.builtNew} output',
      if (progress.builtSame != 0) '${separator()}${progress.builtSame} same',
      if (progress.builtNothing != 0)
        '${separator()}${progress.builtNothing} no-op',
      if (progress.nextInput != null)
        '${separator()}${renderId(progress.nextInput!)}',
      if (activities.isNotEmpty) '; spent $activities',
    ];
  }

  bool get _shouldShowProgressNow {
    final interval =
        configuration.mode == BuildLogMode.build && _display.displayingBlocks
            ? const Duration(milliseconds: 100)
            : const Duration(seconds: 1);
    if (_progressStopwatch.elapsed >= interval) {
      _progressStopwatch.reset();
      return true;
    }
    return false;
  }
}

extension _IntExtension on int {
  String renderNamed(String name) => '$this $name${this == 1 ? '' : 's'}';
}
