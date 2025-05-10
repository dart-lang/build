// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner_core/src/logging/build_log_messages.dart';
import 'package:test/test.dart';

void main() {
  group('BuildLogMessages', () {
    test('hasWarnings', () {
      final messages = BuildLogMessages();
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
        phaseName: 'phase',
        context: 'thing',
        severity: Severity.info,
      );
      expect(messages.hasMessages(phaseName: 'phase'), true);

      messages.clear();
      expect(messages.hasMessages(phaseName: 'phase'), false);
    });

    test('messages', () {
      final messages = BuildLogMessages();
      messages.add(
        'hi',
        phaseName: 'phase',
        context: 'thing',
        severity: Severity.info,
      );
      messages.add(
        'hi again',
        phaseName: 'phase',
        context: 'thing',
        severity: Severity.info,
      );
      expect(messages.messages(phaseName: 'phase', severity: Severity.info), [
        Message(
          phaseName: 'phase',
          context: 'thing',
          severity: Severity.info,
          text: 'hi',
        ),
        Message(
          phaseName: 'phase',
          context: 'thing',
          severity: Severity.info,
          text: 'hi again',
        ),
      ]);
    });
  });
}
