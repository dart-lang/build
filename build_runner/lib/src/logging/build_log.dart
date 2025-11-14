// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:build/build.dart' show AssetId;
import 'package:built_collection/built_collection.dart';
import 'package:path/path.dart' as p;

import '../bootstrap/build_process_state.dart';
import '../build_plan/phase.dart';
import 'ansi_buffer.dart';
import 'build_log_configuration.dart';
import 'build_log_logger.dart';
import 'build_log_messages.dart';
import 'log_display.dart';
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
BuildLog get buildLog => _buildLog;

BuildLog _buildLog = BuildLog._();

class BuildLog {
  /// The log output signalling success, for tests.
  static final String successPattern = 'Built with build_runner';

  /// The log output signalling failure, for tests.
  static final String failurePattern = 'Failed to build with build_runner';

  /// The global, settable logging configuration.
  BuildLogConfiguration configuration = BuildLogConfiguration();

  /// Timings attributed to build phases.
  final TimedActivities activities = TimedActivities();

  /// The messages logged, bucketed by build phase.
  final BuildLogMessages _messages = BuildLogMessages();

  /// Errors logged.
  final ListBuilder<String> _errors = ListBuilder();

  /// JIT compile progress, if there was a JIT compile.
  _CompileProgress? _jitCompileProgress;

  /// AOT compile progress, if there was an AOT compile.
  _CompileProgress? _aotCompileProgress;

  /// Progress by build phase.
  final Map<String, _PhaseProgress> _phaseProgress = {};

  /// Progress by build phase.
  final LogDisplay _display = LogDisplay();

  /// The time the `build_runner` process has been running.
  Duration _processDuration = Duration.zero;

  /// Stopwatch used to update [_processDuration] every [_tick].
  final Stopwatch _stopwatch = Stopwatch()..start();

  /// Amount of time since a progress update.
  final Stopwatch _progressStopwatch = Stopwatch()..start();

  /// A stack of the currently running phases.
  final List<String> _runningPhases = [];

  /// During builds, the currently-displayed status line.
  List<String> _status = [];

  /// For `watch` and `serve` modes, the build number.
  int _buildNumber = 1;

  BuildLog._() {
    // Sync configuration between spawned isolates and the host.
    buildProcessState.doBeforeSend(() {
      buildProcessState.elapsedMillis = _processDuration.inMilliseconds;
      buildProcessState.buildLogMode = configuration.mode;
      buildProcessState.jitCompileProgress = _jitCompileProgress?.serialize();
      buildProcessState.aotCompileProgress = _aotCompileProgress?.serialize();
      buildProcessState.buildNumber = _buildNumber;
    });
    void updateFromProcessState() {
      _processDuration = Duration(
        milliseconds: buildProcessState.elapsedMillis,
      );
      configuration = configuration.rebuild((b) {
        b.mode = buildProcessState.buildLogMode;
      });
      _jitCompileProgress = _CompileProgress.deserialize(
        buildProcessState.jitCompileProgress,
      );
      _aotCompileProgress = _CompileProgress.deserialize(
        buildProcessState.aotCompileProgress,
      );
      _buildNumber = buildProcessState.buildNumber;
    }

    updateFromProcessState();
    buildProcessState.doAfterReceive(updateFromProcessState);
  }

  /// Creates a new build log and configures it for tests.
  ///
  /// Resets [buildProcessState].
  static void resetForTests({
    void Function(String)? printOnFailure,
    int? consoleWidth,
  }) {
    _buildLog = BuildLog._();
    buildLog.configuration = buildLog.configuration.rebuild((b) {
      b.printOnFailure = printOnFailure;
      b.forceConsoleWidthForTesting = consoleWidth;
    });
    buildProcessState.resetForTests();
  }

  /// The name of the currently-running build phase, or `null` if there isn't
  /// one.
  String? get currentPhaseName => _runningPhases.lastOrNull;

  /// Creates a logger that logs to the [BuildLog] stage for [phase] on
  /// [primaryInput].
  BuildLogLogger loggerFor({
    required InBuildPhase phase,
    required AssetId primaryInput,
    required bool lazy,
  }) => BuildLogLogger(
    phaseName: phase.name(lazy: lazy),
    context: renderId(primaryInput),
  );

  /// Creates a logger that logs to the [BuildLog] for work other than building
  /// described by [context].
  BuildLogLogger loggerForOther(String context) =>
      BuildLogLogger(context: context);

  /// Logs a `build_runner` info.
  void info(String message) {
    if (_display.displayingBlocks) {
      _messages.add(severity: Severity.info, message);
      _display.block(render());
    } else {
      _display.message(Severity.info, message);
    }
  }

  /// Logs a `build_runner` warning.
  void warning(String message) {
    if (_display.displayingBlocks) {
      _messages.add(severity: Severity.warning, message);
      _display.block(render());
    } else {
      _display.message(Severity.warning, message);
    }
  }

