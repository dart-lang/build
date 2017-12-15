// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';

final List<Glob> _defaultInclude = new List.unmodifiable([new Glob('**')]);

/// A set of files in a package to use as primary inputs to a `Builder`.
class InputSet {
  /// The package name that the [globs] should be ran on.
  final String package;

  /// Files in [package] that are used as inputs to a builder.
  ///
  /// **NOTE**: If [package] is a package _dependency_, then only files under
  /// `lib` will be available. For the current application package any files can
  /// be listed (such as `bin`, `web`, `tool`, etc).
  final List<Glob> globs;

  /// Files that are excluded when processing [globs].
  final List<Glob> excludes;

  InputSet(this.package, Iterable<String> globs,
      {Iterable<String> excludes: const []})
      : this.globs = globs == null
            ? _defaultInclude
            : new List.unmodifiable(globs.map((pattern) => new Glob(pattern))),
        this.excludes = excludes == null
            ? const []
            : new List.unmodifiable(
                excludes.map((pattern) => new Glob(pattern)));

  /// Returns whether [input] is included in [globs] and not in [excludes].
  bool matches(AssetId input) =>
      package == input.package &&
      globs.any((g) => g.matches(input.path)) &&
      !excludes.any((g) => g.matches(input.path));

  @override
  String toString() {
    var buffer = new StringBuffer()
      ..write('InputSet: package `$package` with globs');
    for (var glob in globs) {
      buffer.write(' `${glob.pattern}`');
    }
    if (excludes.isNotEmpty) {
      buffer.write(' excluding ');
    }
    for (var glob in excludes) {
      buffer.write(' `${glob.pattern}`');
    }
    buffer.writeln('');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InputSet &&
          other.package == package &&
          _deepEquals.equals(_patterns(globs), _patterns(other.globs)) &&
          _deepEquals.equals(_patterns(excludes), _patterns(other.excludes)));

  @override
  int get hashCode =>
      _deepEquals.hash([package, _patterns(globs), _patterns(excludes)]);
}

final _deepEquals = const DeepCollectionEquality();

Iterable<String> _patterns(Iterable<Glob> globs) => globs.map((g) => g.pattern);
