// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import 'package:path/path.dart' as p;

import 'constants.dart';

/// Base interface for all files `build_runner` interacts with.
abstract interface class BuildFile {
  String get package;
  String get path;
}

/// An [AssetId] and its location, either in the visible source tree or in the
/// hidden build cache.
class AssetFile implements BuildFile {
  final AssetId id;

  @override
  String get package => id.package;

  @override
  String get path => id.path;

  /// Whether the asset is in the hidden build cache instead of the source tree.
  final bool hidden;

  const AssetFile(this.id, {required this.hidden});

  /// An asset in the visible source tree.
  const AssetFile.source(this.id) : hidden = false;

  /// An asset in the hidden build cache.
  const AssetFile.cache(this.id) : hidden = true;

  @override
  int get hashCode => id.hashCode ^ hidden.hashCode;

  @override
  bool operator ==(Object other) =>
      other is AssetFile && other.id == id && other.hidden == hidden;

  @override
  String toString() => 'AssetFile {id: $id, hidden: $hidden}';
}

/// An internal non-asset file under `.dart_tool`, such as
/// `.dart_tool/package_config.json` or `.dart_tool/build/asset_graph.json`.
class InternalFile implements BuildFile {
  @override
  final String package;
  @override
  final String path;

  InternalFile(this.package, this.path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath != '.dart_tool' && !lowerPath.startsWith('.dart_tool/')) {
      throw ArgumentError.value(
        path,
        'path',
        'InternalFile path must be under .dart_tool.',
      );
    }
    if (lowerPath.startsWith('${generatedOutputDirectory.toLowerCase()}/')) {
      throw ArgumentError.value(
        path,
        'path',
        'InternalFile path must not be under the build cache '
            '$generatedOutputDirectory.',
      );
    }
    if (p.isAbsolute(path) || p.posix.normalize(path) != path) {
      throw ArgumentError.value(
        path,
        'path',
        'InternalFile path must be a normalized relative path.',
      );
    }
  }

  @override
  int get hashCode => package.hashCode ^ path.hashCode;

  @override
  bool operator ==(Object other) =>
      other is InternalFile && other.package == package && other.path == path;

  @override
  String toString() => 'InternalFile {package: $package, path: $path}';
}
