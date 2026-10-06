// Copyright (c) 2026, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

const _librarySourceSinkModeKey = #builtValueLibrarySourceSinkMode;

/// Whether generation is for `BuildStep.librarySourceSink`.
///
/// In this mode `build_runner` owns the `part` directive, so generation does
/// not check for one.
bool get isLibrarySourceSinkMode =>
    Zone.current[_librarySourceSinkModeKey] == true;

/// Runs [function] with [isLibrarySourceSinkMode] true.
Future<T> runInLibrarySourceSinkMode<T>(Future<T> Function() function) =>
    runZoned(function, zoneValues: {_librarySourceSinkModeKey: true});

/// Whether [source], the source of the library in file [fileName], has a
/// `part` directive for its `.g.dart` part.
///
/// Matches only a directive at the start of a line, so a commented-out
/// directive does not count.
bool hasGDartPartStatement(String source, String fileName) {
  final partName = RegExp.escape(
    '${fileName.substring(0, fileName.length - 5)}.g.dart',
  );
  return RegExp(
    '^\\s*part\\s+([\'"])$partName\\1\\s*;',
    multiLine: true,
  ).hasMatch(source);
}
