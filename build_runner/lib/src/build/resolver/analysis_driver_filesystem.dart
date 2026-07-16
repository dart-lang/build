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
import 'package:built_collection/built_collection.dart';
import 'package:path/path.dart' as p;

import '../../build_plan/build_inputs.dart';
import '../asset_content.dart';
import '../br_outputs.dart';
import '../builder_filesystem.dart';
import '../shared_part.dart';
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

  final Map<String, GeneratedPartFileContent> _partData = {};

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
    for (var p = minPhase; p != maxPhase; ++p) {
      for (final step in plan.buildStepsByPhase[p]) {
        for (final output in plan.declaredOutputsByStep[step]) {
          _changedPaths.add(output.asPath);
        }
        final partPath = step.primaryInput.brOutputIdForPrimaryInput.asPath;
        if (_partData[partPath]?.hasContributionAt(p) == true) {
          _changedPaths.add(partPath);
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
    builderFilesystem.listenToPartContributions(_updatePartContributions);
    _changedPathsThisBuild.clear();

    if (buildInputs.cleanBuild) {
      _phase = 0;
      _changedPaths.addAll(_data.keys);
      _changedPaths.addAll(_partData.keys);
      _data.clear();
      _partData.clear();
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

    for (final id in buildInputs.deletedSources.followedBy(
      buildInputs.updatedSources,
    )) {
      final partPath = id.brOutputIdForPrimaryInput.asPath;
      if (_partData.remove(partPath) != null) {
        _changedPaths.add(partPath);
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

  void _updatePartContributions(
    AssetId primaryInput,
    int phase,
    AssetContent? imports,
    AssetContent? contribution,
  ) {
    final partPath = primaryInput.brOutputIdForPrimaryInput.asPath;
    final partData = _partData.putIfAbsent(
      partPath,
      () => GeneratedPartFileContent(primaryInput, partPath),
    );
    partData.update(phase, imports, contribution);

    if (_phase > phase) {
      _changedPaths.add(partPath);
    }
    _changedPathsThisBuild.add(partPath);
  }

  /// Whether [path] exists.
  bool exists(String path) {
    final partData = _partData[path];
    if (partData != null && partData.existsAt(_phase)) return true;

    final content = _data[path];
    if (content == null) return false;
    return _phase > content.phase;
  }

  /// Reads the data previously written to [path].
  ///
  /// Throws if ![exists].
  String read(String path) {
    final partData = _partData[path];
    if (partData != null && partData.existsAt(_phase)) {
      return partData.contentAt(_phase);
    }

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
  FileContent get(String path) {
    if (!exists(path)) return BuildRunnerFileContent.missing(path);
    final partData = _partData[path];
    if (partData != null && partData.existsAt(_phase)) {
      return partData.fileContentAt(_phase);
    }
    return _data[path]!;
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

class GeneratedPartFileContent {
  final AssetId primaryInput;
  final String path;
  final Map<int, String> _contributions = {};
  final Map<int, Iterable<String>> _imports = {};

  GeneratedPartFileContent(this.primaryInput, this.path);

  void update(int phase, AssetContent? imports, AssetContent? contribution) {
    if (contribution == null && imports == null) {
      _contributions.remove(phase);
      _imports.remove(phase);
    } else {
      if (contribution != null) {
        _contributions[phase] = contribution.stringValue();
      }
      if (imports != null) {
        _imports[phase] = imports.stringValue().split('\n');
      }
    }
  }

  bool existsAt(int phase) =>
      _contributions.keys.any((p) => phase > p) ||
      _imports.keys.any((p) => phase > p);

  bool hasContributionAt(int phase) =>
      _contributions.containsKey(phase) || _imports.containsKey(phase);

  String contentAt(int phase) {
    final validPhases = <int>{
      ..._contributions.keys.where((p) => phase > p),
      ..._imports.keys.where((p) => phase > p),
    }.toList();
    if (validPhases.isEmpty) {
      throw StateError('Read of non-existent file.');
    }
    validPhases.sort();

    final sharedPart = SharedPart((b) {
      b.primaryInput = primaryInput;
      for (final p in validPhases) {
        if (_imports.containsKey(p)) {
          b.imports[p] = BuiltList<String>(_imports[p]!);
        }
        if (_contributions.containsKey(p)) {
          b.contributions[p] = _contributions[p]!;
        }
      }
    });
    return sharedPart.generateContent(format: false);
  }

  FileContent fileContentAt(int phase) {
    if (!existsAt(phase)) return BuildRunnerFileContent.missing(path);
    final content = contentAt(phase);
    return BuildRunnerFileContent(
      path: path,
      exists: true,
      content: content,
      contentHash: content.hashCode.toString(),
      phase: phase,
    );
  }
}
