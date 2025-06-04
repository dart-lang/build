// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:build/build.dart'
    show SyntaxErrorInAssetException, UnresolvableAssetException;
import 'package:logging/logging.dart';

import 'ansi_buffer.dart';
import 'build_log_configuration.dart';
import 'build_log_logger.dart';
import 'build_log_stage.dart';
import 'log_display.dart';

final BuildLog buildLog = BuildLog._();

enum BuildLogMode { simple, build, buildOfSeries, watch, daemon }

/*    // Simple logs only in daemon mode. These get converted into info or
    // severe logs by the client.
    logListener = Logger.root.onRecord.listen((record) {
      if (record.level >= Level.SEVERE) {
        var buffer = StringBuffer(record.message);
        if (record.error != null) buffer.writeln(record.error);
        if (record.stackTrace != null) buffer.writeln(record.stackTrace);
        stderr.writeln(buffer);
      } else {
        stdout.writeln(record.message);
      }
    });*/

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
  static final String successPattern = 'success';
  static final String failurePattern = 'failure';

  BuildLogConfiguration _configuration = BuildLogConfiguration();

  late final LogDisplay _display;
  final Stopwatch _stopwatch = Stopwatch()..start();
  // ignore: unused_field
  BuildLogMode _mode = BuildLogMode.simple;

  final Map<String, Stage> _stagesByName = {};
  Stage _currentStage = Stage.setup();

  String loaded = '';

  Duration _attributedDuration = Duration.zero;

  bool again = false;

  bool? buildResult;
  int? outputs;
  BuildType buildType = BuildType.clean;
  int? assetGraphSize;

  BuildLogConfiguration get configuration => _configuration;
  set configuration(BuildLogConfiguration configuration) {
    _configuration = configuration;
    _display.onLog = _configuration.onLog;
  }

  void reset() {
    _display.displayedLines = 0;
    _stopwatch.reset();
    _stopwatch.start();
    _stagesByName.clear();
    _currentStage = Stage.setup();
    _attributedDuration = Duration.zero;
    again = false;
    buildResult = null;

    configuration = BuildLogConfiguration();
  }

  BuildLog._() {
    _display = LogDisplay();
  }

  void start(BuildLogMode mode) {
    _display.severeToStderr = mode == BuildLogMode.daemon;
    _mode = mode;

    if (mode == BuildLogMode.build) {
      _stagesByName['build_runner setup'] = Stage.setup();
      progress(Progress.setup);
    } else if (mode == BuildLogMode.buildOfSeries) {
      _display.displayedLines = 0;
      _stagesByName.clear();
      _stagesByName['build_runner setup'] = Stage.setup();
      progress(Progress.setup);
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
        .where((value) => !value.isHidden)
        .map((value) => value.maxProgressWidth)
        .fold(0, max);
    final indent = maxProgressWidth + 1;

    for (final entry in _stagesByName.entries) {
      final stage = entry.value;

      if (stage.isHidden) {
        continue;
      }

      final attributions = stage.renderAttributions;

      result.writeLine([
        stage.renderProgress.padLeft(maxProgressWidth),
        ' ',
        AnsiBuffer.bold,
        stage.name,
        AnsiBuffer.reset,
        if (stage.note != null) ', ${stage.note}',
        if (attributions.isNotEmpty) ', [$attributions]',
      ], hangingIndent: indent);

      if (buildResult == null) {
        if (_configuration.verbose && stage.infos.isNotEmpty) {
          final infos = stage.infos.values.fold(
            0,
            (count, list) => count + list.length,
          );
          final key = stage.infos.keys.last;
          final value = stage.infos[key]!.last;
          result.writeLine([
            'info',
            if (key != null) ', $key',
            if (infos > 1) ', +${infos - 1}',
          ], indent: indent);
          result.writeLine([value], indent: indent + 2);
        }

        if (stage.warnings.isNotEmpty) {
          final warnings = stage.warnings.values.fold(
            0,
            (count, list) => count + list.length,
          );
          final key = stage.warnings.keys.last;
          final value = stage.warnings[key]!.last;
          result.writeLine([
            'warning',
            if (key != null) ', $key',
            if (warnings > 1) ', +${warnings - 1}',
          ], indent: indent);
          result.writeLine([value], indent: indent + 2);
        }

        if (stage.errors.isNotEmpty) {
          final errors = stage.errors.values.fold(
            0,
            (count, list) => count + list.length,
          );
          final key = stage.errors.keys.last;
          final value = stage.errors[key]!.last;
          result.writeLine([
            'error',
            if (key != null) ', $key',
            if (errors > 1) ', +${errors - 1}',
          ], indent: indent);
          result.writeLine([value], indent: indent + 2);
        }
      }
    }

    result.writeLine(finalStatus, indent: indent);

    if (buildResult != null) {
      for (final stage in _stagesByName.values) {
        if (_configuration.verbose) {
          for (final stage in _stagesByName.values) {
            if (stage.infos.isNotEmpty) {
              for (final key in stage.warnings.keys) {
                for (final value in stage.infos[key]!) {
                  result.writeLine([
                    '${stage.name} info',
                    if (key != null) ' on $key',
                  ], indent: indent);
                  result.writeLine([value], indent: indent + 2);
                }
              }
            }
          }
        }
        if (stage.warnings.isNotEmpty) {
          for (final key in stage.warnings.keys) {
            for (final value in stage.warnings[key]!) {
              result.writeLine([
                '${stage.name} warning',
                if (key != null) ' on $key',
              ], indent: indent);
              result.writeLine([value], indent: indent + 2);
            }
          }
        }
        if (stage.errors.isNotEmpty) {
          for (final key in stage.errors.keys) {
            for (final value in stage.errors[key]!) {
              result.writeLine([
                '${stage.name} error',
                if (key != null) ' on $key',
              ], indent: indent);
              result.writeLine([value], indent: indent + 2);
            }
          }
        }
      }
    }

    return result.lines;
  }

  List<String> get finalStatus {
    final result = <String>[];
    if (buildResult == null) {
      result.addAll([AnsiBuffer.bold, 'running', AnsiBuffer.reset]);
    } else if (buildResult!) {
      result.addAll([
        AnsiBuffer.bold,
        AnsiBuffer.green,
        'success',
        AnsiBuffer.reset,
      ]);
    } else {
      result.addAll([
        AnsiBuffer.bold,
        AnsiBuffer.red,
        'failure',
        AnsiBuffer.reset,
      ]);
    }

    if (buildResult != null) {
      final totalTime = renderDuration(
        _stagesByName.values
            .where((stage) => stage.length != 0)
            .map((stage) => stage.duration ?? Duration.zero)
            .reduce((a, b) => a + b),
      );

      result.addAll([
        ', $buildType,'
            ' '
            'wrote $outputs file(s) in $totalTime,'
            ' '
            'asset graph is $assetGraphSize bytes',
      ]);
    }

    return result;
  }

  /// Runs [function] with [configuration] `onLog` forwarding to [logger].
  Future<T> runWithOutputToLogger<T>(
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

  void setBuildType(BuildType rebuildReason) {
    rebuildReason = rebuildReason;
    _display.display(
      makeEntry(severity: LineSeverity.info, line: rebuildReason.message),
    );
  }

  // TODO(davidmorgan): do we need this? How is it configured?
  void fine(String message, {String? stage, String? note}) {
    _display.display(makeEntry(severity: LineSeverity.fine, line: message));
  }

  void info(String message, {String? stage, String? note}) {
    ((_stagesByName[stage] ?? _currentStage).infos[note] ??= []).add(message);
    _display.display(makeEntry(severity: LineSeverity.info, line: message));
  }

  void warning(String message, {String? stage, String? note}) {
    ((_stagesByName[stage] ?? _currentStage).warnings[note] ??= []).add(
      message,
    );
    _display.display(makeEntry(severity: LineSeverity.warning, line: message));
  }

  void severe(String message, {String? stage, String? note}) {
    ((_stagesByName[stage] ?? _currentStage).errors[note] ??= []).add(message);
    _display.display(makeEntry(severity: LineSeverity.error, line: message));
  }

  @Deprecated('Only for printf debugging, do not submit.')
  void debug(String message) {
    stdout.writeln('BuildLog.debug:$message');
    _display.displayedLines = 0;
  }

  int previous = 0;

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

  void progress(Progress progress) {
    _currentStage.duration =
        (_currentStage.duration ?? Duration.zero) + _stopwatch.elapsed;
    _stopwatch.reset();

    final oldStage = _currentStage;
    if (progress.number != null) {
      _currentStage = stageNamed(progress.stage);
      _currentStage.progress = progress.number!;
    } else {
      _currentStage.progress = (_currentStage.progress ?? 0) + 1;
      _currentStage = stageNamed(progress.stage);
    }

    _currentStage.note = progress.note;
    _currentStage.duration ??= Duration.zero;
    _currentStage.progress ??= 0;

    BuildLogEntry thisMakeEntry() => makeEntry(
      severity: LineSeverity.info,
      line: _renderStage(_currentStage, forLine: true).first,
    );

    if (_currentStage != oldStage) {
      oldStage.progress = oldStage.length;
      oldStage.note = null;
    }

    _display.display(
      thisMakeEntry(),
      // TODO: changed note?
      force: _currentStage != oldStage || buildResult != null,
    );
  }

  // TODO(davidmorgan): move reset to start.
  void buildDone({
    required bool result,
    required int outputs,
    required int graphSize,
  }) {
    buildResult = result;
    this.outputs = outputs;
    assetGraphSize = graphSize;

    final conclusion = finalStatus;
    progress(Progress.done);
    _display.display(
      makeEntry(severity: LineSeverity.info, line: '--- $conclusion'),
    );

    /*_display.finish();
    _stagesByName.clear();
    _stagesByName['setup'] = Stage.setup();*/
  }

  /// Runs [function] adding the time spent to the measure of the specified
  /// [activity] of the currently-running [Stage].
  Future<T> runActivityAsync<T>(
    StageActivity activity,
    Future<T> Function() function,
  ) async {
    final start = _stopwatch.elapsed;
    final startAttributionDuration = _attributedDuration;
    try {
      return await function();
    } finally {
      final end = _stopwatch.elapsed;
      final thisAttributedDuration =
          end - start - _attributedDuration + startAttributionDuration;
      _attributedDuration += thisAttributedDuration;
      _currentStage.attributions[activity] =
          (_currentStage.attributions[activity] ?? Duration.zero) +
          thisAttributedDuration;
    }
  }

  /// Runs [function] adding the time spent to the measure of the specified
  /// [activity] of the currently-running [Stage].
  T runActivity<T>(StageActivity activity, T Function() function) {
    final start = _stopwatch.elapsed;
    final startAttributionDuration = _attributedDuration;
    try {
      return function();
    } finally {
      final end = _stopwatch.elapsed;
      final thisAttributedDuration =
          end - start - _attributedDuration + startAttributionDuration;
      _attributedDuration += thisAttributedDuration;
      _currentStage.attributions[activity] =
          (_currentStage.attributions[activity] ?? Duration.zero) +
          thisAttributedDuration;
    }
  }

  // TODO: "run scoped"
  BuildLogLogger loggerForBuilderFactory(String name) =>
      BuildLogLogger(stage: 'build_runner setup', note: name);

  BuildLogLogger loggerForSetup() =>
      BuildLogLogger(stage: 'build_runner setup');

  BuildLogLogger loggerForStep(String stage, String note) =>
      BuildLogLogger(stage: stage, note: note);

  BuildLogLogger loggerForPostprocess(String note) =>
      BuildLogLogger(stage: 'build_runner cleanup', note: note);

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

  String renderDuration(Duration duration) {
    if (duration == Duration.zero) return '0s';
    if (duration.inMilliseconds < 1000) return '<1s';
    return '${(duration.inMilliseconds / 1000).round()}s';
  }
}

class Progress {
  static final Progress setup = Progress('build_runner setup', 0);
  static final Progress generateBuildScript = Progress(
    'build_runner setup',
    1,
    'generate build script',
  );
  static final Progress compileBuildScript = Progress(
    'build_runner setup',
    2,
    'compile build script',
  );
  static final Progress readAssetGraph = Progress(
    'build_runner setup',
    3,
    'read asset graph',
  );
  static final Progress checkForUpdates = Progress(
    'build_runner setup',
    4,
    'check for updates',
  );
  static final Progress newAssetGraph = Progress(
    'build_runner setup',
    5,
    'create asset graph',
  );
  static final Progress initialBuildCleanup = Progress(
    'build_runner setup',
    6,
    'initial build cleanup',
  );
  static final Progress updateAssetGraph = Progress(
    'build_runner setup',
    7,
    'update asset graph',
  );

  static final Progress postbuild = Progress(
    'build_runner cleanup',
    0,
    'postbuild',
  );
  static final Progress writeAssetGraph = Progress(
    'build_runner cleanup',
    1,
    'write asset graph',
  );
  static final Progress writePerformance = Progress(
    'build_runner cleanup',
    2,
    'write performance log',
  );
  static final Progress writeOutputDirectory = Progress(
    'build_runner cleanup',
    3,
    'write output directory',
  );
  static final Progress done = Progress('build_runner cleanup', 4, null);

  final String stage;
  final int? number;
  final String? note;

  Progress(this.stage, this.number, [this.note]);

  Progress.build(String builder, this.note) : stage = builder, number = null;
}

enum BuildType {
  clean('Clean build.'),
  incremental('Incremental build.'),
  incompatibleScript('Builder code changed, doing a full build.'),
  incompatibleAssetGraph('Could not load asset graph, doing a full build.'),
  incompatibleBuild('Build changed, doing a full build.');

  const BuildType(this.message);

  final String message;
}
