// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

import '../asset/reader_writer.dart';
import '../generate/build_directory.dart';
import '../generate/finalized_assets_view.dart';
import '../logging/build_log.dart';
import '../logging/timed_activities.dart';
import '../package_graph/package_graph.dart';
import '../state/filesystem.dart';

/// Pool for async file operations, we don't want to use too many file handles.
final _descriptorPool = Pool(32);

const _manifestName = '.build.manifest';
const _manifestSeparator = '\n';

/// Creates merged output directories for each [OutputLocation].
///
/// Returns whether it succeeded or not.
Future<bool> createMergedOutputDirectories(
  BuiltSet<BuildDirectory> buildDirs,
  PackageGraph packageGraph,
  ReaderWriter reader,
  FinalizedAssetsView finalizedAssetsView,
  bool outputSymlinksOnly,
) async {
  buildLog.doing('Writing the output directory.');
  return await TimedActivity.write.runAsync(() async {
    if (outputSymlinksOnly && reader.filesystem is! IoFilesystem) {
      buildLog.error(
        'The current environment does not support symlinks, but symlinks were '
        'requested.',
      );
      return false;
    }
    final conflictingOutputs = _conflicts(buildDirs);
    if (conflictingOutputs.isNotEmpty) {
      buildLog.error(
        'Unable to create merged directory. '
        'Conflicting outputs for $conflictingOutputs',
      );
      return false;
    }

    for (final target in buildDirs) {
      final outputLocation = target.outputLocation;
      if (outputLocation != null) {
        if (!await _createMergedOutputDir(
          outputLocation.path,
          target.directory,
          packageGraph,
          reader,
          finalizedAssetsView,
          // TODO(grouma) - retrieve symlink information from target only.
          outputSymlinksOnly || outputLocation.useSymlinks,
          outputLocation.hoist,
        )) {
          return false;
        }
      }
    }
    return true;
  });
}

Set<String> _conflicts(BuiltSet<BuildDirectory> buildDirs) {
  final seen = <String>{};
  final conflicts = <String>{};
  final outputLocations = buildDirs.map((d) => d.outputLocation?.path).nonNulls;
  for (final location in outputLocations) {
    if (!seen.add(location)) conflicts.add(location);
  }
  return conflicts;
}

