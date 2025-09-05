// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/logging/build_log.dart';
import 'package:build_runner/src/logging/build_log_messages.dart';
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
      final rendered = messages.render();
      expect(rendered.nonFailureLines.map((l) => l.toString()).toList(), [
        'file1 phase2',
        '  message2',
        '  message6',
        'file2 phase1',
        '  message4',
        'build_runner',
        'W message0',
        '  message5',
      ]);
      expect(rendered.failureLines.map((l) => l.toString()).toList(), [
        'file1 phase1',
        'E message1',
        'W message3',
      ]);
    });
  });
}
