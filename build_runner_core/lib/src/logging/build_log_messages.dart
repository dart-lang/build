// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../generate/phase.dart';
import 'ansi_buffer.dart';

class BuildLogMessages {
  final List<BuildLogMessage> _messages = [];
  bool _hasWarnings = false;

  bool get hasWarnings => _hasWarnings;

  void add(
    String message, {
    InBuildPhase? phase,
    String? context,
    required BuildLogSeverity severity,
  }) {
    if (severity == BuildLogSeverity.warning) _hasWarnings = true;
    _messages.add(
      BuildLogMessage(
        message: message,
        phase: phase,
        context: context,
        severity: severity,
      ),
    );
  }

  bool hasMessages({required InBuildPhase phase}) =>
      _messages.any((message) => message.phase == phase);

  int count({
    required InBuildPhase? phase,
    required BuildLogSeverity severity,
  }) {
    // TODO: fasterer
    var result = 0;
    for (final message in _messages) {
      if (identical(message.phase, phase) && message.severity == severity) {
        ++result;
      }
    }
    return result;
  }

  Iterable<BuildLogMessage> messages({
    required InBuildPhase? phase,
    required BuildLogSeverity severity,
  }) {
    return _messages.where(
      (message) =>
          identical(message.phase, phase) && message.severity == severity,
    );
  }

  BuildLogMessage last({
    required InBuildPhase? phase,
    required BuildLogSeverity severity,
  }) {
    for (final message in _messages.reversed) {
      if (identical(message.phase, phase) && message.severity == severity) {
        return message;
      }
    }
    throw StateError('no element');
  }

  List<AnsiBufferLine> renderInline({
    required InBuildPhase? phase,
    required int indent,
  }) {
    final result = {
      BuildLogSeverity.info: <AnsiBufferLine>[],
      BuildLogSeverity.warning: <AnsiBufferLine>[],
      BuildLogSeverity.error: <AnsiBufferLine>[],
    };

    for (final severity in result.keys) {
      final count = this.count(phase: phase, severity: severity);
      if (count == 0) continue;

      final severityResult = result[severity]!;
      final message = last(phase: phase, severity: severity);
      final context = message.context;
      severityResult.add(
        AnsiBufferLine([
          severity.name,
          if (context != null) ', $context',
          if (count > 1) ', +${count - 1}',
        ], indent: indent),
      );
      severityResult.add(AnsiBufferLine([message.message], indent: indent + 2));
    }

    return result.values.expand((x) => x).toList();
  }

  List<AnsiBufferLine> render(Iterable<InBuildPhase?> phases) {
    final result = <AnsiBufferLine>[];
    for (final phase in phases) {
      for (final severity in BuildLogSeverity.values) {
        for (final message in messages(phase: phase, severity: severity)) {
          final context = message.context;
          result.add(
            AnsiBufferLine([
              '${message.phase?.builderLabel ?? 'build_runner'} '
                  '${severity.name}',
              if (context != null) ' on $context',
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
  final InBuildPhase? phase;
  final String? context;
  final BuildLogSeverity severity;
  final String message;

  BuildLogMessage({
    required this.severity,
    required this.message,
    this.phase,
    this.context,
  });
}

enum BuildLogSeverity { info, warning, error }
