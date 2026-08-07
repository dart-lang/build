// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import 'build_step_impl.dart';

class LibrarySourceSinkImpl implements LibrarySourceSink {
  final BuildStepImpl _buildStep;
  @override
  final String importPrefix;

  final String? languageVersion;

  final StringBuffer _buffer = StringBuffer();
  final List<String> _imports = [];

  LibrarySourceSinkImpl(
    this._buildStep,
    this.importPrefix,
    this.languageVersion,
  );

  String get contribution => _buffer.toString();
  List<String> get imports => List.unmodifiable(_imports);

  /// Whether there is a contribution that should be written to the shared part.
  ///
  /// Imports without source code are ignored and not counted as a contribution.
  bool get hasContribution => _buffer.isNotEmpty;

  void _checkCanWrite() {
    if (_buildStep.isComplete) throw BuildStepCompletedException();
  }

  @override
  void addImport(
    String uri, {
    required String as,
    Iterable<String>? show,
    Iterable<String>? hide,
  }) {
    _checkCanWrite();
    if (!as.startsWith(importPrefix)) {
      throw ArgumentError.value(as, 'as', 'must start with $importPrefix');
    }

    final buffer = StringBuffer('import \'$uri\' as $as');
    if (show != null && show.isNotEmpty) {
      buffer.write(' show ${show.join(', ')}');
    }
    if (hide != null && hide.isNotEmpty) {
      buffer.write(' hide ${hide.join(', ')}');
    }
    buffer.write(';');
    _imports.add(buffer.toString());
  }

  @override
  void add(String content) {
    _checkCanWrite();
    _buffer.write(content);
  }
}

const String _base62Chars =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

String prefixForPhase(int phase) {
  var value = phase;
  var limit = 62;
  var length = 1;
  while (value >= limit) {
    value -= limit;
    limit *= 62;
    length++;
  }

  var result = '';
  for (var i = 0; i < length; i++) {
    result = _base62Chars[value % 62] + result;
    value ~/= 62;
  }

  return ('\$' * length) + result;
}
