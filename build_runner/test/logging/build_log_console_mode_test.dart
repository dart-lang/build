// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/bootstrap/build_process_state.dart';
import 'package:build_runner/src/build_plan/phase.dart';
import 'package:build_runner/src/logging/ansi_buffer.dart';
import 'package:build_runner/src/logging/build_log.dart';
import 'package:build_runner/src/logging/build_log_messages.dart';
import 'package:test/test.dart';

void main() {
  group('BuildLog', () {
    setUp(() {
      BuildLog.resetForTests(printOnFailure: printOnFailure, consoleWidth: 80);
      buildLog.configuration = buildLog.configuration.rebuild((b) {
        b.mode = BuildLogMode.build;
        b.forceAnsiConsoleForTesting = true;
        b.forceConsoleWidthForTesting = 80;
      });
    });

    List<String> render() =>
        buildLog.render().lines.map(AnsiBuffer.removeAnsi).toList();

    test('initial display', () {
      expect(render(), <String>[]);
    });

    test('build_runner info, warnings and errors', () {
      buildLog.info('Some info.');
      buildLog.warning('A warning.');
      buildLog.warning('Another warning.');
      buildLog.error('An error.');
      expect(
        render(),
        padLinesRight('''
build_runner
  Some info.
W A warning.
W Another warning.
E An error.'''),
      );
    });

    test('phase progress', () {
      final phases = _createPhases({'builder1': 10, 'builder2': 15});
      buildLog.startPhases(phases);
      buildLog.startStep(
        phase: phases.keys.first,
        primaryInput: AssetId('pkg', 'lib/l0.dart'),
        lazy: false,
      );
      expect(
        render(),
        padLinesRight('''
0s builder1 on 10 inputs; pkg|lib/l0.dart
0s builder2 on 15 inputs'''),
      );

      buildLog.finishStep(
        phase: phases.keys.first,
        anyOutputs: true,
        anyChangedOutputs: true,
        lazy: false,
      );
      expect(
        render(),
        padLinesRight('''
0s builder1 on 10 inputs: 1 output
0s builder2 on 15 inputs'''),
      );

      buildLog.startStep(
        phase: phases.keys.first,
        primaryInput: AssetId('pkg', 'lib/l1.dart'),
        lazy: false,
      );
      expect(
        render(),
        padLinesRight('''
0s builder1 on 10 inputs: 1 output; pkg|lib/l1.dart
0s builder2 on 15 inputs'''),
      );

      buildLog.finishStep(
        phase: phases.keys.first,
        anyOutputs: true,
        anyChangedOutputs: false,
        lazy: false,
      );
      expect(
        render(),
        padLinesRight('''
0s builder1 on 10 inputs: 1 output, 1 same
0s builder2 on 15 inputs'''),
      );

      buildLog.startStep(
        phase: phases.keys.first,
        primaryInput: AssetId('pkg', 'lib/l2.dart'),
        lazy: false,
      );
      buildLog.finishStep(
        phase: phases.keys.first,
        anyOutputs: false,
        anyChangedOutputs: false,
        lazy: false,
      );
      expect(
        render(),
        padLinesRight('''
0s builder1 on 10 inputs: 1 output, 1 same, 1 no-op
0s builder2 on 15 inputs'''),
      );

      buildLog.startStep(
        phase: phases.keys.first,
        primaryInput: AssetId('pkg', 'lib/l3.dart'),
        lazy: false,
      );
      buildLog.skipStep(phase: phases.keys.first, lazy: false);
      expect(
        render(),
        padLinesRight('''
0s builder1 on 10 inputs: 1 skipped, 1 output, 1 same, 1 no-op
0s builder2 on 15 inputs'''),
      );

      buildLog.startStep(
        phase: phases.keys.first,
        primaryInput: AssetId('pkg', 'test/other.dart'),
        lazy: true,
      );
      buildLog.finishStep(
        phase: phases.keys.first,
        lazy: true,
        anyOutputs: true,
        anyChangedOutputs: true,
      );
      expect(
        render(),
        padLinesRight('''
0s builder1 on 10 inputs: 1 skipped, 1 output, 1 same, 1 no-op
0s builder2 on 15 inputs
0s builder1 (lazy): 1 output'''),
      );
    });

    test('phase progress with builder log output', () {
      final phases = _createPhases({'builder1': 10, 'builder2': 15});
      buildLog.startPhases(phases);
      buildLog.startStep(
        phase: phases.keys.first,
        primaryInput: AssetId('pkg', 'lib/l0.dart'),
        lazy: false,
      );

      buildLog.fromBuildLogLogger(
        'Some info.',
        severity: Severity.info,
        phaseName: 'builder1',
        context: 'lib/l0.dart',
      );
      buildLog.fromBuildLogLogger(
        'Some more info.',
        severity: Severity.info,
        phaseName: 'builder1',
        context: 'lib/l0.dart',
      );

      buildLog.fromBuildLogLogger(
        'A warning.',
        severity: Severity.warning,
        phaseName: 'builder2',
        context: 'lib/l1.dart',
      );

      buildLog.fromBuildLogLogger(
        'An error.',
        severity: Severity.error,
        phaseName: 'builder2',
        context: 'lib/l1.dart',
      );
      buildLog.fromBuildLogLogger(
        'An error.',
        severity: Severity.error,
        phaseName: 'builder2',
        context: 'lib/l3.dart',
      );

      expect(
        render(),
        padLinesRight('''
0s builder1 on 10 inputs; pkg|lib/l0.dart
0s builder2 on 15 inputs

lib/l0.dart builder1
  Some info.
  Some more info.

lib/l1.dart builder2
W A warning.
E An error.
lib/l3.dart builder2
E An error.'''),
      );

      buildLog.startStep(
        phase: phases.keys.first,
        primaryInput: AssetId('pkg', 'lib/l0.dart'),
        lazy: true,
      );
      buildLog.finishStep(
        phase: phases.keys.first,
        lazy: true,
        anyOutputs: false,
        anyChangedOutputs: false,
      );
      buildLog.fromBuildLogLogger(
        'An error.',
        severity: Severity.error,
        phaseName: 'builder1 (lazy)',
        context: 'lib/l3.dart',
      );

      expect(
        render(),
        padLinesRight('''
0s builder1 on 10 inputs; pkg|lib/l0.dart
0s builder2 on 15 inputs
0s builder1 (lazy): 1 no-op

lib/l0.dart builder1
  Some info.
  Some more info.

lib/l1.dart builder2
W A warning.
E An error.
lib/l3.dart builder2
E An error.
lib/l3.dart builder1 (lazy)
E An error.'''),
      );
    });

    test('complete build with builder log output', () {
      final phases = _createPhases({'builder1': 1, 'builder2': 1});
      buildLog.startPhases(phases);
      buildLog.startStep(
        phase: phases.keys.first,
        primaryInput: AssetId('pkg', 'lib/l0.dart'),
        lazy: false,
      );
      buildLog.fromBuildLogLogger(
        'Some info.',
        severity: Severity.info,
        phaseName: 'builder1',
        context: 'lib/l0.dart',
      );
      buildLog.finishStep(
        phase: phases.keys.first,
        anyOutputs: true,
        anyChangedOutputs: true,
        lazy: false,
      );
      buildLog.startStep(
        phase: phases.keys.last,
        primaryInput: AssetId('pkg', 'lib/l0.dart'),
        lazy: false,
      );
      buildLog.fromBuildLogLogger(
        'A warning.',
        severity: Severity.warning,
        phaseName: 'builder2',
        context: 'lib/l0.dart',
      );
      buildLog.fromBuildLogLogger(
        'An error.',
        severity: Severity.error,
        phaseName: 'builder2',
        context: 'lib/l0.dart',
      );
      buildLog.finishStep(
        phase: phases.keys.last,
        anyOutputs: true,
        anyChangedOutputs: true,
        lazy: false,
      );
      buildLog.finishBuild(result: true, outputs: 2);

      expect(
        render(),
        padLinesRight('''
0s builder1 on 1 input: 1 output
0s builder2 on 1 input: 1 output

lib/l0.dart builder1
  Some info.

Built with build_runner/jit in 0s with warnings; wrote 2 outputs.

lib/l0.dart builder2
W A warning.
E An error.'''),
      );
    });
  });
}

Map<InBuildPhase, int> _createPhases(Map<String, int> countsByName) {
  final result = <InBuildPhase, int>{};

  for (final entry in countsByName.entries) {
    result[_TestPhase(entry.key)] = entry.value;
  }

  return result;
}

List<String> padLinesRight(String output) {
  final result = <String>[];
  for (final line in output.split('\n')) {
    result.add(line.padRight(80));
  }
  return result;
}

class _TestPhase implements InBuildPhase {
  @override
  final String builderLabel;

  _TestPhase(this.builderLabel);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
