// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The strategy to use with regard to existing output on disk.
enum OutputStrategy {
  /// Overwrite incorrect outputs with correct content.
  ///
  /// This is the default.
  overwrite,

  /// Preserve incorrect outputs until the build step that writes the output is
  /// triggered by an input change.
  ///
  /// This was the only behavior available before 2.16.0. It's useful for trying
  /// changes to generated code.
  keep,

  /// Do no writes or deletes.
  ///
  /// Check the output and fail if it doesn't match the expected output. Useful
  /// as a presubmit check.
  verify,
}
