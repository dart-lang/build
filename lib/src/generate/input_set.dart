// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library build.src.generate.input_set;

/// Represents a set of files in a package which should be used as primary
/// inputs to a `Builder`.
class InputSet {
  /// The package that the [globs] should be ran on.
  final String package;

  /// The file patterns from [package] to use as inputs, glob syntax is
  /// supported.
  ///
  /// Note: If the [package] is a package dependency, then only files under
  /// `lib` will be available, but for the application package any files can be
  /// listed.
  final List<String> filePatterns;

  InputSet(this.package, {Iterable<String> filePatterns})
      : this.filePatterns = new List.unmodifiable(filePatterns);
}
