// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';

BuildLogger? _instance;

class BuildLogger {
  final Map<String, Duration> _durations = {};
  final Map<String, _BuildStepState> _steps = {};

  factory BuildLogger() => _instance ??= BuildLogger._();

  BuildLogger._() {
    _steps['setup'] = _BuildStepState('setup', 0, 7);
    start('setup');
  }

  Future<T> runAsyncWithLogger<T>(
    Logger? logger,
    Future<T> Function() function,
  ) async {
    return await function();
  }

  Future<T> run<T>(BuildStage stage, Future<T> Function() function) async {
    if (stage.type == StageType.setup) {
      if (stage != BuildStage.generateBuildScript) {
        previous = 1;
      }
    }
    if (stage.type != StageType.build) {
      progress(stage.type.name, number: stage.number, extra: stage.name);
    }
    if (stage == BuildStage.saveGraph) {
      start('cleanup');
    }
    if (stage == BuildStage.build) {
      stop('setup');
    }
    final result = await function();
    if (stage.type != StageType.build) {
      progress(stage.type.name, number: stage.number + 1, extra: stage.name);
    }
    return result;
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

  var previous = 0;

  void declare(List<String> names, Map<String, int> buildSteps) {
    // print('declare: $names $buildSteps');
    for (final name in names) {
      final length = buildSteps[name]!;
      if (length == 0) continue;
      _steps[name] = _BuildStepState(name, 0, length);
    }
    _steps['cleanup'] = _BuildStepState('cleanup', 0, 2);
  }

  void start(String name) {
    _steps[name]!.start();
  }

  void stop(String name) {
    _steps[name]!.stop();
  }

  void progress(String name, {int? number, String? extra}) {
    final buffer = StringBuffer();
    if (!_steps.containsKey(name)) throw 'missing: $name';
    if (number != null) {
      _steps[name]!.number = number;
    } else {
      _steps[name]!.number++;
    }
    _steps[name]!.maybeStart();

    final longestNameLength = _steps.keys.fold(
      0,
      (longest, name) => max(longest, name.length),
    );

    for (final step in _steps.values) {
      if (name == 'setup' && step.name != 'setup') break;
      var displayName =
          step.name == name
              ? (extra == null ? step.name : '${step.name} $extra')
              : step.name;
      final number = step.number;
      final of = step.of;

      final time =
          ((step.stopwatch.elapsed.inMilliseconds ~/ 100) / 10).toStringAsFixed(
            1,
          ) +
          's';

      /*var ticks = 80 * number ~/ of;
      ticks = max(0, ticks - displayName.length - 1);
      var spaces = max(0, 80 - ticks - displayName.length - 1 - time.length);
      // buffer.writeln('$displayName ${'.' * ticks}${' ' * spaces}$time');*/

      var percent = '${100 * number ~/ of}%'.padLeft(4);

      displayName = displayName.padLeft(longestNameLength);

      buffer.writeln('$displayName [$percent] $time');
    }

    final output = buffer.toString();

    final moveCursor = previous == 0 ? '' : '\x1b[${previous}F';
    final count = '\n'.allMatches(output).length;
    previous = count;
    stdout.write('$moveCursor$output');
  }

  void buildDone(bool result) {
    progress('cleanup', number: 2);
    print(_durations);

    _steps.clear();
    _durations.clear();
    _steps['setup'] = _BuildStepState('setup', 0, 7);
  }

  final Stopwatch stopwatch = Stopwatch()..start();
  var attributedDuration = Duration.zero;

  Future<T> attribute<T>(String type, FutureOr<T> Function() function) async {
    final start = stopwatch.elapsed;
    final startAttributionDuration = attributedDuration;
    try {
      return await function();
    } finally {
      final end = stopwatch.elapsed;
      final thisAttributedDuration =
          end - start - attributedDuration + startAttributionDuration;
      attributedDuration += thisAttributedDuration;
      _durations[type] =
          (_durations[type] ?? Duration.zero) + thisAttributedDuration;
    }
  }

  Logger get logger => BuildLoggerLogger(this);
}

enum BuildStage {
  generateBuildScript(StageType.setup, 0, 7),
  precompileBuildScript(StageType.setup, 1, 7),
  readAssetGraph(StageType.setup, 2, 7),
  checkForUpdates(StageType.setup, 3, 7),
  newAssetGraph(StageType.setup, 4, 7),
  initialBuildCleanup(StageType.setup, 5, 7),
  updateAssetGraph(StageType.setup, 6, 7),
  build(StageType.build, 0, 1),
  saveGraph(StageType.cleanup, 0, 2),
  writePerformance(StageType.cleanup, 1, 2);

  final StageType type;
  final int number;
  final int of;

  const BuildStage(this.type, this.number, this.of);
}

enum StageType { setup, build, cleanup }

class _BuildStepState {
  String name;
  int number;
  int of;
  Stopwatch stopwatch = Stopwatch();

  _BuildStepState(this.name, this.number, this.of) {
    // if (of == 0) throw '0 for $name';
  }

  void start() {
    if (stopwatch.isRunning) print('already running? $name');
    stopwatch.start();
  }

  void maybeStart() {
    stopwatch.start();
  }

  void stop() {
    stopwatch.stop();
  }
}

Future<void> main() async {
  final log = BuildLogger();

  await log.run(
    BuildStage.generateBuildScript,
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await log.run(
    BuildStage.precompileBuildScript,
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await log.run(
    BuildStage.readAssetGraph,
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await log.run(
    BuildStage.checkForUpdates,
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await log.run(
    BuildStage.newAssetGraph,
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await log.run(
    BuildStage.initialBuildCleanup,
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await log.run(
    BuildStage.updateAssetGraph,
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );

  log.declare(['foo', 'bar'], {'foo': 100, 'bar': 100});

  for (var i = 1; i != 101; ++i) {
    log.progress('foo');
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  for (var i = 1; i != 101; ++i) {
    log.progress('bar');
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }

  await log.run(
    BuildStage.saveGraph,
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );

  await log.run(
    BuildStage.writePerformance,
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
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

enum AttributionType { analyzer, resolver, lazy, other }
