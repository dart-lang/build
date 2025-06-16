// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/src/logging/build_log.dart';
import 'package:build/src/logging/build_log_messages.dart';
import 'package:test/test.dart';

void main() {
  group('BuildLogMessages', () {
    setUp(() {
      buildLog.configuration = buildLog.configuration.rebuild((b) {
        b.forceAnsiConsoleForTesting = false;
      });
    });
    test('hasWarnings', () {
      final messages = BuildLogMessages();
      expect(messages.hasWarnings, false);

      messages.add(
        'hi',
        phaseName: 'phase',
        context: 'thing',
        severity: Severity.error,
      );
      expect(messages.hasWarnings, false);

      messages.add(
        'hi',
        phaseName: 'phase',
        context: 'thing',
        severity: Severity.warning,
      );
      expect(messages.hasWarnings, true);

      messages.clear();
      expect(messages.hasWarnings, false);
    });

    test('hasMessages', () {
      final messages = BuildLogMessages();
      expect(messages.hasMessages(phaseName: 'phase'), false);

      messages.add(
        'hi',
        phaseName: 'unrelated_phase',
        context: 'thing',
        severity: Severity.info,
      );
      expect(messages.hasMessages(phaseName: 'phase'), false);

      messages.add(
        'hi',
        phaseName: 'phase',
        context: 'thing',
        severity: Severity.info,
      );
      expect(messages.hasMessages(phaseName: 'phase'), true);

      messages.clear();
      expect(messages.hasMessages(phaseName: 'phase'), false);
    });

    test('render groups messages by phase and context', () {
      final messages = BuildLogMessages();
      messages.add('message0', phaseName: null, severity: Severity.warning);
      messages.add(
        'message1',
        phaseName: 'phase1',
        context: 'file1',
        severity: Severity.error,
      );
      messages.add(
        'message2',
        phaseName: 'phase2',
        context: 'file1',
        severity: Severity.info,
      );
      messages.add(
        'message3',
        phaseName: 'phase1',
        context: 'file1',
        severity: Severity.warning,
      );
      messages.add(
        'message4',
        phaseName: 'phase1',
        context: 'file2',
        severity: Severity.info,
      );
      messages.add('message5', phaseName: null, severity: Severity.info);
      messages.add(
        'message6',
        phaseName: 'phase2',
        context: 'file1',
        severity: Severity.info,
      );
      expect(messages.render().map((l) => l.toString()).toList(), [
        'log output for phase1 on file1',
        'E message1',
        'W message3',
        'log output for phase2 on file1',
        '  message2',
        '  message6',
        'log output for phase1 on file2',
        '  message4',
        'log output for build_runner',
        'W message0',
        '  message5',
      ]);
    });
  });
}
