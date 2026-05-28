// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Placeholders are virtual files that exist in every package.
///
/// Builders can declare them as input "extensions" in order to declare a fixed
/// list of outputs. This uses the normal extension matching mechanism, but in a
/// surprising way: the entire placeholder name is declared as the "input
/// extension", so the entire name is replaced with the "output extension".
///
/// Builders usually match the placeholder name, not the full path. This puts
/// the outputs in the placeholder path, because only the name is replaced.
/// So matching `$lib$` puts outputs under `lib`.
class Placeholders {
  static const String libName = r'$lib$';
  static const String libPath = 'lib/$libName';

  static const String testName = r'$test$';
  static const String testPath = 'test/$testName';

  static const String webName = r'$web$';
  static const String webPath = 'web/$webName';

  static const String packageName = r'$package$';
  static const String packagePath = packageName;

  /// Whether [path] is one of the placeholders.
  static bool isPlaceholderPath(String path) =>
      path == libPath ||
      path == testPath ||
      path == webPath ||
      path == packageName;
}
