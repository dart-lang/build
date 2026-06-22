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

import '../../build_plan/build_inputs.dart';
import '../asset_content.dart';
import '../builder_filesystem.dart';
import 'asset_ids.dart';

/// The in-memory filesystem that is the analyzer's view of the build.
///
/// Call [startBuild] first to pass a [BuilderFilesystem]. Its callbacks for new
/// content are used to keep the filesystem in sync with the build state.
///
/// During the build, set [phase] to change the phase that the files are viewed
/// at.
class AnalysisDriverFilesystem
    implements UriResolver, ResourceProvider, FileContentCache {
  late BuilderFilesystem _builderFilesystem;

  final Map<String, BuildRunnerFileContent> _data = {};
  final Set<String> _changedPaths = {};
  final Set<String> _changedPathsThisBuild = {};

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

    final plan = _builderFilesystem.buildStepPlan;
    final minPhase = previousPhase < phase ? previousPhase : phase;
    final maxPhase = previousPhase > phase ? previousPhase : phase;
    for (var phase = minPhase; phase != maxPhase; ++phase) {
      for (final step in plan.buildStepsByPhase[phase]) {
        for (final output in plan.declaredOutputsByStep[step]) {
          _changedPaths.add(output.asPath);
        }
      }
    }
  }

  /// Initializes for a build.
  ///
  /// For a clean build, all content will be removed from the filesystem.
  ///
  /// For an incremental build, deleted sources and outputs will be removed
  /// from the filesystem, and updated sources will be evicted or updated.
  void startBuild({
    required BuilderFilesystem builderFilesystem,
    required BuildInputs buildInputs,
  }) {
    _builderFilesystem = builderFilesystem;
    builderFilesystem.listenToContentUpdates(_updateContent);
    _changedPathsThisBuild.clear();

    if (buildInputs.cleanBuild) {
      _phase = 0;
      _changedPaths.addAll(_data.keys);
      _data.clear();
      for (final id in builderFilesystem.buildState.sources) {
        final content = builderFilesystem.buildState.contentOf(id: id);
        if (content != null) {
          _updateContent(id, content);
        }
      }
      return;
    }

    for (final id in buildInputs.deletedSources.followedBy(
      buildInputs.deletedOutputs,
    )) {
      final path = id.asPath;
      if (_data.remove(path) != null) {
        _changedPaths.add(path);
      }
    }
    for (final id in buildInputs.updatedSources) {
      _updateContent(id, builderFilesystem.buildState.contentOfSource(id));
    }
  }

  void _updateContent(AssetId id, AssetContent? content) {
    if (!id.isDart) return;
    if (content == null) {
      // The update is that the file no longer exists.
      final path = id.asPath;
      if (_data.remove(path) != null) {
        _changedPaths.add(path);
      }
      return;
    }
    if (!content.hasContent) {
      // The update is that the file is known to the build but has not been read
      // yet. Do nothing, it will be read before it is used.
      return;
    }
    final phase =
        _builderFilesystem.buildStepPlan
            .stepForDeclaredOutputOrNull(id)
            ?.phaseNumber ??
        -1;
    _writeContent(
      BuildRunnerFileContent(
        path: id.asPath,
        exists: true,
        content: content.dartStringValueOrEmptyFail(id: id),
        contentHash: content.digest.toString(),
        phase: phase,
      ),
    );
  }

  /// Whether [path] exists.
  bool exists(String path) {
    final content = _data[path];
    if (content == null) return false;
    return _phase > content.phase;
  }

  /// Reads the data previously written to [path].
  ///
  /// Throws if ![exists].
  String read(String path) {
    if (!exists(path)) throw StateError('Read of non-existent file.');
    return _data[path]!.content;
  }

  /// Writes [content].
  void _writeContent(BuildRunnerFileContent content) {
    if (!content.exists) throw ArgumentError('content must exist');
    final path = content.path;
    final previousContent = _data[path];
    final isVisible = _phase > content.phase;
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

  /// Paths that were modified by [_writeContent] since the last
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

  final int phase;

  BuildRunnerFileContent({
    required this.path,
    required this.exists,
    required this.content,
    required this.contentHash,
    required this.phase,
  });

  static BuildRunnerFileContent missing(String path) => BuildRunnerFileContent(
    path: path,
    exists: false,
    content: '',
    contentHash: '',
    phase: -1,
  );
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
