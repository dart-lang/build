// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Adds source to a Dart library.
///
/// Source additions and imports are accumulated from all builders that use a
/// `LibrarySourceSink` and written to a single shared part file.
///
/// Experimental, may change following feedback and discussion at
/// https://github.com/dart-lang/build/discussions.
abstract class LibrarySourceSink {
  /// Adds [source] to the library.
  ///
  /// The source must not contain directives. It does not need to be formatted.
  void add(String source);

  /// The import prefix reserved for this sink.
  String get importPrefix;

  /// Adds an import directive to the library.
  ///
  /// The `as` clause must start with [importPrefix], or an [ArgumentError] is
  /// thrown.
  ///
  /// TODO(davidmorgan): currently this only works with the "parts with imports"
  /// experiment enabled. Handle the case where the feature is unavailable.
  void addImport(
    String uri, {
    required String as,
    Iterable<String>? show,
    Iterable<String>? hide,
  });
}
