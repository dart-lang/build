// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

/// A file in a `build_runner` build.
class AssetId implements Comparable<AssetId> {
  /// The package containing the file.
  final String package;

  /// The relative path of the file under the root of [package].
  ///
  /// The path is relative and contains no parent references `..`, guaranteeing
  /// that it is under [package].
  ///
  /// The path segment separator is `/` on all platforms.
  final String path;

  /// The segments of [path].
  List<String> get pathSegments => p.url.split(path);

  /// The file extension of [path]: the portion of its "basename" from the last
  /// `.` to the end, including the `.` itself.
  String get extension => p.extension(path);

  /// An [AssetId] with the specified [path] under [package].
  ///
  /// The [path] must be relative and under [package], or an [ArgumentError] is
  /// thrown.
  ///
  /// The [path] is normalized: `\` is replaced with `/`, then `.` and `..` are removed.
  AssetId(this.package, String path) : path = _normalizePath(path);

  /// Creates an [AssetId] from a [uri].
  ///
  /// The [uri] can be relative, in which case it will be resolved relative to
  /// [from]; if [uri] is relative and [from] is not specified, an
  /// [ArgumentError] is thrown.
  ///
  /// Or, [uri] can have the scheme `package` or `asset`.
  ///
  /// A `package` [uri] has the form `package:$package/$path` and references
  /// the specified path within the `lib/` directory of the specified package, just like
  /// a `package` URI in Dart source code.
  ///
  /// An `asset` [uri] has the form `asset:$package/$path` and references the
  /// specified path within the root of the specified package.
  ///
  /// If [uri] has any other scheme then [UnsupportedError] is thrown.
  factory AssetId.resolve(Uri uri, {AssetId? from}) {
    if (from == null && !uri.hasScheme) {
      throw ArgumentError.value(
        from,
        'from',
        'An AssetId `from` must be specified to resolve a relative URI.',
      );
    }
    final resolved = uri.hasScheme ? uri : from!.uri.resolveUri(uri);
    if (resolved.scheme == 'package') {
      return AssetId(
        resolved.pathSegments.first,
        p.url.join('lib', p.url.joinAll(resolved.pathSegments.skip(1))),
      );
    } else if (resolved.scheme == 'asset') {
      return AssetId(
        resolved.pathSegments.first,
        p.url.joinAll(resolved.pathSegments.skip(1)),
      );
    }
    throw UnsupportedError(
      'Cannot resolve $uri; only "package" and "asset" schemes supported.',
    );
  }

  /// Parses an [AssetId] string of the form `$package|$path`.
  ///
  /// If [id] does not match that form, a [FormatException] is thrown.
  ///
  /// See [AssetId.new] for restrictions on `path` and how it will be
  /// normalized.
  factory AssetId.parse(String id) {
    final parts = id.split('|');
    if (parts.length != 2) {
      throw FormatException('Could not parse "$id".');
    }

    return AssetId(parts[0], parts[1]);
  }

  /// If [path] starts with `lib/`, the URI starting `package:` that refers to this asset.
  ///
  /// If not, the URI `asset:$package/$path`.
  late final Uri uri = _constructUri(this);

  /// Returns an [AssetId] in [package] with path `$path$exension`.
  AssetId addExtension(String extension) => AssetId(package, '$path$extension');

  /// Returns an [AssetId] in [package] with [extension] removed and
  /// [newExtension] appended.
  AssetId changeExtension(String newExtension) =>
      AssetId(package, p.withoutExtension(path) + newExtension);

  /// Deserializes a `List<dynamic>` from [serialize].
  AssetId.deserialize(List<dynamic> serialized)
    : package = serialized[0] as String,
      path = serialized[1] as String;

  /// Serializes this [AssetId] to an `Object` that can be sent across isolates.
  ///
  /// See [AssetId.deserialize].
  Object serialize() => [package, path];

  @override
  bool operator ==(Object other) =>
      other is AssetId && package == other.package && path == other.path;

  @override
  int get hashCode => package.hashCode ^ path.hashCode;

  @override
  int compareTo(AssetId other) {
    final packageComp = package.compareTo(other.package);
    if (packageComp != 0) return packageComp;
    return path.compareTo(other.path);
  }

  /// Returns `$package|$path`, which can be converted back to an `AssetId`
  /// using [AssetId.parse].
  @override
  String toString() => '$package|$path';
}

String _normalizePath(String path) {
  if (p.isAbsolute(path)) {
    throw ArgumentError.value(path, 'Asset paths must be relative.');
  }
  path = path.replaceAll(r'\', '/');

  // Collapse "." and "..".
  final result = p.posix.normalize(path);
  if (result.startsWith('../')) {
    throw ArgumentError.value(
      path,
      'Asset paths must be within the specified the package.',
    );
  }
  return result;
}

Uri _constructUri(AssetId id) {
  final originalSegments = id.pathSegments;
  final isLib = originalSegments.first == 'lib';
  final scheme = isLib ? 'package' : 'asset';
  final pathSegments = isLib ? originalSegments.skip(1) : originalSegments;
  return Uri(scheme: scheme, pathSegments: [id.package, ...pathSegments]);
}
