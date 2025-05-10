// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:logging/logging.dart';

import 'ansi_buffer.dart';

part 'build_log_messages.g.dart';

/// Messages logged to `BuildLog`.
///
/// Messages are bucketed by the name of the running build phase and the message
/// [Severity]. The `null ` phase name means no phase is running.
class BuildLogMessages {
  bool _hasWarnings = false;
  final Set<String?> _phaseNamesWithMessages = {};
  final Map<(String?, Severity), List<Message>>
  _messagesByPhaseNameAndSeverity = {};

  void clear() {
    _hasWarnings = false;
    _phaseNamesWithMessages.clear();
    _messagesByPhaseNameAndSeverity.clear();
  }

  void add(
    String string, {
    String? phaseName,
    String? context,
    required Severity severity,
  }) {
    if (severity == Severity.warning) _hasWarnings = true;
    _phaseNamesWithMessages.add(phaseName);
    final message = Message(
      text: string,
      phaseName: phaseName,
      context: context,
      severity: severity,
    );
    _messagesByPhaseNameAndSeverity
        .putIfAbsent((phaseName, severity), () => [])
        .add(message);
  }

  bool get hasWarnings => _hasWarnings;

  bool hasMessages({required String? phaseName}) =>
      _phaseNamesWithMessages.contains(phaseName);

  Iterable<Message> messages({
    required String? phaseName,
    required Severity severity,
  }) => _messagesByPhaseNameAndSeverity[(phaseName, severity)] ?? const [];

  List<AnsiBufferLine> render(Iterable<String?> phaseNames) {
    final result = <AnsiBufferLine>[];
    for (final phaseName in phaseNames) {
      AnsiBufferLine? previousHeader;
      for (final severity in Severity.values) {
        for (final message in messages(
          phaseName: phaseName,
          severity: severity,
        )) {
          final context = message.context;
          final header = AnsiBufferLine([
            'log output for ',
            AnsiBuffer.bold,
            message.phaseName ?? 'build_runner',
            AnsiBuffer.reset,
            if (context != null) ...[
              ' on ',
              AnsiBuffer.bold,
              context,
              AnsiBuffer.reset,
            ],
          ]);
          if (header != previousHeader) {
            result.add(header);
          }
          previousHeader = header;
          var first = true;
          for (final line in message.text.split('\n')) {
            result.add(
              AnsiBufferLine([
                first ? severity.prefix : '  ',
                line,
              ], hangingIndent: 2),
            );
            first = false;
          }
        }
      }
    }
    return result;
  }
}

/// A message logged to `BuildLog`.
abstract class Message implements Built<Message, MessageBuilder> {
  /// The running build phase, or `null` if none is running.
  ///
  /// If it's a lazy build step the name is suffixed ` (lazy)`.
  String? get phaseName;

  /// The message context: usually the build step input.
  String? get context;

  Severity get severity;
  String get text;

  factory Message({
    required String? phaseName,
    required String? context,
    required Severity severity,
    required String text,
  }) = _$Message._;
  Message._();
}

/// Severity of a message logged to `BuildLog`.
enum Severity {
  /// An informational message.
  ///
  /// Builder `info` logs are only displayed in "verbose" mode, but
  /// `build_runner` `info` logs are always displayed.s
  info,

  /// A non-fatal warning.
  warning,

  /// An error explaining why the current operation has failed.
  error;

  static Severity fromLogLevel(Level level) {
    if (level < Level.WARNING) return Severity.info;
    if (level < Level.SEVERE) return Severity.warning;
    return Severity.error;
  }

  Level get toLogLevel => switch (this) {
    Severity.info => Level.INFO,
    Severity.warning => Level.WARNING,
    Severity.error => Level.SEVERE,
  };

  /// Prefix for display.
  String get prefix => switch (this) {
    Severity.info => '  ',
    Severity.warning => 'W ',
    Severity.error => 'E ',
  };
}
