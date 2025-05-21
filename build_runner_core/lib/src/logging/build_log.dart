// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart'
    show AssetId, SyntaxErrorInAssetException, UnresolvableAssetException;
import 'package:logging/logging.dart';

import 'build_log_logger.dart';
import 'log_display.dart';

BuildLog? _instance;

enum BuildLogMode { simple, build, watch, daemon }

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
class BuildLog {
  late final LogDisplay _display;
  final Stopwatch _stopwatch = Stopwatch()..start();
  // ignore: unused_field
  BuildLogMode _mode = BuildLogMode.simple;

  final Map<String, Stage> _stagesByName = {};
  Stage _currentStage = Stage.setup();

  String loaded = '';

  Duration _attributedDuration = Duration.zero;

  bool again = false;

  bool? result;

  factory BuildLog() => _instance ??= BuildLog._();

  BuildLog._() {
    _display = LogDisplay();
    _stagesByName['setup'] = Stage.setup();
    progress(Progress.setup);
  }

  factory BuildLog.forTesting() = BuildLog._;

  void configure({
    BuildLogMode? mode,
    bool? assumeTty,
    bool? verbose,
    Level? logLevel,
    void Function(LogRecord record)? onLog,
  }) {
    if (mode != null) _mode = mode;
    if (onLog != null) _display.onLog = onLog;
    // TODO
  }

  void clearOnLog() {
    _display.onLog = null;
    // TODO
  }

  String loggerState() {
    _display.close();
    var lines = _display.displayedLines;
    if (again) lines += 2;
    again = true;
    return '$lines,${_stagesByName['setup']!.duration?.inMilliseconds}';
  }

  void oldLoggerState(String state) {
    loaded = state;
    try {
      final items = state.split(',');
      _display.displayedLines = int.parse(items[0]);
      _stagesByName['setup']!.duration =
          items[1] == 'null'
              ? null
              : Duration(milliseconds: int.parse(items[1]));
    } catch (_) {}
    //
  }

  BuildLogEntry makeEntry({
    required LineSeverity severity,
    required String line,
  }) {
    return BuildLogEntry(lines: render(), line: line, severity: severity);
  }

  String _renderStage(Stage stage) {
    final name = stage.name;
    final progress = stage.progress;
    final length = stage.length;

    final time =
        stage.duration == null
            ? '    '
            : stage.duration!.inMilliseconds < 1000
            ? '<1s'.padLeft(4)
            : '${(stage.duration!.inMilliseconds / 1000).round()}s'.padLeft(4);

    /*final time = (((step.stopwatch.elapsed.inMilliseconds / 100) / 10)
                  .round()
                  .toString() +
              's')
          .padLeft(4);*/

    /*var ticks = 80 * number ~/ of;
      ticks = max(0, ticks - displayName.length - 1);
      var spaces = max(0, 80 - ticks - displayName.length - 1 - time.length);
      // buffer.writeln('$displayName ${'.' * ticks}${' ' * spaces}$time');*/

    /*var percent =
          number == 0 ? '    ' : '${100 * number ~/ of}'.padLeft(3) + '%';*/

    var percent =
        (progress == null || length == 0)
            ? ''
            : '${100 * progress ~/ length}'.padLeft(2);
    if (percent == '100' || percent == '') {
      percent = '';
    } else {
      percent = ', $percent%';
    }

    //displayName = displayName.padLeft(longestNameLength);

    var attrs = '';
    //if (name == step.name) {
    final buffer2 = StringBuffer();
    final entries = stage.attributions.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    for (final entry in entries) {
      if (entry.value.inMilliseconds < 1000) continue;
      buffer2.write(', ');
      final time = '${(entry.value.inMilliseconds / 1000).round()}s';

      buffer2.write('${entry.key} $time');
    }
    attrs = buffer2.toString();
    //buffer.writeln('     │      │ $buffer2'.padRight(80));
    //}

    return '$time $name$percent$attrs';
  }

  List<String> render() {
    final buildDone = result != null;

    final note = _currentStage.note == null ? '' : ' ${_currentStage.note}';

    final buffer = <String>[];

    void writeLine(String line) {
      buffer.add(line.padRight(80));
    }

    writeLine(' --- build_runner$note');

    for (final entry in _stagesByName.entries) {
      final stage = entry.value;
      final length = stage.length;

      if (length == 0 && !stage.hasLogOutput) {
        continue;
      }

      writeLine(_renderStage(stage));

      if (!buildDone) {
        if (stage.warnings.isNotEmpty) {
          final warnings = stage.warnings.values.fold(
            0,
            (count, list) => count + list.length,
          );
          final key = stage.warnings.keys.last;
          final value = stage.warnings[key]!.last;
          writeLine('       $warnings warning(s), latest: $key');
          writeLine('       $value');
        }

        if (stage.errors.isNotEmpty) {
          final errors = stage.errors.values.fold(
            0,
            (count, list) => count + list.length,
          );
          final key = stage.errors.keys.last;
          final value = stage.errors[key]!.last;
          writeLine('       $errors error(s), latest: $key');
          writeLine('       $value');
        }
      }
    }

    if (result != null) {
      for (final stage in _stagesByName.values) {
        if (stage.warnings.isNotEmpty) {
          for (final key in stage.warnings.keys) {
            writeLine(' === ${stage.name} on $key warnings');
            for (final value in stage.warnings[key]!) {
              writeLine('     $value');
            }
          }
        }
        if (stage.errors.isNotEmpty) {
          for (final key in stage.errors.keys) {
            writeLine(' === ${stage.name} on $key errors');
            for (final value in stage.errors[key]!) {
              writeLine('     $value');
            }
          }
        }
      }

      writeLine(' --- ${result! ? 'SUCCESS' : 'FAILURE'}');
    }

    return buffer;
  }