  /// Logs an `build_runner` error.
  void error(String message) {
    _errors.add(message);
    if (_display.displayingBlocks) {
      _messages.add(severity: Severity.error, message);
      _display.block(render());
    } else {
      _display.message(Severity.error, message);
    }
  }

  /// Logs a message from a [BuildLogLogger].
  void fromBuildLogLogger(
    String message, {
    required Severity severity,
    String? phaseName,
    String? context,
  }) {
    if (severity == Severity.error) _errors.add(message);
    if (_display.displayingBlocks) {
      _messages.add(
        severity: severity,
        phaseName: phaseName,
        context: context,
        message,
      );
      _display.block(render());
    } else {
      _display.message(
        severity,
        [
          if (phaseName != null) '$phaseName ',
          if (phaseName != null && context != null) 'on $context:',
          if (phaseName != null) '\n',
          message,
        ].join(''),
      );
    }
  }

  @Deprecated('Only for printf debugging, do not submit.')
  void debug(String message) {
    _display.flushAndPrint('BuildLog.debug:$message');
  }

  _PhaseProgress _getProgress({
    required InBuildPhase phase,
    required bool lazy,
  }) {
    return _phaseProgress.putIfAbsent(
      phase.name(lazy: lazy),
      _PhaseProgress.new,
    );
  }

