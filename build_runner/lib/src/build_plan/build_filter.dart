// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

/// Describes a set of files that should be built.
class BuildFilter {
  /// The package name glob that files must live under in order to match.
  final Glob _package;

  /// A glob for files under [_package] that must match.
  final Glob _path;

  BuildFilter(this._package, this._path);

  /// Builds a [BuildFilter] from a command line argument.
  ///
  /// Both relative paths and package: uris are supported. Relative
  /// paths are treated as relative to the [currentPackage], if set.
  ///
  /// Globs are supported in package names and paths.
  factory BuildFilter.fromArg(String arg, String? currentPackage) {
    final uri = Uri.parse(arg);
    if (uri.scheme == 'package') {
      final package = uri.pathSegments.first;
      final glob = Glob(p.url.joinAll(['lib', ...uri.pathSegments.skip(1)]));
      return BuildFilter(Glob(package), glob);
    } else if (uri.scheme.isEmpty) {
      if (currentPackage == null) {
        throw FormatException(
          'No current package so relative path is not supported: $arg',
        );
      } else {
        return BuildFilter(Glob(currentPackage), Glob(uri.path));
      }
    } else {
      throw FormatException('Unsupported scheme ${uri.scheme}', uri);
    }
  }

  /// Returns whether or not [id] mathes this filter.
  bool matches(AssetId id) =>
      _package.matches(id.package) && _path.matches(id.path);

  @override
  int get hashCode => Object.hash(
    _package.context,
    _package.pattern,
    _package.recursive,
    _path.context,
    _path.pattern,
    _path.recursive,
  );

  @override
  bool operator ==(Object other) =>
      other is BuildFilter &&
      other._path.context == _path.context &&
      other._path.pattern == _path.pattern &&
      other._path.recursive == _path.recursive &&
      other._package.context == _package.context &&
      other._package.pattern == _package.pattern &&
      other._package.recursive == _package.recursive;
}
