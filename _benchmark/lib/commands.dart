// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'config.dart';
import 'shape.dart';
import 'workspace.dart';

class BenchmarkCommand extends Command<void> {
  @override
  String get description => 'Runs the benchmark suite sequentially.';

  @override
  String get name => 'benchmark';

  @override
  Future<void> run() async {
    await MeasureCommand()._run(globalResults!);
  }
}

class CreateCommand extends Command<void> {
  @override
  String get description =>
      'Creates codebases to benchmark (for manual checking).';

  @override
  String get name => 'create';

  @override
  Future<void> run() => _run(globalResults!);

  Future<void> _run(ArgResults globalResults) async {
    final config = Config.fromArgResults(globalResults);

    for (final shape in config.shapes) {
      for (final size in config.sizes) {
        final paddedSize = size.toString().padLeft(4, '0');
        for (final web in config.webConfigs) {
          final workspace = Workspace(
            config: config,
            name:
                '${config.generator.packageName}_${shape.name}_$paddedSize'
                '${web ? "_web" : ""}',
          );
          final runConfig = RunConfig(
            config: config,
            workspace: workspace,
            size: size,
            paddedSize: paddedSize,
            shape: shape,
            version: 'local',
            web: web,
          );
          config.generator.benchmark.create(runConfig);
        }
      }
    }
  }
}

class MeasureCommand extends Command<void> {
  @override
  String get description => 'Builds and measures performance sequentially.';

  @override
  String get name => 'measure';

  @override
  Future<void> run() => _run(globalResults!);

  Future<void> _run(ArgResults globalResults) async {
    final config = Config.fromArgResults(globalResults);

    final showShape = config.shapes.any((s) => s != Shape.random);

    // Print CSV Header
    print(
      [
        'Version',
        if (showShape) 'Shape',
        'Size',
        'Web',
        'Clean Mean (s)',
        'Clean CI (s)',
        'No-Changes Mean (s)',
        'No-Changes CI (s)',
        'Incremental Mean (s)',
        'Incremental CI (s)',
        'Graph Size (KiB)',
      ].join(','),
    );

    for (final version in config.versions) {
      for (final shape in config.shapes) {
        for (final size in config.sizes) {
          for (final web in config.webConfigs) {
            await _runBenchmarkCell(
              config,
              version,
              shape,
              size,
              web,
              showShape: showShape,
            );
          }
        }
      }
    }
  }

  Future<void> _runBenchmarkCell(
    Config config,
    String version,
    Shape shape,
    int size,
    bool web, {
    required bool showShape,
  }) async {
    final cleanTimes = <Duration>[];
    final noChangesTimes = <Duration>[];
    final incrementalTimes = <Duration>[];
    int? graphSize;

    for (var rep = 0; rep < config.repetitions; ++rep) {
      final paddedSize = size.toString().padLeft(4, '0');
      final workspaceName =
          '${config.generator.packageName}_${shape.name}_${paddedSize}_'
          '${web ? "web_" : ""}${version}_rep$rep';

      final workspace = Workspace(
        config: config,
        name: workspaceName,
        clean: true,
      );

      final runConfig = RunConfig(
        config: config,
        workspace: workspace,
        size: size,
        paddedSize: paddedSize,
        shape: shape,
        version: version,
        web: web,
      );

      // 1. Create source
      config.generator.benchmark.create(runConfig);

      // 2. Run pub get
      final pubGetExitCode = await workspace.runPubGet();
      if (pubGetExitCode != 0) {
        workspace.deleteSelf();
        if (!config.allowFailures) {
          throw StateError('pub get failed for $workspaceName');
        }
        continue;
      }

      // 3. Measure
      final pendingResult = PendingResult();
      await workspace.measureSequential(pendingResult);

      if (pendingResult.isFailure) {
        workspace.deleteSelf();
        if (!config.allowFailures) {
          throw StateError(pendingResult.failure!);
        }
        continue;
      }

      cleanTimes.add(pendingResult.cleanBuildTime!);
      noChangesTimes.add(pendingResult.noChangesBuildTime!);
      incrementalTimes.add(pendingResult.incrementalBuildTime!);
      graphSize = pendingResult.graphSize;

      // 4. Cleanup
      workspace.deleteSelf();
    }

    if (cleanTimes.isEmpty) return;

    final cleanStats = Stats(cleanTimes);
    final noChangesStats = Stats(noChangesTimes);
    final incrementalStats = Stats(incrementalTimes);

    print(
      [
        version,
        if (showShape) shape.name,
        size,
        web ? 'true' : 'false',
        cleanStats.meanSeconds.toStringAsFixed(2),
        cleanStats.confidenceIntervalHalfWidthSeconds.toStringAsFixed(2),
        noChangesStats.meanSeconds.toStringAsFixed(2),
        noChangesStats.confidenceIntervalHalfWidthSeconds.toStringAsFixed(2),
        incrementalStats.meanSeconds.toStringAsFixed(2),
        incrementalStats.confidenceIntervalHalfWidthSeconds.toStringAsFixed(2),
        graphSize == null ? 'X' : (graphSize / 1024).round().toString(),
      ].join(','),
    );
  }
}

class Stats {
  final List<Duration> durations;

  Stats(this.durations);

  double get meanSeconds {
    if (durations.isEmpty) return 0.0;
    final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    return (totalMs / durations.length) / 1000.0;
  }

  double get standardDeviationSeconds {
    if (durations.length <= 1) return 0.0;
    final mean = meanSeconds;
    final variance =
        durations
            .map((d) {
              final diff = (d.inMilliseconds / 1000.0) - mean;
              return diff * diff;
            })
            .reduce((a, b) => a + b) /
        (durations.length - 1);
    return sqrt(variance);
  }

  /// Returns the half-width of the 90% confidence interval for the mean.
  double get confidenceIntervalHalfWidthSeconds {
    final n = durations.length;
    if (n <= 1) return 0.0;
    final sd = standardDeviationSeconds;
    final t = _tCriticalValue(n);
    return t * (sd / sqrt(n));
  }

  double _tCriticalValue(int n) {
    const table = {
      2: 6.314,
      3: 2.920,
      4: 2.353,
      5: 2.132,
      6: 2.015,
      7: 1.943,
      8: 1.895,
      9: 1.860,
      10: 1.833,
      11: 1.812,
      12: 1.796,
      13: 1.782,
      14: 1.771,
      15: 1.761,
      16: 1.753,
      17: 1.746,
      18: 1.740,
      19: 1.734,
      20: 1.729,
    };
    if (n < 2) return 0.0;
    if (n <= 20) return table[n]!;
    // Z-score approximation for large n
    return 1.645;
  }
}
