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
// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:build/build.dart' hide Resource;
import 'package:path/path.dart' as p;

import '../asset_graph/node.dart';

/// The in-memory filesystem that is the analyzer's view of the build.
///
/// Pass an `Iterable<AssetNode>` of generated file nodes to [startBuild] at the
/// start of a build. This tells the filesystem at what phase each generated
/// file becomes visible.
///
/// During the build, set [phase] to change the phase that the files are viewed
/// at.
///
/// Source files are added as they're needed during a build. [startBuild]
/// manages how source and generated files are invalidated between builds.
class AnalysisDriverFilesystem
    implements UriResolver, ResourceProvider, FileContentCache {
  final Map<String, FileContent> _data = {};
  final Set<String> _changedPaths = {};
  final Set<String> _changedPathsThisBuild = {};

  // Path and phase information derived from the `Iterable<AssetNode>` for fast
  // lookup.
  Map<String, int> _phaseByPath = {};
  Map<int, List<String>> _pathByPhase = {};

  int _phase = 0;

  // Methods for use by `AnalysisDriverModel`.

  /// The phase the files are currently viewed at.
  int get phase => _phase;

  /// Sets the phase that the files are viewed at.
  ///
  /// A generated file is only visible if it was generated at an earlier phase.
  ///
  /// Records changes due to the phase change in [changedPaths].
  set phase(int phase) {
    if (phase == _phase) return;
    final previousPhase = _phase;
    _phase = phase;

    for (final entry in _pathByPhase.entries) {
      final previouslyWasVisible = previousPhase > entry.key;
      final isVisible = phase > entry.key;

      if (previouslyWasVisible != isVisible) {
        _changedPaths.addAll(entry.value);
      }
    }
  }

  /// Initializes a new filesystem that will have files added due to the
  /// build described by [generatedNodes].
  ///
  /// If [invalidatedSources] is `null`, this is an initial build and all
  /// cached contents are cleared. Otherwise, only source files matching
  /// [invalidatedSources] are removed.
  void startBuild(
    Iterable<AssetNode> generatedNodes, {
    required Set<AssetId>? invalidatedSources,
  }) {
    final previousPhaseByPath = _phaseByPath;
    _phaseByPath = <String, int>{};
    _pathByPhase = <int, List<String>>{};
    for (final node in generatedNodes) {
      final phase = node.generatedNodeConfiguration!.phaseNumber;
      final idAsPath = node.id.asPath;
      _phaseByPath[idAsPath] = phase;
      _pathByPhase.putIfAbsent(phase, () => []).add(idAsPath);
    }

    _changedPathsThisBuild.clear();

    if (invalidatedSources == null) {
      _changedPaths.addAll(_data.keys);
      _data.clear();
      return;
    }

    for (final id in invalidatedSources) {
      final path = id.asPath;
      if (_data.remove(path) != null) {
        _changedPaths.add(path);
      }
    }

    for (final entry in previousPhaseByPath.entries) {
      final path = entry.key;
      final previousPhase = entry.value;
      final nextPhase = _phaseByPath[path];
      if (nextPhase == null) {
        if (_data.remove(path) != null && _phase > previousPhase) {
          _changedPaths.add(path);
        }
        continue;
      }
      if (nextPhase == previousPhase || !_data.containsKey(path)) {
        continue;
      }
      final previouslyWasVisible = _phase > previousPhase;
      final isVisible = _phase > nextPhase;
      if (previouslyWasVisible != isVisible) {
        _changedPaths.add(path);
      }
    }
  }

  /// Returns the phase of the generated file at [path] or `-1` if it's not a
  /// generated file or not known.
  int _phaseOf(String path) => _phaseByPath[path] ?? -1;

  /// Whether [path] exists.
  bool exists(String path) =>
      _data.containsKey(path) && _phase > _phaseOf(path);

  /// Reads the data previously written to [path].
  ///
  /// Throws if ![exists].
  String read(String path) {
    if (path.contains('/sdk/') || path.contains('/dart-sdk/')) {
      return io.File(path).readAsStringSync();
    }
    if (!exists(path)) throw StateError('Read of non-existent file.');
    return _data[path]!.content;
    }
    final result = _data[path];
    if (result == null) throw ArgumentError('Path does not exist: $path');
    return result;
  }
  }

  /// Writes [content].
  void writeContent(BuildRunnerFileContent content) {
    if (!content.exists) throw ArgumentError('content must exist');
    final path = content.path;
    final previousContent = _data[path];
    final isVisible = _phase > _phaseOf(path);
    if (previousContent != null &&
        content.contentHash == previousContent.contentHash) {
      return;
    }

    _data[path] = content;
    if (isVisible) {
      _changedPaths.add(path);
    }
    assert(_changedPathsThisBuild.add(path), path);
  }

  /// Paths that were modified by [writeContent] since the last
  /// call to [clearChangedPaths].
  Iterable<String> get changedPaths => _changedPaths;

  /// Clears [changedPaths].
  void clearChangedPaths() => _changedPaths.clear();

  // `FileContentCache` methods.

  @override
  FileContent get(String path) =>
      exists(path) ? _data[path]! : BuildRunnerFileContent.missing(path);

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
  
  // `File` methods. These are mostly not used as reads for analysis are via
  // the `FileContentCache` API.

  @override
  Uint8List readAsBytesSync() => utf8.encode(filesystem.read(path));

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

extension AssetIdExtensions on AssetId {
  /// Asset path for the in-memory filesystem.
  String get asPath => AnalysisDriverFilesystem.assetPath(this);
}
