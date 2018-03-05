// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';

/// A filter on files to run through a Builder.
abstract class InputMatcher {
  /// Whether [input] is included in this set of assets.
  bool matches(AssetId input);

  factory InputMatcher(InputSet inputSet) = _GlobInputMatcher;
}

class _GlobInputMatcher implements InputMatcher {
  /// The files to include
  ///
  /// Null or empty means include everything.
  final List<Glob> include;

  /// The files within [include] to exclude.
  ///
  /// Null or empty means exclude nothing.
  final List<Glob> exclude;

  _GlobInputMatcher(InputSet inputSet)
      : this.include = inputSet.include?.map((p) => new Glob(p))?.toList(),
        this.exclude = inputSet.exclude?.map((p) => new Glob(p))?.toList();

  @override
  bool matches(AssetId input) => _include(input) && !_exclude(input);

  bool _include(AssetId input) =>
      include == null ||
      include.isEmpty ||
      include.any((g) => g.matches(input.path));

  bool _exclude(AssetId input) =>
      exclude != null &&
      exclude.isNotEmpty &&
      exclude.any((g) => g.matches(input.path));

  @override
  String toString() {
    final result = new StringBuffer();
    if (include == null || include.isEmpty) {
      result.write('any assets');
    } else {
      result.write('assets matching ${_patterns(include).toList()}');
    }
    if (exclude != null && exclude.isNotEmpty) {
      result.write(' except ${_patterns(exclude).toList()}');
    }
    return '$result';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _GlobInputMatcher &&
          _deepEquals.equals(_patterns(include), _patterns(other.include)) &&
          _deepEquals.equals(_patterns(exclude), _patterns(other.exclude)));

  @override
  int get hashCode =>
      _deepEquals.hash([_patterns(include), _patterns(exclude)]);
}

final _deepEquals = const DeepCollectionEquality();

Iterable<String> _patterns(Iterable<Glob> globs) =>
    globs?.map((g) => g.pattern);