  Future<T> logCompile<T>({
    required bool isAot,
    required Future<T> Function() function,
  }) async {
    final progress = _CompileProgress();
    if (isAot) {
      _aotCompileProgress = progress;
    } else {
      _jitCompileProgress = progress;
    }
    _compileTick(isAot: isAot, firstTick: true, lastTick: false);

    final timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _compileTick(isAot: isAot, firstTick: false, lastTick: false),
    );
    try {
      return await function();
    } finally {
      timer.cancel();
      _compileTick(isAot: isAot, firstTick: false, lastTick: true);
    }
  }

  void _compileTick({
    required bool isAot,
    required bool firstTick,
    required bool lastTick,
  }) {
    final duration = _stopwatch.elapsed;
    _stopwatch.reset();
    _processDuration += duration;

    if (!firstTick) {
      if (isAot) {
        _aotCompileProgress!.duration += duration;
      } else {
        _jitCompileProgress!.duration += duration;
      }
    }

    if (_shouldShowProgressNow || lastTick) {
      if (_display.displayingBlocks) {
        _display.block(render());
      } else {
        _display.message(
          Severity.info,
          _renderCompiling(isAot: isAot).toString(),
        );
      }
    }
  }

  /// Sets up logging of build phases with the number of primary inputs matching
  /// for each required phase.
  void startPhases(Map<InBuildPhase, int> primaryInputCountsByPhase) {
    _phaseProgress.clear();
    for (final entry in primaryInputCountsByPhase.entries) {
      final phase = entry.key;
      final primaryInputCount = entry.value;
      _getProgress(phase: phase, lazy: false).inputs += primaryInputCount;
    }
  }

  /// Logs that a build step is starting.
  void startStep({
    required InBuildPhase phase,
    required AssetId primaryInput,
    required bool lazy,
  }) {
    final phaseName = phase.name(lazy: lazy);
    final progress = _getProgress(phase: phase, lazy: lazy);
    progress.nextInput = primaryInput;
    _tick();
    _pushPhase(phaseName);
    // Always log if it's the first step in the phase, otherwise throttle.
    if (progress.isStarting || _shouldShowProgressNow) {
      if (_display.displayingBlocks) {
        _display.block(render());
      } else {
        _display.message(Severity.info, _renderPhase(phaseName).toString());
      }
    }
  }

  /// Logs that a build step was not triggered.
  void stepNotTriggered({required InBuildPhase phase, required bool lazy}) {
    final progress = _getProgress(phase: phase, lazy: lazy);
    progress.notTriggered++;
    progress.nextInput = null;
    final phaseName = phase.name(lazy: lazy);
    _tick();

    // Usually the next step will immediately run and update with more useful
    // information, so only display if this is the last for the builder.
    if (progress.isFinished) {
      if (_display.displayingBlocks) {
        _display.block(render());
      } else {
        _display.message(Severity.info, _renderPhase(phaseName).toString());
      }
    }

    _popPhase();
  }

  /// Logs that a build step has been skipped during an incremental build.
  void skipStep({required InBuildPhase phase, required bool lazy}) {
    final progress = _getProgress(phase: phase, lazy: lazy);
    progress.skipped++;
    progress.nextInput = null;
    final phaseName = phase.name(lazy: lazy);
    _tick();

    // Usually the next step will immediately run and update with more useful
    // information, so only display if this is the last for the builder.
    if (progress.isFinished) {
      if (_display.displayingBlocks) {
        _display.block(render());
      } else {
        _display.message(Severity.info, _renderPhase(phaseName).toString());
      }
    }

    _popPhase();
  }

  /// Logs that a build step has finished.
  void finishStep({
    required InBuildPhase phase,
    required bool lazy,
    required bool anyOutputs,
    required bool anyChangedOutputs,
  }) {
    final phaseName = phase.name(lazy: lazy);
    final progress = _getProgress(phase: phase, lazy: lazy);
    progress.nextInput = null;
    if (anyChangedOutputs) {
      progress.builtNew++;
    } else if (anyOutputs) {
      progress.builtSame++;
    } else {
      progress.builtNothing++;
    }

    _tick();

    // Usually the next step will immediately run and update with more useful
    // information, so only display if this is the last for the builder.
    if (progress.isFinished) {
      if (_display.displayingBlocks) {
        _display.block(render());
      } else {
        _display.message(Severity.info, _renderPhase(phaseName).toString());
      }
    }

    _popPhase();
  }

  /// For `watch` and `serve` modes, logs that a new build (not the initial
  /// build) has started.
  ///
  /// Clears timings and messages.
  void nextBuild({bool recompilingBuilders = false}) {
    _stopwatch.reset();
    _processDuration = Duration.zero;
    activities.clear();
    _messages.clear();
    _status.clear();
    _display.flushAndPrint(
      '\nStarting build #${++_buildNumber}'
      '${recompilingBuilders ? ' with updated builders' : ''}.\n',
    );
  }

  /// Logs that the build has finished with [result] and the count of [outputs].
  ///
  /// Returns the list of errors logged.
  BuiltList<String> finishBuild({required bool result, required int outputs}) {
    _tick();
    final displayingBlocks = _display.displayingBlocks;
    _status = [
      result ? successPattern : failurePattern,
      _isJit ? '/jit' : '/aot',
      ' in ',
      renderDuration(_processDuration),
      if (_messages.hasWarnings) ' with warnings',
      '; wrote ',
      outputs.renderNamed('output'),
      '.',
    ];

    if (displayingBlocks) {
      _display.block(render());
      _display.flush();
    } else {
      _display.message(
        Severity.info,
        // Removes ANSI codes if necessary.
        AnsiBufferLine(_status).toString(),
      );
    }

    _processDuration = Duration.zero;
    _jitCompileProgress = null;
    _aotCompileProgress = null;

    final errors = _errors.build();
    _errors.clear();
    return errors;
  }

  static bool get _isJit {
    final executable = p.basename(Platform.resolvedExecutable);
    return executable == 'dart' || executable == 'dart.exe';
  }

  /// Renders [message] with optional [error] and [stackTrace].
  ///
  /// Skips rendering [stackTrace] if [error] is an [Exception].
  String renderThrowable(
    Object? message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    var result = message?.toString() ?? '';
    if (error != null) {
      if (message != null) result += '\n';
      result += '$error';
    }

    if (stackTrace != null && error is! Exception) {
      result += '\n$stackTrace';
    }
    return result;
  }

  /// Renders [duration].
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

  /// Records time spent since the previous [_tick].
  void _tick() {
    final duration = _stopwatch.elapsed;
    _stopwatch.reset();
    _processDuration += duration;
    if (currentPhaseName != null) {
      _phaseProgress[currentPhaseName]!.duration += duration;
    }
  }

  void _pushPhase(String phaseName) {
    _runningPhases.add(phaseName);
  }

  void _popPhase() {
    _runningPhases.removeLast();
  }

  /// Renders the console display for the current log state.
  AnsiBuffer render() {
    final result = AnsiBuffer();

    if (_jitCompileProgress != null) {
      result.write(_renderCompiling(isAot: false));
    }
    if (_aotCompileProgress != null) {
      result.write(_renderCompiling(isAot: true));
    }

    final displayedProgressEntries = _phaseProgress.entries.where(
      (e) => e.value.isDisplayed || _messages.hasMessages(phaseName: e.key),
    );
    final maxProgressWidth = displayedProgressEntries
        .map((entry) => renderDuration(entry.value.duration).length)
        .fold(0, max);
    final indent = maxProgressWidth + 1;

    if (displayedProgressEntries.isNotEmpty) {
      for (final entry in displayedProgressEntries) {
        final phaseName = entry.key;

        result.write(_renderPhase(phaseName).withHangingIndent(indent));
      }
    }

    final renderedMessages = _messages.render();

    // Log output blocks with no errors show before the status line.
    if (renderedMessages.nonFailureLines.isNotEmpty) {
      if (result.lines.isNotEmpty) result.writeEmptyLine();
      for (final line in renderedMessages.nonFailureLines) {
        result.write(line);
      }
    }

    if (_status.isNotEmpty) {
      if (result.lines.isNotEmpty) result.writeEmptyLine();
      result.writeLine(_status);
    }

    // Log output blocks that do have errors show after the status line.
    if (renderedMessages.failureLines.isNotEmpty) {
      if (result.lines.isNotEmpty) result.writeEmptyLine();
      for (final line in renderedMessages.failureLines) {
        result.write(line);
      }
    }

    return result;
  }

  AnsiBufferLine _renderCompiling({required bool isAot}) {
    final progress = isAot ? _aotCompileProgress! : _jitCompileProgress!;
    return AnsiBufferLine([
      renderDuration(progress.duration),
      ' ',
      AnsiBuffer.bold,
      'compiling builders',
      AnsiBuffer.reset,
      '/${isAot ? 'aot' : 'jit'}',
    ]);
  }

  /// Renders a line describing the progress of [phaseName].
  AnsiBufferLine _renderPhase(String phaseName) {
    final activities = this.activities.render(phaseName: phaseName);

    var firstSeparator = true;
    String separator() {
      if (firstSeparator) {
        firstSeparator = false;
        return ': ';
      }
      return ', ';
    }

    final progress = _phaseProgress[phaseName]!;
    return AnsiBufferLine([
      renderDuration(progress.duration),
      ' ',
      AnsiBuffer.bold,
      phaseName,
      AnsiBuffer.reset,
      if (progress.inputs != 0) ' on ${progress.inputs.renderNamed('input')}',
      if (progress.skipped != 0) '${separator()}${progress.skipped} skipped',
      if (progress.notTriggered != 0)
        '${separator()}${progress.notTriggered} not triggered',
      if (progress.builtNew != 0) '${separator()}${progress.builtNew} output',
      if (progress.builtSame != 0) '${separator()}${progress.builtSame} same',
      if (progress.builtNothing != 0)
        '${separator()}${progress.builtNothing} no-op',
      if (activities.isNotEmpty) '; spent $activities',
      if (progress.nextInput != null) ...[
        '; ',
        AnsiBuffer.bold,
        renderId(progress.nextInput!),
        AnsiBuffer.reset,
      ],
    ]);
  }

  /// Whether progress should be displayed.
  ///
  /// In `BuildLogMode.build` progress is throttled to 10x per second,
  /// in other modes it's throttled to once per second.
  ///
  /// Important progress, such as the first step in a phase or the last step
  /// in a phase, does not check this; it's always logged.
  ///
  bool get _shouldShowProgressNow {
    if (!configuration.throttleProgressUpdates) return true;
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
  /// Renders a number with [name] and an "s" if the number is not 1.
  String renderNamed(String name) => '$this $name${this == 1 ? '' : 's'}';
}

