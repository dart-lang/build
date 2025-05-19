// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart' show AssetId;
import 'package:logging/logging.dart';

import 'failure_reporter.dart';
import 'log_display.dart';

BuildLog? _instance;

class BuildLog {
  late final LogDisplay _display;
  final Map<Stage, StageState> _stages = {};
  final Stopwatch _stopwatch = Stopwatch()..start();

  var loaded = '';

  Duration _attributedDuration = Duration.zero;
  Stage _stage = Stage.setup;

  var again = false;

  factory BuildLog() => _instance ??= BuildLog._();

  BuildLog._() {
    _display = LogDisplay(render);
    _stages[Stage.setup] = StageState();
    progress(Progress.setup);
  }

  factory BuildLog.forTesting() = BuildLog._;

  String loggerState() {
    _display.close();
    var lines = _display.displayedLines;
    if (again) lines += 2;
    again = true;
    return '$lines,${_stages[Stage.setup]!.duration?.inMilliseconds}';
  }

  void oldLoggerState(String state) {
    loaded = state;
    try {
      final items = state.split(',');
      _display.displayedLines = int.parse(items[0]);
      _stages[Stage.setup]!.duration =
          items[1] == 'null'
              ? null
              : Duration(milliseconds: int.parse(items[1]));
    } catch (_) {}
    //
  }

  String render() {
    final buffer = StringBuffer(
      // TODO: add rerun type
      ' --- build_runner'.padRight(80) + '\n',
    );
    for (final entry in _stages.entries) {
      final stage = entry.key;
      final state = entry.value;
      /*if (name == 'setup' && step.name != 'setup') break;
      var displayName =
          step.name == name
              ? (extra == null ? step.name : '${step.name} $extra')
              : step.name;*/
      var displayName = stage.name;
      final length = stage.length;
      final progress = state.progress;

      final time =
          state.duration == null
              ? '    '
              : state.duration!.inMilliseconds < 1000
              ? ('<1s').padLeft(4)
              : ((state.duration!.inMilliseconds / 1000).round().toString() +
                      's')
                  .padLeft(4);

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
          progress == null ? '' : '${100 * progress ~/ length}'.padLeft(2);
      if (percent == '100' || percent == '') {
        percent = '';
      } else {
        percent = ', ' + percent + '%';
      }

      //displayName = displayName.padLeft(longestNameLength);

      var attrs = '';
      //if (name == step.name) {
      final buffer2 = StringBuffer();
      final entries = state.attributions.entries.toList();
      entries.sort((a, b) => b.value.compareTo(a.value));
      for (final entry in entries) {
        if (entry.value.inMilliseconds < 1000) continue;
        buffer2.write(', ');
        final time =
            (entry.value.inMilliseconds / 1000).round().toString() + 's';

        buffer2.write('${entry.key} $time');
      }
      attrs = buffer2.toString();
      //buffer.writeln('     │      │ $buffer2'.padRight(80));
      //}

      final note = state.note == null ? '' : ', ${state.note}';

      buffer.writeln('$time $displayName$note$percent$attrs'.padRight(80));
    }

    return buffer.toString();
  }

  // TODO(davidmorgan): document.
  Future<T> runAsyncWithLogger<T>(
    Logger? logger,
    Future<T> Function() function,
  ) async {
    // TODO(davidmorgan): output to the logger.
    return await function();
  }

  void fine(String message) {
    //print(message);
  }

  void info(String message) {
    //print(message);
  }

  void warning(String message) {
    //print(message);
  }

  void severe(String message, [Object? e, StackTrace? s]) {
    print('*** severe $message $e $s');
  }

  int previous = 0;

  void builders(List<String> names, Map<String, int> buildSteps) {
    // print('declare: $names $buildSteps');
    for (final name in names) {
      final length = buildSteps[name]!;
      if (length == 0) continue;
      final stage = Stage(name, length);
      _stages[stage] = StageState();
    }
    _stages[Stage.cleanup] = StageState();
  }

  void progress(Progress progress) {
    _stages[_stage]!.duration =
        (_stages[_stage]!.duration ?? Duration.zero) + _stopwatch.elapsed;
    _stopwatch.reset();

    final oldStage = _stage;
    if (progress.number != null) {
      _stage = _stages.keys.where((s) => s.name == progress.stage).single;
      _stages[_stage]!.progress = progress.number!;
    } else {
      _stages[_stage]!.progress = (_stages[_stage]!.progress ?? 0) + 1;
      _stage = _stages.keys.where((s) => s.name == progress.stage).single;
    }

    _stages[_stage]!.note = progress.note;
    if (_stages[_stage]!.duration == null) {
      _stages[_stage]!.duration = Duration.zero;
    }
    if (_stages[_stage]!.progress == null) {
      _stages[_stage]!.progress = 0;
    }

    if (_stage != oldStage) {
      _stages[oldStage]!.progress = oldStage.length;
      _stages[oldStage]!.note = null;
      _display.display();
    } else {
      _display.maybeDisplay();
    }
  }

