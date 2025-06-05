// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ansi_buffer.dart';

class BuildLogMessages {
  final List<BuildLogMessage> _messages = [];

  void add(
    String message, {
    String? stage,
    String? substage,
    required BuildLogSeverity severity,
  }) {
    _messages.add(
      BuildLogMessage(
        message: message,
        stage: stage,
        substage: substage,
        severity: severity,
      ),
    );
  }

  int count({required String? stage, required BuildLogSeverity severity}) {
    // TODO: fasterer
    var result = 0;
    for (final message in _messages) {
      if (message.severity == severity && message.stage == stage) ++result;
    }
    return result;
  }

  Iterable<BuildLogMessage> messages({
    required String? stage,
    required BuildLogSeverity severity,
  }) {
    return _messages.where(
      (message) => message.stage == stage && message.severity == severity,
    );
  }

  BuildLogMessage last({
    required String? stage,
    required BuildLogSeverity severity,
  }) {
    for (final message in _messages.reversed) {
      if (message.severity == severity && message.stage == stage) {
        return message;
      }
    }
    throw StateError('no element');
  }

  List<AnsiBufferLine> renderInline({
    required String? stage,
    required int indent,
  }) {
    final result = {
      BuildLogSeverity.info: <AnsiBufferLine>[],
      BuildLogSeverity.warning: <AnsiBufferLine>[],
      BuildLogSeverity.error: <AnsiBufferLine>[],
    };

    for (final severity in result.keys) {
      final count = this.count(stage: stage, severity: severity);
      if (count == 0) continue;

      final severityResult = result[severity]!;
      final message = last(stage: stage, severity: severity);
      final substage = message.substage;
      severityResult.add(
        AnsiBufferLine([
          severity.name,
          if (substage != null) ', $substage',
          if (count > 1) ', +${count - 1}',
        ], indent: indent),
      );
      severityResult.add(AnsiBufferLine([message.message], indent: indent + 2));
    }

    return result.values.expand((x) => x).toList();
  }

  List<AnsiBufferLine> render() {
    final result = <AnsiBufferLine>[];
    // TODO: fasterer
    final stages =
        _messages.map((message) => message.stage).toSet().toList()..sort();

    for (final stage in stages) {
      for (final severity in BuildLogSeverity.values) {
        for (final message in messages(stage: stage, severity: severity)) {
          final substage = message.substage;
          result.add(
            AnsiBufferLine([
              '${message.stage ?? 'build_runner'} ${severity.name}',
              if (substage != null) ' $substage',
            ]),
          );
          result.add(AnsiBufferLine([message.message], indent: 2));
        }
      }
    }
    return result;
  }
}

class BuildLogMessage {
  final String? stage;
  final String? substage;
  final BuildLogSeverity severity;
  final String message;

  BuildLogMessage({
    required this.severity,
    required this.message,
    this.stage,
    this.substage,
  });
}

enum BuildLogSeverity { info, warning, error }
