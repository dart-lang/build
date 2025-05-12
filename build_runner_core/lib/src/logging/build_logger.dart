// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';

class BuildLogger {
  final Map<String, _BuildStepState> _steps = {};

  Future<T> runAsyncWithLogger<T>(
    Logger? logger,
    Future<T> Function() function,
  ) async {
    return await function();
  }

  Future<T> stage<T>(BuildStage stage, Future<T> Function() function) async {
    print(stage);
    final stopwatch = Stopwatch()..start();
    final result = await function();
    print('done $stage, ${stopwatch.elapsed}');
    return result;
  }

  void fine(String message) {
    print(message);
  }

  void info(String message) {
    print(message);
  }

  void warning(String message) {
    print(message);
  }

  void severe(String message, [Object? e, StackTrace? s]) {
    print(message);
  }

  var previous = 0;

  void buildStep(String name, {required int number, required int of}) {
    if (previous != 0) {
      stdout.write('\x1b[${previous}F');
    }
    _steps[name] = _BuildStepState(name, number, of);
    for (final step in _steps.values) {
      final name = step.name;
      final number = step.number;
      final of = step.of;

      var ticks = 80 * number ~/ of;
      ticks = max(0, ticks - name.length - 1);

      stdout.write('$name ${'.' * ticks}\n');
    }
    final count = _steps.values.length;

    previous = count;
  }
}

enum BuildStage {
  generateBuildScript,
  precompileBuildScript,
  readAssetGraph,
  checkForUpdates,
  newAssetGraph,
  initialBuildCleanup,
  updateAssetGraph,
  build,
  saveGraph,
  writePerformance,
}

class _BuildStepState {
  String name;
  int number;
  int of;

  _BuildStepState(this.name, this.number, this.of);
}

Future<void> main() async {
  final log = BuildLogger();
  log.info('info');

  log.buildStep('foo', number: 0, of: 100);
  log.buildStep('bar', number: 0, of: 100);

  for (var i = 1; i != 101; ++i) {
    log.buildStep('foo', number: i, of: 100);
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  for (var i = 1; i != 101; ++i) {
    log.buildStep('bar', number: i, of: 100);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  log.info('done');
}
