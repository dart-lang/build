// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart'
    show AssetId, SyntaxErrorInAssetException, UnresolvableAssetException;
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:logging/logging.dart';

import '../../build_runner_core.dart';
import 'ansi_buffer.dart';
import 'build_log_logger.dart';
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
  BuildType buildType = BuildType.clean;
  int? assetGraphSize;

  void reset() {
    _display.displayedLines = 0;
    _stopwatch.reset();
    _stopwatch.start();
    _stagesByName.clear();
    _currentStage = Stage.setup();
    _attributedDuration = Duration.zero;
    again = false;
    buildResult = null;
    assumeTty = false;
    verbose = false;
  }

  /// Runs [fn] in an error handling [Zone].
  ///
  /// Any calls to [print] will be logged with `log.warning`, and any errors
  /// will be logged with `log.severe`.
  ///
  /// Completes with the first error or result of `fn`, whichever comes first.
  /// TODO move to BuildLog.
  Future<T> scopeLogAsync<T>(Future<T> Function() fn, Logger log) {
    var done = Completer<T>();
    runZonedGuarded(
      fn,
      (e, st) {
        log.severe('', e, st);
        if (done.isCompleted) return;
        done.completeError(e, st);
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, message) {
          log.warning(message);
        },
      ),
      zoneValues: {logKey: log},
    )?.then((result) {
      if (done.isCompleted) return;
      done.complete(result);
    });
    return done.future;
  }

  /// Runs [fn] in an error handling [Zone].
  ///
  /// Any calls to [print] will be logged with `log.info`, and any errors will
  /// be logged with `log.severe`.
  T? scopeLogSync<T>(T Function() fn, Logger log) {
    return runZonedGuarded(
      fn,
      (e, st) {
        log.severe('', e, st);
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, message) {
          log.info(message);
        },
      ),
      zoneValues: {logKey: log},
    );
  }

  BuildLog._() {
    _display = LogDisplay();
  }

  set onLog(void Function(LogRecord)? onLog) {
    _display.onLog = onLog;
  }

  void Function(LogRecord)? get onLog => _display.onLog;

  bool assumeTty = false;
  bool verbose = false;

  void start(BuildLogMode mode) {
    _display.severeToStderr = mode == BuildLogMode.daemon;
    _mode = mode;

    if (mode == BuildLogMode.build) {
      _stagesByName['setup'] = Stage.setup();
      progress(Progress.setup);
    } else if (mode == BuildLogMode.buildOfSeries) {
      _display.displayedLines = 0;
      _stagesByName.clear();
      _stagesByName['setup'] = Stage.setup();
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

    for (final entry in _stagesByName.entries) {
      final stage = entry.value;

      if (stage.isHidden) {
        continue;
      }

      result.writeLine([
        AnsiBuffer.bold,
        stage.name,
        AnsiBuffer.reset,
        if (stage.note != null) ', ${stage.note}',
      ]);

      result.writeLine([stage.renderProgress], indent: 1);

      /*var first = true;
      for (final line in _renderStage(stage)) {
        result.writeLine([line], indent: first ? 5 : 7);
        first = false;
      }*/

      /*if (!buildDone) {
        if (verbose && stage.infos.isNotEmpty) {
          final infos = stage.infos.values.fold(
            0,
            (count, list) => count + list.length,
          );
          final key = stage.infos.keys.last;
          final value = stage.infos[key]!.last;
          result.writeLine(['       $infos info(s), latest: $key'], indent: 7);
          result.writeLine(['       $value'], indent: 7);
        }

        if (stage.warnings.isNotEmpty) {
          final warnings = stage.warnings.values.fold(
            0,
            (count, list) => count + list.length,
          );
          final key = stage.warnings.keys.last;
          final value = stage.warnings[key]!.last;
          result.writeLine([
            '       $warnings warning(s), latest: $key',
          ], indent: 7);
          result.writeLine(['       $value'], indent: 7);
        }

        if (stage.errors.isNotEmpty) {
          final errors = stage.errors.values.fold(
            0,
            (count, list) => count + list.length,
          );
          final key = stage.errors.keys.last;
          final value = stage.errors[key]!.last;
          result.writeLine([
            '       $errors error(s), latest: $key',
          ], indent: 7);
          result.writeLine(['       $value'], indent: 7);
        }
      }
    }

    if (buildResult != null) {
      for (final stage in _stagesByName.values) {
        if (verbose && stage.infos.isNotEmpty) {
          for (final key in stage.warnings.keys) {
            result.writeLine([' === ${stage.name} on $key infos']);
            for (final value in stage.infos[key]!) {
              result.writeLine(['     $value'], indent: 5);
            }
          }
        }
        if (stage.warnings.isNotEmpty) {
          for (final key in stage.warnings.keys) {
            result.writeLine([' === ${stage.name} on $key warnings']);
            for (final value in stage.warnings[key]!) {
              result.writeLine(['     $value'], indent: 5);
            }
          }
        }
        if (stage.errors.isNotEmpty) {
          for (final key in stage.errors.keys) {
            result.writeLine([' === ${stage.name} on $key errors']);
            for (final value in stage.errors[key]!) {
              result.writeLine(['     $value'], indent: 5);
            }
          }
        }
      }

      result.writeLine([
        ' --- ',
        AnsiBuffer.bold,
        finalStatus,
        AnsiBuffer.reset,
      ]);*/
    }

    result.writeLine(finalStatus);

    return result.lines;
  }

  List<String> get finalStatus {
    if (buildResult == null) {
      return [AnsiBuffer.bold, 'pending', AnsiBuffer.reset];
    }
    final buildResultString = buildResult! ? 'SUCCESS' : 'FAILURE';
    final totalTime = renderDuration(
      _stagesByName.values
          .where((stage) => stage.length != 0)
          .map((stage) => stage.duration ?? Duration.zero)
          .reduce((a, b) => a + b),
    );
    final filesOutput = '100';

    final graphSize = File(assetGraphPath).lengthSync();

    return [
      '$buildResultString, $buildType, '
          'built $filesOutput file(s) in $totalTime, '
          'asset graph is $graphSize bytes',
    ];
  }

  /// Runs [function] with [onLog] forwarding to [logger].
  Future<T> runWithOutputToLogger<T>(
    Logger? logger,
    Future<T> Function() function,
  ) async {
    final previousOnLog = onLog;
    if (logger != null) {
      onLog =
          (record) => logger.log(
            record.level,
            record.message,
            record.error,
            record.stackTrace,
            record.zone,
          );
    }
    try {
      return await function();
    } finally {
      if (logger != null) {
        onLog = previousOnLog;
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
  void buildDone(bool result) {
    buildResult = result;
    final conclusion = finalStatus;
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

  String renderDuration(Duration duration) {
    if (duration == Duration.zero) return '0s';
    if (duration.inMilliseconds < 1000) return '<1s';
    return '${(duration.inMilliseconds / 1000).round()}s';
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

  final Map<String?, List<String>> infos = {};
  final Map<String?, List<String>> warnings = {};
  final Map<String?, List<String>> errors = {};

  bool get isHidden => length == 0 && !hasLogOutput;

  bool get isInProgress => progress != null && progress! < length;

  String get renderProgress {
    final result = StringBuffer('${progress ?? 0} of $length');

    if (duration != null) {
      result.write(', ${buildLog.renderDuration(duration!)}');
    }

    final renderedAttributions = renderAttributions;
    if (renderedAttributions.isNotEmpty) {
      result.write(', [$renderedAttributions]');
    }

    return result.toString();
  }

  bool get hasLogOutput =>
      warnings.isNotEmpty ||
      errors.isNotEmpty ||
      (buildLog.verbose && infos.isNotEmpty);

  String get renderAttributions {
    final result = StringBuffer();
    final entries = attributions.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    for (final entry in entries) {
      if (entry.value.inMilliseconds < 1000) continue;
      if (result.isNotEmpty) result.write(', ');
      result.write('${buildLog.renderDuration(entry.value)} ${entry.key}');
    }
    return result.toString();
  }
}

extension type Attribution(String name) {
  static final Attribution analyze = Attribution._('analyzing');
  static final Attribution build = Attribution._('building');
  static final Attribution track = Attribution._('tracking');
  static final Attribution resolve = Attribution._('resolving');
  static final Attribution read = Attribution._('reading');
  static final Attribution write = Attribution._('writing');

  Attribution.optionalBuilder(this.name);
  Attribution._(this.name);
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
