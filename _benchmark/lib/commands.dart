// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'config.dart';
import 'shape.dart';
import 'workspace.dart';

class BenchmarkCommand extends Command<void> {
  @override
  String get description => 'Runs "create" then "measure".';

  @override
  String get name => 'benchmark';

  @override
  Future<void> run() async {
    await CreateCommand()._run(globalResults!);
    await MeasureCommand()._run(globalResults!);
  }
}

class CreateCommand extends Command<void> {
  @override
  String get description => 'Creates codebases to benchmark.';

  @override
  String get name => 'create';

  @override
  Future<void> run() => _run(globalResults!);

  Future<void> _run(ArgResults globalResults) async {
    final config = Config.fromArgResults(globalResults);

    for (final shape in config.shapes) {
      for (final size in config.sizes) {
        final paddedSize = size.toString().padLeft(4, '0');
        final workspace = Workspace(
          config: config,
          name: '${config.generator.packageName}_${shape.name}_$paddedSize',
        );
        final runConfig = RunConfig(
          config: config,
          workspace: workspace,
          size: size,
          paddedSize: paddedSize,
          shape: shape,
        );
        config.generator.benchmark.create(runConfig);
      }
    }
  }
}

class MeasureCommand extends Command<void> {
  @override
  String get description => 'Builds and measures performance.';

  @override
  String get name => 'measure';

  @override
  Future<void> run() => _run(globalResults!);

  Future<void> _run(ArgResults globalResults) async {
    // Launch a benchmark at each size in parallel.
    final config = Config.fromArgResults(globalResults);
    final pendingResults = <(Shape, int), PendingResult>{};
    for (final shape in config.shapes) {
      for (final size in config.sizes) {
        final paddedSize = size.toString().padLeft(4, '0');
        final workspace = Workspace(
          config: config,
          name: '${config.generator.packageName}_${shape.name}_$paddedSize',
          clean: false,
        );
        pendingResults[(shape, size)] = workspace.measure();
      }
    }

    // Wait for them to complete, printing status every second only if it
    // changed.
    String? previousUpdate;
    while (!pendingResults.values.every((r) => r.isFinished)) {
      await Future<void>.delayed(const Duration(seconds: 1));

      final update = StringBuffer('${config.generator.packageName}\n');
      update.write(
        'shape,libraries,clean/ms,no changes/ms,incremental/ms,'
        'json/KiB\n',
      );
      for (final shape in config.shapes) {
        for (final size in config.sizes) {
          final pendingResult = pendingResults[(shape, size)]!;
          if (pendingResult.isFailure) {
            if (!config.allowFailures) {
              throw StateError(pendingResult.failure!);
            }
            update.write(
              [
                shape.name,
                size,
                pendingResult.cleanBuildTime.renderFailed,
                pendingResult.noChangesBuildTime.renderFailed,
                pendingResult.incrementalBuildTime.renderFailed,
                pendingResult.graphSize.renderFailed,
              ].join(','),
            );
          } else {
            update.write(
              [
                shape.name,
                size,
                pendingResult.cleanBuildTime.render,
                pendingResult.noChangesBuildTime.render,
                pendingResult.incrementalBuildTime.render,
                pendingResult.graphSize.render,
              ].join(','),
            );
          }
          update.write('\n');
        }
      }

      final updateString = update.toString();
      if (updateString != previousUpdate) {
        print(updateString);
        previousUpdate = updateString;
      }
    }
  }
}

extension DurationExtension on Duration? {
  /// Renders with `---` for `null`, to mean "pending".
  String get render => this == null ? '---' : this!.inMilliseconds.toString();

  /// Renders with X` for `null`, to mean "failed".
  String get renderFailed =>
      this == null ? 'X' : this!.inMilliseconds.toString();
}

extension IntExtension on int? {
  /// Renders with `---` for `null`, to mean "pending".
  String get render => this == null ? '---' : (this! / 1024).round().toString();

  /// Renders with X` for `null`, to mean "failed".
  String get renderFailed => this == null ? 'X' : this!.toString();
}
