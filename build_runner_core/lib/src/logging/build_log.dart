// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart' show AssetId;
import 'package:logging/logging.dart';

import 'failure_reporter.dart';
import 'log_display.dart';

BuildLog? _instance;

class BuildLog {
  late final LogDisplay _display;
  final Stopwatch _stopwatch = Stopwatch()..start();

  final Map<String, Stage> _stagesByName = {};
  Stage _currentStage = Stage.setup();

  var loaded = '';

  Duration _attributedDuration = Duration.zero;

  var again = false;

  bool? result = null;

  factory BuildLog() => _instance ??= BuildLog._();

  BuildLog._() {
    _display = LogDisplay(render);
    _stagesByName['setup'] = Stage.setup();
    progress(Progress.setup);
  }

  factory BuildLog.forTesting() = BuildLog._;

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

  String render() {
    final buildDone = result != null;
    final buffer = StringBuffer(
      // TODO: add rerun type
      ' --- build_runner'.padRight(80) + '\n',
    );
    for (final entry in _stagesByName.entries) {
      final name = entry.key;
      final stage = entry.value;
      final length = stage.length;

      /*if (name == 'setup' && step.name != 'setup') break;
      var displayName =
          step.name == name
              ? (extra == null ? step.name : '${step.name} $extra')
              : step.name;*/
      final progress = stage.progress;

      final time =
          stage.duration == null
              ? '    '
              : stage.duration!.inMilliseconds < 1000
              ? ('<1s').padLeft(4)
              : ((stage.duration!.inMilliseconds / 1000).round().toString() +
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
      final entries = stage.attributions.entries.toList();
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

      final note = stage.note == null ? '' : ', ${stage.note}';

      buffer.writeln('$time $name$note$percent$attrs'.padRight(80));

      if (!buildDone && stage.warnings.isNotEmpty) {
        final warnings = stage.warnings.values.fold(
          0,
          (count, list) => count + list.length,
        );
        final key = stage.warnings.keys.last;
        final value = stage.warnings[key]!.last;
        buffer.writeln(
          '       $warnings warning(s), latest: $key'.padRight(80),
        );
        buffer.writeln('       $value'.padRight(80));
      }
    }

    if (result != null) {
      buffer.writeln('     ${result! ? 'SUCCESS' : 'FAILURE'}');
      for (final stage in _stagesByName.values) {
        if (stage.warnings.isNotEmpty) {
          buffer.writeln(' --- ${stage.name} warning(s)');
          for (final key in stage.warnings.keys) {
            buffer.writeln('     $key');
            for (final value in stage.warnings[key]!) {
              buffer.writeln('     $value');
            }
          }
        }
      }
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
      _stagesByName[name] = Stage(name: name, length: length);
    }
    _stagesByName['cleanup'] = Stage.cleanup();
  }

  void progress(Progress progress) {
    _currentStage.duration =
        (_currentStage.duration ?? Duration.zero) + _stopwatch.elapsed;
    _stopwatch.reset();

    final oldStage = _currentStage;
    if (progress.number != null) {
      _currentStage = _stagesByName[progress.stage]!;
      _currentStage.progress = progress.number!;
    } else {
      _currentStage.progress = (_currentStage.progress ?? 0) + 1;
      _currentStage = _stagesByName[progress.stage]!;
    }

    _currentStage.note = progress.note;
    _currentStage.duration ??= Duration.zero;
    _currentStage.progress ??= 0;

    if (_currentStage != oldStage) {
      oldStage.progress = oldStage.length;
      oldStage.note = null;
      _display.display();
    } else {
      _display.maybeDisplay();
    }
  }

  // TODO(davidmorgan): move reset to start.
  void buildDone(bool result) {
    progress(Progress.done);
    this.result = result;
    _display.display();

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

  BuildStepLogger loggerForSetup() =>
      BuildStepLogger(this, _stagesByName['setup']!, null);

  BuildStepLogger loggerForStep(String stage, AssetId input) =>
      BuildStepLogger(this, _stagesByName[stage]!, input);

  BuildStepLogger loggerForPostprocess(AssetId input) =>
      BuildStepLogger(this, _stagesByName['cleanup']!, input);
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

class Stage {
  final String name;
  final int length;

  final Map<Attribution, Duration> attributions = {};
  Duration? duration;
  int? progress;
  String? note;

  Stage({required this.name, required this.length});
  factory Stage.setup() => Stage(name: 'setup', length: 8);
  factory Stage.cleanup() => Stage(name: 'cleanup', length: 3);

  final Map<AssetId?, List<String>> warnings = {};
}

class BuildStepLogger implements Logger {
  final BuildLog buildLogger;
  final Stage stage;
  final AssetId? primaryInput;

  BuildStepLogger(this.buildLogger, this.stage, this.primaryInput);

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

    (stage.warnings[primaryInput] ??= []).add('$message');
    buildLogger._display.display();

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