  // TODO(davidmorgan): move reset to start.
  void buildDone(bool result) {
    progress(Progress.done);
    _display.display();
    print('     ${result ? 'SUCCESS' : 'FAILURE'}');

    _display.finish();
    _stages.clear();
    _stages[Stage.setup] = StageState();
  }

  Future<T> attributeAsync<T>(
    Attribution attribution,
    Future<T> Function() function,
  ) async {
    final start = _stopwatch.elapsed;
    final startAttributionDuration = _attributedDuration;
    final stageState = _stages[_stage]!;
    try {
      return await function();
    } finally {
      final end = _stopwatch.elapsed;
      final thisAttributedDuration =
          end - start - _attributedDuration + startAttributionDuration;
      _attributedDuration += thisAttributedDuration;
      stageState.attributions[attribution] =
          (stageState.attributions[attribution] ?? Duration.zero) +
          thisAttributedDuration;
    }
  }

  T attribute<T>(Attribution attribution, T Function() function) {
    final start = _stopwatch.elapsed;
    final startAttributionDuration = _attributedDuration;
    final stageState = _stages[_stage]!;
    try {
      return function();
    } finally {
      final end = _stopwatch.elapsed;
      final thisAttributedDuration =
          end - start - _attributedDuration + startAttributionDuration;
      _attributedDuration += thisAttributedDuration;
      stageState.attributions[attribution] =
          (stageState.attributions[attribution] ?? Duration.zero) +
          thisAttributedDuration;
    }
  }

  BuildStepLogger loggerForSetup() => BuildStepLogger(this);

  BuildStepLogger loggerForStep(String stage, AssetId input) =>
      BuildStepLogger(this);
}

class Stage {
  static final Stage setup = Stage('setup', 8);
  static final Stage cleanup = Stage('cleanup', 3);

  final String name;
  final int length;

  Stage(this.name, this.length);
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
  static final Progress done = Progress('cleanup', 3, null);

  final String stage;
  final int? number;
  final String? note;

  Progress(this.stage, this.number, [this.note]);

  Progress.build(String builder, this.note) : stage = builder, number = null;
}

class StageState {
  final Map<Attribution, Duration> attributions = {};
  Duration? duration;
  int? progress;
  String? note;

  final List<String> warnings = [];
}

class BuildStepLogger implements Logger {
  final BuildLog buildLogger;

  BuildStepLogger(this.buildLogger);

  @override
  Level get level => Level.INFO;
  @override
  set level(Level? value) {}

  @override
  Map<String, Logger> get children => {};

  @override
  void clearListeners() {}

  @override
  // TODO: implement fullName
  String get fullName => throw UnimplementedError();

  @override
  bool isLoggable(Level value) {
    // TODO: implement isLoggable
    throw UnimplementedError();
  }

  @override
  void log(
    Level logLevel,
    Object? message, [
    Object? error,
    StackTrace? stackTrace,
    Zone? zone,
  ]) {
    if (logLevel < Level.INFO) return;

    /*stdout.write(
      '\n\n\n\n\n\n$logLevel $message $error $stackTrace\n\n\n\n\n\n',
    );*/
  }

  @override
  // TODO: implement name
  String get name => throw UnimplementedError();

  @override
  // TODO: implement onLevelChanged
  Stream<Level?> get onLevelChanged => throw UnimplementedError();

  @override
  // TODO: implement onRecord
  Stream<LogRecord> get onRecord => throw UnimplementedError();

  @override
  // TODO: implement parent
  Logger? get parent => throw UnimplementedError();

  @override
  void finest(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINEST, message, error, stackTrace);

  @override
  void finer(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINER, message, error, stackTrace);

  @override
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINE, message, error, stackTrace);

  @override
  void config(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.CONFIG, message, error, stackTrace);

  @override
  void info(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.INFO, message, error, stackTrace);

  @override
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.WARNING, message, error, stackTrace);

  @override
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.SEVERE, message, error, stackTrace);

  @override
  void shout(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.SHOUT, message, error, stackTrace);

  List<ErrorReport> get errors {
    return [];
  }
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
