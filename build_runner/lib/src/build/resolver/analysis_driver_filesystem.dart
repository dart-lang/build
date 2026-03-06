// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:build/build.dart' hide Resource;
import 'package:path/path.dart' as p;

/// The in-memory filesystem that is the analyzer's view of the build.
///
/// Tracks modified paths, which should be passed to
/// `AnalysisDriver.changeFile` to update the analyzer state.
class AnalysisDriverFilesystem implements UriResolver, ResourceProvider {
  final Map<String, String> _data = {};
  final Set<String> _changedPaths = {};

  // Methods for use by `AnalysisDriverModel`.

  /// Whether [path] exists.
  bool exists(String path) => _data.containsKey(path);

  /// Reads the data previously written to [path].
  ///
  /// Throws if ![exists].
  String read(String path) {
    if (path.contains('/sdk/') || path.contains('/dart-sdk/')) {
      return io.File(path).readAsStringSync();
    }
    final result = _data[path];
    if (result == null) throw ArgumentError('Path does not exist: $path');
    return result;
  }

  /// Deletes the data previously written to [path].
  ///
  /// Records the change in [changedPaths].
  ///
  /// Or, if it's missing, does nothing.
  void deleteFile(String path) {
    if (_data.remove(path) != null) _changedPaths.add(path);
  }

  /// Writes [content] to [path].
  ///
  /// Records the change in [changedPaths], only if the content actually
  /// changed.
  void writeFile(String path, String content) {
    final oldContent = _data[path];
    _data[path] = content;
    if (content != oldContent) _changedPaths.add(path);
  }

  /// Paths that were modified by [deleteFile] or [writeFile] since the last
  /// call to [clearChangedPaths].
  Iterable<String> get changedPaths => _changedPaths;

  /// Clears [changedPaths].
  void clearChangedPaths() => _changedPaths.clear();

  // `UriResolver` methods.

  /// Converts [path] to [Uri].
  ///
  /// [path] must be absolute and matches one of two formats:
  ///
  /// ```
  /// /<package>/lib/<rest> --> package:<package>/<rest>
  /// /<package>/<rest> --> asset:<package>/<rest>
  /// ```
  @override
  Uri pathToUri(String path) {
    if (!path.startsWith('/')) {
      throw ArgumentError.value('path', path, 'Must start with "/". ');
    }
    final pathSegments = path.split('/');
    // First segment is empty because of the starting `/`.
    final packageName = pathSegments[1];
    if (pathSegments[2] == 'lib') {
      return Uri(
        scheme: 'package',
        pathSegments: [packageName].followedBy(pathSegments.skip(3)),
      );
    } else {
      return Uri(
        scheme: 'asset',
        pathSegments: [packageName].followedBy(pathSegments.skip(2)),
      );
    }
  }

  @override
  Source? resolveAbsolute(Uri uri, [Uri? actualUri]) {
    final assetId = parseAsset(uri);
    if (assetId == null) return null;

    final file = getFile(assetPath(assetId));
    return FileSource(file, assetId.uri);
  }

  /// Path of [assetId] for the in-memory filesystem.
  static String assetPath(AssetId assetId) =>
      '/${assetId.package}/${assetId.path}';

  /// Path of the asset with [package] and [path] for the in-memory filesystem.
  static String assetPathFor({required String package, required String path}) =>
      '/$package/$path';

  /// Attempts to parse [uri] into an [AssetId].
  ///
  /// Handles 'package:' or 'asset:' URIs, as well as 'file:' URIs that have the
  /// same pattern used by [assetPath].
  ///
  /// Returns null if the Uri cannot be parsed.
  static AssetId? parseAsset(Uri uri) {
    if (uri.isScheme('package') || uri.isScheme('asset')) {
      return AssetId.resolve(uri);
    }
    if (uri.isScheme('file')) {
      if (!uri.path.startsWith('/')) {
        throw ArgumentError.value(
          'uri.path',
          uri.path,
          'Must start with "/". ',
        );
      }
      final parts = uri.path.split('/');
      // First part is empty because of the starting `/`, second is package,
      // remainder is path in package.
      return AssetId(parts[1], parts.skip(2).join('/'));
    }
    return null;
  }

  // `ResourceProvider` methods.

  @override
  p.Context get pathContext => p.posix;

  @override
  File getFile(String path) => _Resource(this, path);

  @override
  Folder getFolder(String path) => _Resource(this, path);

  // `ResourceProvider` methods that are not needed.

  @override
  Link getLink(String path) => throw UnimplementedError();

  @override
  Resource getResource(String path) => throw UnimplementedError();

  @override
  Folder? getStateLocation(String pluginId) => throw UnimplementedError();
}

/// Minimal implementation of [File] and [Folder].
///
/// Provides only what the analyzer actually uses during analysis.
class _Resource implements File, Folder {
  final AnalysisDriverFilesystem filesystem;
  @override
  final String path;

  _Resource(this.filesystem, this.path);

  // `File` and `Folder` methods.

  @override
  bool get exists => filesystem.exists(path);

  @override
  String get shortName => filesystem.pathContext.basename(path);

  @override
  Folder get parent => _Resource(filesystem, p.dirname(path));

  // `File` methods.
  @override
  Uint8List readAsBytesSync() {
    // TODO(davidmorgan): the analyzer reads as bytes in `FileContentCache`
    // then converts back to `String` and hashes. It should be possible to save
    // that work, for example by injecting a custom `FileContentCache`.
    return utf8.encode(filesystem.read(path));
  }

  @override
  String readAsStringSync() => filesystem.read(path);

  @override
  String canonicalizePath(String path) => path;

  // Analyzer methods such as `CompilationUnitElement.source` provide access to
  // source and return a `TimestampedData` with this value.
  //
  // `build_runner` explicitly notifies the analyzer of changes, so it's not
  // needed for analysis; and generators should not try to determine which files
  // were modified since the last run. So, just return zero.
  @override
  int get modificationStamp => 0;

  // `Folder` methods.

  @override
  bool contains(String path) =>
      filesystem.pathContext.isWithin(this.path, path);

  @override
  File getChildAssumingFile(String relPath) =>
      _Resource(filesystem, '$path/$relPath');

  @override
  Folder getChildAssumingFolder(String relPath) =>
      _Resource(filesystem, '$path/$relPath');

  // Most `File` and/or `Folder` methods are not needed.

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  // Needs an explicit override to satisfy both `File.copyTo` and
  // `Folder.copyTo`.
  @override
  _Resource copyTo(Folder _) => throw UnimplementedError();
}