Future<bool> _createMergedOutputDir(
  String outputPath,
  String? root,
  PackageGraph packageGraph,
  ReaderWriter readerWriter,
  FinalizedAssetsView finalizedOutputsView,
  bool symlinkOnly,
  bool hoist,
) async {
  try {
    if (root == null) return false;
    final absoluteRoot = p.join(packageGraph.root.path, root);
    if (absoluteRoot != packageGraph.root.path &&
        !p.isWithin(packageGraph.root.path, absoluteRoot)) {
      buildLog.error(
        'Invalid dir to build `$root`, must be within the package root.',
      );
      return false;
    }
    final outputDir = Directory(outputPath);
    final outputDirExists = await outputDir.exists();
    if (outputDirExists) {
      if (!await _cleanUpOutputDir(outputDir)) return false;
    }
    final builtAssets = finalizedOutputsView.allAssets(rootDir: root).toList();
    if (root != '' &&
        !builtAssets
            .where((id) => id.package == packageGraph.root.name)
            .any((id) => p.isWithin(root, id.path))) {
      buildLog.error('No assets exist in $root, skipping output.');
      return false;
    }

    final outputPaths = <String>[];
    if (!outputDirExists) {
      await outputDir.create(recursive: true);
    }

    outputPaths.addAll(
      await Future.wait([
        for (final id in builtAssets)
          _writeAsset(
            id,
            outputDir,
            root,
            packageGraph,
            readerWriter,
            symlinkOnly,
            hoist,
          ),
        _writeModifiedPackageConfig(
          packageGraph.root.name,
          packageGraph,
          outputDir,
        ),
      ]),
    );

    if (!hoist) {
      for (final dir in _findRootDirs(builtAssets, outputPath)) {
        final link = Link(p.join(outputDir.path, dir, 'packages'));
        if (!link.existsSync()) {
          link.createSync(p.join('..', 'packages'), recursive: true);
        }
      }
    }

    outputPaths.sort();
    final content = outputPaths
        // Normalize path separators for the manifest.
        .map((path) => path.replaceAll(r'\', '/'))
        .join(_manifestSeparator);
    await _writeAsString(outputDir, _manifestName, content);

    return true;
  } on FileSystemException catch (e) {
    if (e.osError?.errorCode != 1314) rethrow;
    final devModeLink =
        'https://docs.microsoft.com/en-us/windows/uwp/get-started/'
        'enable-your-device-for-development';
    buildLog.error(
      'Failed to create merged output directory with symlinks. '
      'To allow creation of symlinks run in a console with admin privileges '
      'or enable developer mode following $devModeLink.',
    );
    return false;
  }
}

/// Creates a modified `.dart_tool/package_config.json` file in [outputDir]
/// based on the current one but with modified root and package uris.
///
/// All `rootUri`s are of the form `packages/<package>` and the `packageUri`
/// is always the empty string. This is because only the lib directory is
/// exposed when using a `packages` directory layout so the root uri and
/// package uri are equivalent.
///
/// All other fields are left as is.
///
/// Returns the relative path that was written to.
Future<String> _writeModifiedPackageConfig(
  String rootPackage,
  PackageGraph packageGraph,
  Directory outputDir,
) async {
  final packageConfig = <String, Object?>{
    'configVersion': 2,
    'packages': [
      for (final package in packageGraph.allPackages.values)
        {
          'name': package.name,
          'rootUri':
              package.name == rootPackage
                  ? '../'
                  : '../packages/${package.name}',
          'packageUri':
              package.name == rootPackage ? 'packages/${package.name}' : '',
          if (package.languageVersion != null)
            'languageVersion': '${package.languageVersion}',
        },
    ],
  };
  final packageConfigPath = '.dart_tool/package_config.json';
  await _writeAsString(outputDir, packageConfigPath, jsonEncode(packageConfig));
  return packageConfigPath;
}

Set<String> _findRootDirs(Iterable<AssetId> allAssets, String outputPath) {
  final rootDirs = <String>{};
  for (final id in allAssets) {
    final parts = p.url.split(id.path);
    if (parts.length == 1) continue;
    final dir = parts.first;
    if (dir == outputPath || dir == 'lib') continue;
    rootDirs.add(parts.first);
  }
  return rootDirs;
}

/// Writes [id] to [outputDir].
///
/// Returns the relative path under [outputDir] that it was written to.
Future<String> _writeAsset(
  AssetId id,
  Directory outputDir,
  String root,
  PackageGraph packageGraph,
  ReaderWriter readerWriter,
  bool symlinkOnly,
  bool hoist,
) {
  return _descriptorPool.withResource(() async {
    String assetPath;
    if (id.path.startsWith('lib/')) {
      assetPath = p.url.join(
        'packages',
        id.package,
        id.path.substring('lib/'.length),
      );
    } else {
      assetPath = id.path;
      assert(id.package == packageGraph.root.name);
      if (hoist && p.isWithin(root, id.path)) {
        assetPath = p.relative(id.path, from: root);
      }
    }

    try {
      if (symlinkOnly) {
        // We assert at the top of `createMergedOutputDirectories` that the
        // reader filesystem is `IoFilesystem`, so symlinks make sense.
        await Link(_filePathFor(outputDir, assetPath)).create(
          readerWriter.assetPathProvider.pathFor(
            readerWriter.generatedAssetHider.maybeHide(
              id,
              packageGraph.root.name,
            ),
          ),
          recursive: true,
        );
      } else {
        await _writeAsBytes(
          outputDir,
          assetPath,
          await readerWriter.readAsBytes(id),
        );
      }
    } on AssetNotFoundException catch (e) {
      if (!p.basename(id.path).startsWith('.')) {
        buildLog.error(
          'Missing asset ${e.assetId}, it may have been deleted during the '
          'build. Please try rebuilding and if you continue to see the '
          'error then file a bug at '
          'https://github.com/dart-lang/build/issues/new.',
        );
        rethrow;
      }
    }
    return assetPath;
  });
}

Future<void> _writeAsBytes(Directory outputDir, String path, List<int> bytes) =>
    _fileFor(outputDir, path).then((file) => file.writeAsBytes(bytes));

Future<void> _writeAsString(
  Directory outputDir,
  String path,
  String contents,
) => _fileFor(outputDir, path).then((file) => file.writeAsString(contents));

Future<File> _fileFor(Directory outputDir, String path) {
  return File(_filePathFor(outputDir, path)).create(recursive: true);
}

String _filePathFor(Directory outputDir, String path) {
  return p.join(outputDir.path, path);
}

/// Checks for a manifest file in [outputDir] and deletes all referenced files.
///
/// Prompts the user with a few options if no manifest file is found.
///
/// Returns whether or not the directory was successfully cleaned up.
Future<bool> _cleanUpOutputDir(Directory outputDir) async {
  final outputPath = outputDir.path;
  final manifestFile = File(p.join(outputPath, _manifestName));
  if (!manifestFile.existsSync()) {
    if (outputDir.listSync(recursive: false).isNotEmpty) {
      buildLog.error(
        'Unable to create merged directory $outputPath. Choose a different '
        'directory or delete the contents of that directory.',
      );
      return false;
    }
  } else {
    final previousOutputs = manifestFile.readAsStringSync().split(
      _manifestSeparator,
    );

    for (final path in previousOutputs) {
      final file = File(p.join(outputPath, path));
      if (file.existsSync()) file.deleteSync();
    }
    _cleanEmptyDirectories(outputPath, previousOutputs);
  }
  return true;
}

/// Deletes all the directories which used to contain any path in
/// [removedFilePaths] if that directory is now empty.
void _cleanEmptyDirectories(
  String outputPath,
  Iterable<String> removedFilePaths,
) {
  for (final directory
      in removedFilePaths
          .map((path) => p.join(outputPath, p.dirname(path)))
          .toSet()) {
    _deleteUp(directory, outputPath);
  }
}

/// Deletes the directory at [from] and and any parent directories which are
/// subdirectories of [to] if they are empty.
void _deleteUp(String from, String to) {
  var directoryPath = from;
  while (p.isWithin(to, directoryPath)) {
    final directory = Directory(directoryPath);
    if (!directory.existsSync() || directory.listSync().isNotEmpty) return;
    directory.deleteSync();
    directoryPath = p.dirname(directoryPath);
  }
}
