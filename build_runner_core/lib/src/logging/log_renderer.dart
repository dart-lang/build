// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';

/// Renders objects to strings for display in logs.
class LogRenderer {
  final String rootPackageName;

  LogRenderer({required this.rootPackageName});

  /// Renders [id].
  ///
  /// Like `AssetId.toString`, except the package name is omitted if it matches
  /// [rootPackageName].
  String id(AssetId id) {
    if (id.package == rootPackageName) {
      return id.path;
    } else {
      return id.toString();
    }
  }

  /// Renders a build action with [input] and [outputs].
  ///
  /// Output names that mostly match [input] are shortened to remove the
  /// duplication.
  ///
  /// Examples: `foo.dart->.g.dart`, `foo.dart->(.g.dart, .other.dart)`
  String build(AssetId input, Iterable<AssetId> outputs) {
    final displayedInput = id(input);
    // If the input ends in `.dart`, take the base name and trim it from all
    // outputs. So for example `foo.dart->foo.g.dart` is shortened to
    // `foo.dart->.g.dart`.
    final trimPrefix =
        displayedInput.endsWith('.dart')
            ? displayedInput.substring(0, displayedInput.length - 5)
            : null;
    final displayedOutputs =
        outputs.length == 1
            ? _trim(id(outputs.first), trimPrefix: trimPrefix)
            : '(${trimmedIds(outputs, trimPrefix: trimPrefix)})';
    return '$displayedInput->$displayedOutputs';
  }

  /// Returns [ids] converted to `String` as a comma-separated list,
  /// with all ids beyond the third replaced by "(# more)".
  ///
  /// If [trimPrefix] is passed, trim the specified prefix from all items where
  /// it matches.
  String trimmedIds(Iterable<AssetId> ids, {String? trimPrefix}) {
    final firstThree = ids
        .map(id)
        .take(3)
        .map((s) => _trim(s, trimPrefix: trimPrefix));
    if (firstThree.length == ids.length) {
      return firstThree.join(', ');
    } else {
      return [...firstThree, '(${ids.length - 3} more)'].join(', ');
    }
  }

  /// Renders [digest].
  ///
  /// Returns `none` for null, or the first seven characters of the digest.
  String digest(Digest? digest) {
    if (digest == null) return 'none';
    var result = digest.toString();
    if (result.length > 7) result = result.substring(0, 7);
    return result;
  }

  /// Returns [string] with [trimPrefix] removed if it matches.
  static String _trim(String string, {String? trimPrefix}) {
    if (trimPrefix == null) return string;
    if (string.startsWith(trimPrefix)) {
      return string.substring(trimPrefix.length);
    }
    return string;
  }
}
