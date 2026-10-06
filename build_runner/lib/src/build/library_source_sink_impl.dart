// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:built_collection/built_collection.dart';

import '../contracts.dart';
import 'build_step_impl.dart';

export 'prefix_for_phase.dart';

/// The language experiment that allows a part to have imports.
const String _enhancedParts = 'enhanced-parts';

@Invariant('importPrefix.isNotEmpty')
@Invariant('languageVersion == null || languageVersion!.isNotEmpty')
class LibrarySourceSinkImpl implements LibrarySourceSink {
  final BuildStepImpl _buildStep;
  @override
  final String importPrefix;

  final String? languageVersion;

  final StringBuffer _buffer = StringBuffer();
  final ListBuilder<String> _imports = ListBuilder<String>();

  LibrarySourceSinkImpl(
    this._buildStep,
    this.importPrefix,
    this.languageVersion,
  );

  String get contribution => _buffer.toString();
  BuiltList<String> get imports => _imports.build();

  /// Whether there is a contribution that should be written to the shared part.
  ///
  /// Imports without source code are ignored and not counted as a contribution.
  ///
  /// Whitespace is not source code, so it is ignored as well. A whitespace
  /// only contribution writes nothing to the shared part file, so recording it
  /// would create state that cannot be recovered by reading the file back.
  bool get hasContribution => _buffer.toString().trim().isNotEmpty;

  void _checkCanWrite() {
    if (_buildStep.isComplete) throw BuildStepCompletedException();
  }

  @Requires('uri.isNotEmpty')
  @Requires('as.isNotEmpty')
  @Requires('as.startsWith(importPrefix)')
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
    if (!enabledExperiments.contains(_enhancedParts)) {
      throw StateError(
        'Imports in parts need the `$_enhancedParts` language experiment. '
        'Pass `--enable-experiment=$_enhancedParts` to `build_runner`, and '
        'enable it for anything else that analyzes or compiles the '
        'generated code.',
      );
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
