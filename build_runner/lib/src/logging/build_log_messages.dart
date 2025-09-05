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
  final Map<_MessageCategory, List<Message>> _messageByCategory = {};

  void clear() {
    _hasWarnings = false;
    _phaseNamesWithMessages.clear();
    _messageByCategory.clear();
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
    _messageByCategory
        .putIfAbsent(
          _MessageCategory(phaseName: phaseName, context: context),
          () => [],
        )
        .add(message);
  }

  bool get hasWarnings => _hasWarnings;

  bool hasMessages({required String? phaseName}) =>
      _phaseNamesWithMessages.contains(phaseName);

  RenderResult render() {
    final result = RenderResult();

    final buildRunnerCategories = <MapEntry<_MessageCategory, List<Message>>>[];
    for (final entry in _messageByCategory.entries) {
      if (entry.key.phaseName == null) {
        // Messages with no phase name are `build_runner` messages, render them
        // last for maximum visibility.
        buildRunnerCategories.add(entry);
      } else {
        result.addAll(_renderCategory(entry));
      }
    }

    for (final entry in buildRunnerCategories) {
      result.addAll(_renderCategory(entry));
    }

    return result;
  }

  RenderResult _renderCategory(
    MapEntry<_MessageCategory, List<Message>> entry,
  ) {
    final category = entry.key;
    final context = category.context;

    final messages = _messageByCategory[category]!;
    final failed = messages.any(
      (message) => message.severity == Severity.error,
    );

    final result = <AnsiBufferLine>[];
    result.add(
      AnsiBufferLine([
        if (context != null) ...[
          failed ? AnsiBuffer.boldRed : AnsiBuffer.bold,
          context,
          AnsiBuffer.reset,
          ' ',
        ],
        AnsiBuffer.bold,
        category.phaseName ?? 'build_runner',
        AnsiBuffer.reset,
      ]),
    );

    for (final message in messages) {
      var first = true;
      for (final line in message.text.split('\n')) {
        result.add(
          AnsiBufferLine([
            if (message.severity == Severity.error) AnsiBuffer.boldRed,
            first ? message.severity.prefix : '  ',
            if (message.severity == Severity.error) AnsiBuffer.reset,
            line,
          ], hangingIndent: 2),
        );
        first = false;
      }
    }

    return failed
        ? RenderResult.failed(result)
        : RenderResult.succeeded(result);
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

/// Messages are displayed by phase+context.
abstract class _MessageCategory
    implements Built<_MessageCategory, _MessageCategoryBuilder> {
  String? get phaseName;
  String? get context;

  factory _MessageCategory({
    required String? phaseName,
    required String? context,
  }) => _$MessageCategory._(phaseName: phaseName, context: context);
  _MessageCategory._();
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

class RenderResult {
  /// Rendered messages block that does not contain any errors.
  final List<AnsiBufferLine> nonFailureLines;

  /// Rendered messages block that does contain errors.
  final List<AnsiBufferLine> failureLines;

  RenderResult() : nonFailureLines = [], failureLines = [];
  RenderResult.failed(List<AnsiBufferLine> lines)
    : failureLines = lines,
      nonFailureLines = [];
  RenderResult.succeeded(List<AnsiBufferLine> lines)
    : nonFailureLines = lines,
      failureLines = [];

  void addAll(RenderResult other) {
    nonFailureLines.addAll(other.nonFailureLines);
    failureLines.addAll(other.failureLines);
  }
}
