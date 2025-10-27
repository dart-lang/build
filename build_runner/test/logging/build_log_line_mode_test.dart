// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/bootstrap/build_process_state.dart';
import 'package:build_runner/src/build_plan/phase.dart';
import 'package:build_runner/src/logging/build_log.dart';
import 'package:build_runner/src/logging/build_log_messages.dart';
import 'package:test/test.dart';

void main() {
  group('BuildLog', () {
    late List<String> lines;

    setUp(() {
      lines = [];
      BuildLog.resetForTests();
      buildLog.configuration = buildLog.configuration.rebuild((b) {
        b.mode = BuildLogMode.build;
        b.forceAnsiConsoleForTesting = false;
        b.onLog = (record) => lines.add(record.toString());
        b.throttleProgressUpdates = false;
      });
    });

    test('build_runner info, warnings and errors', () {
      buildLog.info('Some info.');
      buildLog.warning('A warning.');
      buildLog.warning('Another warning.');
      buildLog.error('An error.');
      expect(lines, [
        '  Some info.',
        'W A warning.',
        'W Another warning.',
        'E An error.',
      ]);
    });

    test('compile progress', () {
      buildLog.logCompile(isAot: false, function: () async {});
      expect(lines, ['  0s compiling builders/jit']);
      buildLog.logCompile(isAot: true, function: () async {});
      expect(lines, [
        '  0s compiling builders/jit',
        '  0s compiling builders/aot',
      ]);
    });

    test('phase progress', () {
      final phases = _createPhases({'builder1': 10, 'builder2': 15});
      buildLog.startPhases(phases);
      buildLog.startStep(
        phase: phases.keys.first,
        primaryInput: AssetId('pkg', 'lib/l0.dart'),
        lazy: false,
      );
      expect(lines, ['  0s builder1 on 10 inputs; pkg|lib/l0.dart']);

      buildLog.finishStep(
        phase: phases.keys.first,
        anyOutputs: true,
        anyChangedOutputs: true,
        lazy: false,
      );
      buildLog.startStep(
        phase: phases.keys.first,
        primaryInput: AssetId('pkg', 'lib/l1.dart'),
        lazy: false,
      );
      expect(lines, [
        '  0s builder1 on 10 inputs; pkg|lib/l0.dart',
        '  0s builder1 on 10 inputs: 1 output; pkg|lib/l1.dart',
      ]);

      buildLog.finishStep(
        phase: phases.keys.first,
        anyOutputs: true,
        anyChangedOutputs: false,
        lazy: false,
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
      expect(lines, [
        '  0s builder1 on 10 inputs; pkg|lib/l0.dart',
        '  0s builder1 on 10 inputs: 1 output; pkg|lib/l1.dart',
        '  0s builder1 on 10 inputs: 1 output, 1 same; pkg|lib/l2.dart',
      ]);

      buildLog.startStep(
        phase: phases.keys.first,
        primaryInput: AssetId('pkg', 'lib/l3.dart'),
        lazy: false,
      );
      buildLog.skipStep(phase: phases.keys.first, lazy: false);
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
      expect(lines, [
        '  0s builder1 on 10 inputs; pkg|lib/l0.dart',
        '  0s builder1 on 10 inputs: 1 output; pkg|lib/l1.dart',
        '  0s builder1 on 10 inputs: 1 output, 1 same; pkg|lib/l2.dart',
        '  0s builder1 on 10 inputs: 1 output, 1 same, 1 no-op; pkg|lib/l3.dart',
        '  0s builder1 (lazy); pkg|test/other.dart',
      ]);
    });

    test('phase progress with builder log output', () {
      buildLog.configuration = buildLog.configuration.rebuild((b) {
        b.mode = BuildLogMode.build;
      });

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

      expect(lines, [
        '  0s builder1 on 10 inputs; pkg|lib/l0.dart',
        '  builder1 on lib/l0.dart:\n'
            'Some info.',
        '  builder1 on lib/l0.dart:\n'
            'Some more info.',
        'W builder2 on lib/l1.dart:\n'
            'A warning.',
        'E builder2 on lib/l1.dart:\n'
            'An error.',
        'E builder2 on lib/l3.dart:\n'
            'An error.',
      ]);

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

      expect(lines, [
        '  0s builder1 on 10 inputs; pkg|lib/l0.dart',
        '  builder1 on lib/l0.dart:\n'
            'Some info.',
        '  builder1 on lib/l0.dart:\n'
            'Some more info.',
        'W builder2 on lib/l1.dart:\n'
            'A warning.',
        'E builder2 on lib/l1.dart:\n'
            'An error.',
        'E builder2 on lib/l3.dart:\n'
            'An error.',
        '  0s builder1 (lazy); pkg|lib/l0.dart',
        'E builder1 (lazy) on lib/l3.dart:\n'
            'An error.',
      ]);
    });

    test('complete build with builder log output', () {
      buildLog.configuration = buildLog.configuration.rebuild((b) {
        b.mode = BuildLogMode.build;
      });
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

      expect(lines, [
        '  0s builder1 on 1 input; pkg|lib/l0.dart',
        '  builder1 on lib/l0.dart:\n'
            'Some info.',
        '  0s builder1 on 1 input: 1 output',
        '  0s builder2 on 1 input; pkg|lib/l0.dart',
        'W builder2 on lib/l0.dart:\n'
            'A warning.',
        'E builder2 on lib/l0.dart:\n'
            'An error.',
        '  0s builder2 on 1 input: 1 output',
        '  Built with build_runner/jit in 0s; wrote 2 outputs.',
      ]);
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

class _TestPhase implements InBuildPhase {
  @override
  final String displayName;

  _TestPhase(this.displayName);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
