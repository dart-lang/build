// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import 'package:glob/glob.dart';
import 'package:meta/meta.dart';

/// Indexes build files by package for fast glob matching and file lookup.
///
/// Used both during the build and by `BuildOutputReader`.
class BuildFileIndex {
  final Iterable<AssetId> _files;

  /// Sorted files by package, or null if not yet computed.
  Map<String, List<AssetId>>? _sortedFileIdsByPackage;

  BuildFileIndex(Iterable<AssetId> files) : _files = files;

  /// All IDs in `package` that refer to files and match.
  ///
  /// If [glob] is passed, return only IDs for which the glob matches the path.
  Iterable<AssetId> findFiles(String package, {Glob? glob}) {
    _sortedFileIdsByPackage ??= _computeSortedFileIdsByPackage();
    final list = _sortedFileIdsByPackage![package];
    if (list == null) return const [];
    if (glob == null) return list;

    final simplePrefix = simpleGlobPrefix(glob);
    Iterable<AssetId> result = list;
    if (simplePrefix.isNotEmpty) {
      result = list.filterToPrefix(simplePrefix);
    }

    return result.where((id) => glob.matches(id.path));
  }

  /// Computes a `Map` from package names to sorted IDs of files in the package.
  Map<String, List<AssetId>> _computeSortedFileIdsByPackage() {
    final result = <String, List<AssetId>>{};
    for (final id in _files) {
      result.putIfAbsent(id.package, () => []).add(id);
    }
    for (final value in result.values) {
      value.sort();
    }
    return result;
  }
}

/// Extension on `List<AssetId>` that assumes the list is sorted so it can do a
/// binary search.
extension ListOfAssetIdsExtension on List<AssetId> {
  /// IDs in the list filtered to path prefix [prefix].
  Iterable<AssetId> filterToPrefix(String prefix) {
    return fromFirstWithPrefix(
      prefix,
    ).takeWhile((id) => id.path.startsWith(prefix));
  }

  /// IDs in the list starting from the first with path prefix [prefix].
  @visibleForTesting
  Iterable<AssetId> fromFirstWithPrefix(String prefix) {
    final fromIndex = findFirstWithPrefix(prefix);
    return fromIndex == -1 ? const [] : getRange(fromIndex, length);
  }

  /// Index of the first ID in the list with path prefix [prefix], or -1 if
  /// there is no matching ID.
  @visibleForTesting
  int findFirstWithPrefix(String prefix) {
    var min = 0;
    var max = length;
    while (min < max) {
      final mid = (min + max) ~/ 2;
      if (this[mid].path.compareTo(prefix) >= 0) {
        max = mid;
      } else {
        min = mid + 1;
      }
    }
    if (min >= length || !this[min].path.startsWith(prefix)) return -1;
    return min;
  }
}

/// The prefix of the [glob] pattern up to but not including the first special
/// character.
@visibleForTesting
String simpleGlobPrefix(Glob glob) {
  final pattern = glob.pattern;
  for (var i = 0; i != pattern.length; ++i) {
    final codeUnit = pattern.codeUnitAt(i);

    /// Code units signalling the start of non-literal content in a glob
    /// pattern, see: https://pub.dev/packages/glob
    if (codeUnit == $STAR ||
        codeUnit == $QUESTION ||
        codeUnit == $OPEN_SQUARE_BRACKET ||
        codeUnit == $BACKSLASH ||
        codeUnit == $OPEN_CURLY_BRACKET) {
      return pattern.substring(0, i);
    }
  }
  return pattern;
}

// Constants copied from `fe_analyzer_shared`.
// ignore_for_file: constant_identifier_names
const int $STAR = 42;
const int $QUESTION = 63;
const int $OPEN_SQUARE_BRACKET = 91;
const int $BACKSLASH = 92;
const int $OPEN_CURLY_BRACKET = 123;