extension _PhaseExtension on InBuildPhase {
  String name({required bool lazy}) =>
      lazy ? '$displayName (lazy)' : displayName;
}

/// Compile progress.
class _CompileProgress {
  Duration duration = Duration.zero;

  Object? serialize() => duration.inMilliseconds;

  static _CompileProgress? deserialize(Object? serialized) {
    if (serialized == null) return null;
    return _CompileProgress()
      ..duration = Duration(milliseconds: serialized as int);
  }
}

/// Progress metrics tracked for each build phase.
class _PhaseProgress {
  Duration duration = Duration.zero;

  /// The number of primary inputs built non-lazily by required phases.
  ///
  /// For optional phases, or for the lazy part of required phases, this is
  /// zero.
  int inputs = 0;

  /// Build steps that were skipped during incremental builds because the
  /// outputs are up to date.
  int skipped = 0;

  /// Build steps with `run_only_if_triggered` that were not triggered.
  int notTriggered = 0;

  /// Build steps that ran and output new or different output.
  int builtNew = 0;

  /// Build steps that ran but output the same output as they did previously.
  int builtSame = 0;

  /// Build steps that ran but output nothing.
  int builtNothing = 0;

  /// The next input that will run in this phase.
  AssetId? nextInput;

  _PhaseProgress();

  /// The number of build steps that have run in this phase.
  int get runCount =>
      skipped + notTriggered + builtNew + builtSame + builtNothing;

  /// Whether this progress in displayed.
  ///
  /// `inputs != 0` means it's the non-lazy part of a required phase, then
  /// `runCount != 0` covers lazy phases that actually ran.
  bool get isDisplayed => inputs != 0 || runCount != 0;

  /// Whether this progress will definitely run and is starting.
  ///
  /// `inputs != 0` means it's the non-lazy part of a required phase, then
  /// `runCount == 0` means it hasn't run yet.
  bool get isStarting => inputs != 0 && runCount == 0;

  /// Whether this progress is the non-lazy part of a required phase and
  /// has finished.
  bool get isFinished => inputs != 0 && inputs == runCount;
}
