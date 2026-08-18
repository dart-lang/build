// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

/// Base interface for all files `build_runner` interacts with.
abstract interface class BuildFile {}

/// An [AssetId] and its location, either in the visible source tree or in the
/// hidden build cache.
class AssetFile implements BuildFile {
  final AssetId id;

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
  final String package;
  final String path;

  const InternalFile(this.package, this.path);

  @override
  int get hashCode => package.hashCode ^ path.hashCode;

  @override
  bool operator ==(Object other) =>
      other is InternalFile && other.package == package && other.path == path;

  @override
  String toString() => 'InternalFile {package: $package, path: $path}';
}
