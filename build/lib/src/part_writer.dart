// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Writes a part file for the primary input library.
///
/// The owning builder must call either [close] or [cancel] before the end of
/// the build step.
abstract class PartWriter {
  /// The import prefix prefix assigned to the builder that owns this writer.
  String get importPrefix;

  /// Adds an import directive to the top of the generated part.
  ///
  /// Throws an [ArgumentError] if [as] does not start with [importPrefix].
  void addImport(
    String uri, {
    required String as,
    Iterable<String>? show,
    Iterable<String>? hide,
  });

  /// Appends [content] to the body of the generated part.
  void write(String content);

  /// Appends [content] followed by a newline to the body of the generated part.
  void writeln([String content = '']);

  /// Commits the accumulated imports and content to the build step.
  void close();

  /// Discards all accumulated state.
  void cancel();
}