  // TODO(davidmorgan): document.
  Future<T> runAsyncWithLogger<T>(
    Logger? logger,
    Future<T> Function() function,
  ) async {
    // TODO(davidmorgan): output to the logger.
    return await function();
  }

  void fine(String message, {String? stage, String? note}) {
    _display.display(makeEntry(severity: LineSeverity.fine, line: message));
  }

  void info(String message, {String? stage, String? note}) {
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
    stderr.writeln(message);
  }

  int previous = 0;

  void builders(Map<String, int> buildSteps) {
    // print('declare: $names $buildSteps');
    for (final entry in buildSteps.entries) {
      final name = entry.key;
      final length = entry.value;
      _stagesByName[name] = Stage(name: name, length: length);
    }
    _stagesByName['cleanup'] = Stage.cleanup();
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
      line: _renderStage(_currentStage),
    );

    if (_currentStage != oldStage) {
      oldStage.progress = oldStage.length;
      oldStage.note = null;
    }

    if (_currentStage != oldStage || result != null) {
      _display.display(thisMakeEntry());
    } else {
      _display.maybeDisplay(thisMakeEntry);
    }
  }

  // TODO(davidmorgan): move reset to start.
  void buildDone(bool result) {
    this.result = result;
    final conclusion = result ? 'SUCCESS' : 'FAILURE';
    progress(Progress.done);
    _display.display(
      makeEntry(severity: LineSeverity.info, line: '--- $conclusion'),
    );

    /*_display.finish();
    _stagesByName.clear();
    _stagesByName['setup'] = Stage.setup();*/
  }

  Future<T> attributeAsync<T>(
    Attribution attribution,
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
      _currentStage.attributions[attribution] =
          (_currentStage.attributions[attribution] ?? Duration.zero) +
          thisAttributedDuration;
    }
  }

  T attribute<T>(Attribution attribution, T Function() function) {
    final start = _stopwatch.elapsed;
    final startAttributionDuration = _attributedDuration;
    try {
      return function();
    } finally {
      final end = _stopwatch.elapsed;
      final thisAttributedDuration =
          end - start - _attributedDuration + startAttributionDuration;
      _attributedDuration += thisAttributedDuration;
      _currentStage.attributions[attribution] =
          (_currentStage.attributions[attribution] ?? Duration.zero) +
          thisAttributedDuration;
    }
  }

  // TODO: "run scoped"
  BuildLogLogger loggerForBuilderFactory(String name) =>
      BuildLogLogger(stage: 'setup', note: name);

  BuildLogLogger loggerForSetup() => BuildLogLogger(stage: 'setup');

  BuildLogLogger loggerForStep(String stage, AssetId input) =>
      BuildLogLogger(stage: stage, note: input.toString());

  BuildLogLogger loggerForPostprocess(AssetId input) =>
      BuildLogLogger(stage: 'cleanup', note: input.toString());

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
}

class Progress {
  static final Progress setup = Progress('setup', 0);
  static final Progress generateBuildScript = Progress(
    'setup',
    1,
    'generate build script',
  );
  static final Progress compileBuildScript = Progress(
    'setup',
    2,
    'compile build script',
  );
  static final Progress readAssetGraph = Progress(
    'setup',
    3,
    'read asset graph',
  );
  static final Progress checkForUpdates = Progress(
    'setup',
    4,
    'check for updates',
  );
  static final Progress newAssetGraph = Progress(
    'setup',
    5,
    'create asset graph',
  );
  static final Progress initialBuildCleanup = Progress(
    'setup',
    6,
    'initial build cleanup',
  );
  static final Progress updateAssetGraph = Progress(
    'setup',
    7,
    'update asset graph',
  );

  static final Progress postbuild = Progress('cleanup', 0, 'postbuild');
  static final Progress writeAssetGraph = Progress(
    'cleanup',
    1,
    'write asset graph',
  );
  static final Progress writePerformance = Progress(
    'cleanup',
    2,
    'write performance log',
  );
  static final Progress writeOutputDirectory = Progress(
    'cleanup',
    3,
    'write output directory',
  );
  static final Progress done = Progress('cleanup', 4, null);

  final String stage;
  final int? number;
  final String? note;

  Progress(this.stage, this.number, [this.note]);

  Progress.build(String builder, this.note) : stage = builder, number = null;
}

class Stage {
  final String name;
  final int length;

  final Map<Attribution, Duration> attributions = {};
  Duration? duration;
  int? progress;
  String? note;

  Stage({required this.name, required this.length});
  factory Stage.setup() => Stage(name: 'setup', length: 8);
  factory Stage.cleanup() => Stage(name: 'cleanup', length: 4);

  final Map<String?, List<String>> warnings = {};
  final Map<String?, List<String>> errors = {};

  bool get hasLogOutput => warnings.isNotEmpty || errors.isNotEmpty;
}

extension type Attribution(String name) {
  static final Attribution analyze = Attribution._('analyze');
  static final Attribution build = Attribution._('build');
  static final Attribution track = Attribution._('track');
  static final Attribution resolve = Attribution._('resolve');
  static final Attribution read = Attribution._('read');
  static final Attribution write = Attribution._('write');

  Attribution.optionalBuilder(this.name);
  Attribution._(this.name);
}
