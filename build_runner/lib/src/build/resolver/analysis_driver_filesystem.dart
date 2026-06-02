// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:build/build.dart' hide Resource;
import 'package:path/path.dart' as p;

import '../library_cycle_graph/phased_value.dart';

/// The in-memory filesystem that is the analyzer's view of the build.
///
/// Source files are added as they're needed during a build. [startBuild]
/// manages how source and generated files are invalidated between builds.
class AnalysisDriverFilesystem
    implements UriResolver, ResourceProvider, FileContentCache {
  final Map<String, PhasedValue<FileContent>> _phasedData = {};
  final Set<String> _changedPaths = {};
  final Set<String> _syncedPathsThisBuild = {};

  int _phase = 0;

  // Methods for use by `AnalysisDriverModel`.

  /// The phase the files are currently viewed at.
  int get phase => _phase;

  /// Sets the phase that the files are viewed at.
  ///
  /// Records changes due to the phase change in [changedPaths].
  set phase(int phase) {
    if (phase == _phase) return;
    final previousPhase = _phase;
    _phase = phase;

    for (final entry in _phasedData.entries) {
      final path = entry.key;
      final phased = entry.value;

      FileContent? prevVal;
      try {
        prevVal = phased.valueAt(phase: previousPhase);
      } catch (_) {}

      FileContent? newVal;
      try {
        newVal = phased.valueAt(phase: phase);
      } catch (_) {}

      if (prevVal?.contentHash != newVal?.contentHash) {
        _changedPaths.add(path);
      }
    }
  }

  /// Initializes a new filesystem that will have files added due to the build.
  ///
  /// If [invalidatedSources] is `null`, this is an initial build and all
  /// cached contents are cleared. Otherwise, only source files matching
  /// [invalidatedSources] are removed.
  void startBuild({
    required Set<AssetId>? invalidatedSources,
  }) {
    _syncedPathsThisBuild.clear();

    if (invalidatedSources == null) {
      _changedPaths.addAll(_phasedData.keys);
      _phasedData.clear();
      return;
    }

    for (final id in invalidatedSources) {
      final path = id.asPath;
      if (_phasedData.remove(path) != null) {
        _changedPaths.add(path);
      }
    }
  }

  /// Whether [path] exists.
  bool exists(String path) {
    final phased = _phasedData[path];
    if (phased == null) return false;
    try {
      final expiring = phased.expiringValueAt(phase: _phase);
      if (expiring.expiresAfter != null) return false;
      return expiring.value.exists;
    } catch (_) {
      return false;
    }
  }

  /// Reads the data previously written to [path].
  ///
  /// Throws if ![exists].
  String read(String path) {
    if (!exists(path)) throw StateError('Read of non-existent file.');
    final phased = _phasedData[path];
    if (phased == null) throw StateError('Read of non-existent file.');
    return phased.valueAt(phase: _phase).content;
  }

  /// Writes [phasedContent]. Returns true if the content was actually updated.
  bool writePhasedContent(String path, PhasedValue<FileContent> phasedContent) {
    final existing = _phasedData[path];

    if (existing != null && _syncedPathsThisBuild.contains(path)) {
      try {
        final existingVal = existing.valueAt(phase: _phase);
        final newVal = phasedContent.valueAt(phase: _phase);
        if (existingVal != newVal) {
          assert(false, 'Conflicting write to $path at phase $_phase: $existingVal vs $newVal');
        }
      } on StateError catch (_) {}
    }

    if (existing != phasedContent) {
      _phasedData[path] = phasedContent;
      _changedPaths.add(path);
      _syncedPathsThisBuild.add(path);
      return true;
    }
    _syncedPathsThisBuild.add(path);
    return false;
  }

  /// Paths that were modified by [writeContent] since the last
  /// call to [clearChangedPaths].
  Iterable<String> get changedPaths => _changedPaths;

  /// Clears [changedPaths].
  void clearChangedPaths() => _changedPaths.clear();

  // `FileContentCache` methods.

  @override
  FileContent get(String path) {
    final phased = _phasedData[path];
    if (phased == null) return BuildRunnerFileContent.missing(path);
    try {
      return phased.valueAt(phase: _phase);
    } catch (_) {
      return BuildRunnerFileContent.missing(path);
    }
  }

  @override
  void invalidate(String path) {
    // build_runner handles invalidation, ignore request to invalidate from the
    // analyzer.
  }

  @override
  void invalidateAll() {
    // build_runner handles invalidation, ignore request to invalidate from the
    // analyzer.
  }

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

class BuildRunnerFileContent implements FileContent {
  @override
  final String path;
  @override
  final bool exists;
  @override
  final String content;
  @override
  final String contentHash;

  BuildRunnerFileContent(
    this.path,
    this.exists,
    this.content,
    this.contentHash,
  );

  static BuildRunnerFileContent missing(String path) =>
      BuildRunnerFileContent(path, false, '', '');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildRunnerFileContent &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          exists == other.exists &&
          content == other.content &&
          contentHash == other.contentHash;

  @override
  int get hashCode =>
      path.hashCode ^
      exists.hashCode ^
      content.hashCode ^
      contentHash.hashCode;

  @override
  String toString() => 'BuildRunnerFileContent(path: $path, exists: $exists, contentHash: $contentHash, content: ${content.length > 50 ? content.substring(0, 50) + "..." : content})';
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

  // `File` methods. These are mostly not used as reads for analysis are via
  // the `FileContentCache` API.
  @override
  Uint8List readAsBytesSync() => utf8.encode(filesystem.read(path));

  @override
  String readAsStringSync() => filesystem.read(path);

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

  // Most `File` and/or `Folder` methods are not needed.

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  // Needs an explicit override to satisfy both `File.copyTo` and
  // `Folder.copyTo`.
  @override
  _Resource copyTo(Folder _) => throw UnimplementedError();
}

extension AssetIdExtensions on AssetId {
  /// Asset path for the in-memory filesystem.
  String get asPath => AnalysisDriverFilesystem.assetPath(this);
}
