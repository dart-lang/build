// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

import 'console_display.dart';

BuildLogger? _instance;

class BuildLogger {
  late final ConsoleDisplay _display;
  final Map<Stage, StageState> _stages = {};
  final Stopwatch _stopwatch = Stopwatch()..start();

  Duration _attributedDuration = Duration.zero;
  Stage _stage = Stage.setup;

  factory BuildLogger() => _instance ??= BuildLogger._();

  String loggerState() {
    _display.dispose();
    return '333333333333333333\n\n3333';
  }

  BuildLogger._() {
    _display = ConsoleDisplay(render);
    print('''
 --- build_runner
''');
    _stages[Stage.setup] = StageState();
  }

  String render() {
    final buffer = StringBuffer();
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
          state.duration.inMilliseconds == 0
              ? '    '
              : state.duration.inMilliseconds < 1000
              ? ('<1s').padLeft(4)
              : ((state.duration.inMilliseconds / 1000).round().toString() +
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
          progress == 0 ? '' : '${100 * progress ~/ length}'.padLeft(2, '0');
      if (percent == '100' || percent == '') {
        percent = '';
      } else {
        percent = ' ' + percent + '%';
      }

      //displayName = displayName.padLeft(longestNameLength);

      var attrs = '';
      //if (name == step.name) {
      final buffer2 = StringBuffer();
      final entries = state.attributions.entries.toList();
      entries.sort((a, b) => b.value.compareTo(a.value));
      for (final entry in entries) {
        if (entry.value.inMilliseconds < 1000) continue;
        final time =
            (entry.value.inMilliseconds / 1000).round().toString() + 's';

        buffer2.write('${entry.key} $time');
        if (entry != entries.last) buffer2.write(', ');
      }
      attrs = buffer2.isEmpty ? '' : ': $buffer2';
      //buffer.writeln('     │      │ $buffer2'.padRight(80));
      //}

      buffer.writeln('$time$percent $displayName$attrs'.padRight(80));
    }

    return buffer.toString();
  }

  void oldLoggerState(String state) {
    print(state);
  }

  Future<T> runAsyncWithLogger<T>(
    Logger? logger,
    Future<T> Function() function,
  ) async {
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

  void declare(List<String> names, Map<String, int> buildSteps) {
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
    _stages[_stage]!.duration += _stopwatch.elapsed;
    _stopwatch.reset();

    final oldStage = _stage;
    if (progress.number != null) {
      _stage = _stages.keys.where((s) => s.name == progress.stage).single;
      if (_stage != oldStage) {
        _stages[oldStage]!.progress = oldStage.length;
      }
      _stages[_stage]!.progress = progress.number!;
    } else {
      _stages[_stage]!.progress++;
      _stage = _stages.keys.where((s) => s.name == progress.stage).single;
    }

    if (_stage != oldStage) _display.display();
  }

  void buildDone(bool result) {
    progress(Progress.done);
    print('     ${result ? 'SUCCESS' : 'FAILURE'}');

    _display.dispose();
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

  Logger get logger => BuildLoggerLogger(this);
}

class Stage {
  static final Stage setup = Stage('setup', 7);
  static final Stage cleanup = Stage('cleanup', 3);

  final String name;
  final int length;

  Stage(this.name, this.length);
}

class Progress {
  static final Progress generateBuildScript = Progress(
    'setup',
    0,
    'generate build script',
  );
  static final Progress compileBuildScript = Progress(
    'setup',
    1,
    'compile build script',
  );
  static final Progress readAssetGraph = Progress(
    'setup',
    2,
    'read asset graph',
  );
  static final Progress checkForUpdates = Progress(
    'setup',
    3,
    'check for updates',
  );
  static final Progress newAssetGraph = Progress(
    'setup',
    4,
    'create asset graph',
  );
  static final Progress initialBuildCleanup = Progress(
    'setup',
    5,
    'initial build cleanup',
  );
  static final Progress updateAssetGraph = Progress(
    'setup',
    6,
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
  static final Progress done = Progress('cleanup', 2, 'done');

  final String stage;
  final int? number;
  final String? note;

  Progress(this.stage, this.number, [this.note]);

  Progress.build(String builder) : stage = builder, number = null, note = null;
}

class StageState {
  final Map<Attribution, Duration> attributions = {};
  Duration duration = Duration.zero;
  int progress = 0;
}

class BuildLoggerLogger implements Logger {
  final BuildLogger buildLogger;

  BuildLoggerLogger(this.buildLogger);

  @override
  Level get level => Level.ALL;
  @override
  set level(Level? value) {}

  @override
  Map<String, Logger> get children => {};

  @override
  void clearListeners() {}

  @override
  void config(Object? message, [Object? error, StackTrace? stackTrace]) {
    // TODO: implement config
  }

  @override
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) {
    // TODO: implement fine
  }

  @override
  void finer(Object? message, [Object? error, StackTrace? stackTrace]) {
    // TODO: implement finer
  }

  @override
  void finest(Object? message, [Object? error, StackTrace? stackTrace]) {
    // TODO: implement finest
  }

  @override
  // TODO: implement fullName
  String get fullName => throw UnimplementedError();

  @override
  void info(Object? message, [Object? error, StackTrace? stackTrace]) {
    // TODO: implement info
  }

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
    // TODO: implement log
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
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) {
    // TODO: implement severe
  }

  @override
  void shout(Object? message, [Object? error, StackTrace? stackTrace]) {
    // TODO: implement shout
  }

  @override
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) {
    // TODO: implement warning
  }
}

extension type Attribution(String name) {
  static final Attribution analyze = Attribution._('analyze');
  static final Attribution build = Attribution._('build');
  static final Attribution check = Attribution._('build');
  static final Attribution resolve = Attribution._('resolve');
  static final Attribution read = Attribution._('read');
  static final Attribution write = Attribution._('write');

  Attribution.optionalBuilder(this.name);
  Attribution._(this.name);
}

enum AttributionType { analyzer, resolver, lazy, other }
