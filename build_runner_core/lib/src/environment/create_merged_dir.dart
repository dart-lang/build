// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

import '../environment/build_environment.dart';
import '../generate/build_directory.dart';
import '../generate/finalized_assets_view.dart';
import '../logging/build_log.dart';
import '../logging/timed_activities.dart';
import '../package_graph/package_graph.dart';

/// Pool for async file operations, we don't want to use too many file handles.
final _descriptorPool = Pool(32);

const _manifestName = '.build.manifest';
const _manifestSeparator = '\n';

/// Creates merged output directories for each [OutputLocation].
///
/// Returns whether it succeeded or not.
Future<bool> createMergedOutputDirectories(
  Set<BuildDirectory> buildDirs,
  PackageGraph packageGraph,
  BuildEnvironment environment,
  AssetReader reader,
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
    var conflictingOutputs = _conflicts(buildDirs);
    if (conflictingOutputs.isNotEmpty) {
      buildLog.error(
        'Unable to create merged directory. '
        'Conflicting outputs for $conflictingOutputs',
      );
      return false;
    }

    for (var target in buildDirs) {
      var outputLocation = target.outputLocation;
      if (outputLocation != null) {
        if (!await _createMergedOutputDir(
          outputLocation.path,
          target.directory,
          packageGraph,
          environment,
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

Set<String> _conflicts(Set<BuildDirectory> buildDirs) {
  final seen = <String>{};
  final conflicts = <String>{};
  var outputLocations = buildDirs.map((d) => d.outputLocation?.path).nonNulls;
  for (var location in outputLocations) {
    if (!seen.add(location)) conflicts.add(location);
  }
  return conflicts;
}

Future<bool> _createMergedOutputDir(
  String outputPath,
  String? root,
  PackageGraph packageGraph,
  BuildEnvironment environment,
  AssetReader reader,
  FinalizedAssetsView finalizedOutputsView,
  bool symlinkOnly,
  bool hoist,
) async {
  try {
    if (root == null) return false;
    var absoluteRoot = p.join(packageGraph.root.path, root);
    if (absoluteRoot != packageGraph.root.path &&
        !p.isWithin(packageGraph.root.path, absoluteRoot)) {
      buildLog.error(
        'Invalid dir to build `$root`, must be within the package root.',
      );
      return false;
    }
    var outputDir = Directory(outputPath);
    var outputDirExists = await outputDir.exists();
    if (outputDirExists) {
      if (!await _cleanUpOutputDir(outputDir, environment)) return false;
    }
    var builtAssets = finalizedOutputsView.allAssets(rootDir: root).toList();
    if (root != '' &&
        !builtAssets
            .where((id) => id.package == packageGraph.root.name)
            .any((id) => p.isWithin(root, id.path))) {
      buildLog.error('No assets exist in $root, skipping output.');
      return false;
    }

    var outputAssets = <AssetId>[];
    if (!outputDirExists) {
      await outputDir.create(recursive: true);
    }

    outputAssets.addAll(
      await Future.wait([
        for (var id in builtAssets)
          _writeAsset(
            id,
            outputDir,
            root,
            packageGraph,
            reader,
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
      for (var dir in _findRootDirs(builtAssets, outputPath)) {
        var link = Link(p.join(outputDir.path, dir, 'packages'));
        if (!link.existsSync()) {
          link.createSync(p.join('..', 'packages'), recursive: true);
        }
      }
    }

    var paths = outputAssets.map((id) => id.path).toList()..sort();
    var content = paths.join(_manifestSeparator);
    await _writeAsString(
      outputDir,
      AssetId(packageGraph.root.name, _manifestName),
      content,
    );

    return true;
  } on FileSystemException catch (e) {
    if (e.osError?.errorCode != 1314) rethrow;
    var devModeLink =
        'https://docs.microsoft.com/en-us/windows/uwp/get-started/'
        'enable-your-device-for-development';
    buildLog.error(
      'Unable to create symlink ${e.path}. Note that to create '
      'symlinks on windows you need to either run in a console with admin '
      'privileges or enable developer mode (see $devModeLink).',
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
Future<AssetId> _writeModifiedPackageConfig(
  String rootPackage,
  PackageGraph packageGraph,
  Directory outputDir,
) async {
  var packageConfig = <String, Object?>{
    'configVersion': 2,
    'packages': [
      for (var package in packageGraph.allPackages.values)
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
  var packageConfigId = AssetId(rootPackage, '.dart_tool/package_config.json');
  await _writeAsString(outputDir, packageConfigId, jsonEncode(packageConfig));
  return packageConfigId;
}

Set<String> _findRootDirs(Iterable<AssetId> allAssets, String outputPath) {
  var rootDirs = <String>{};
  for (var id in allAssets) {
    var parts = p.url.split(id.path);
    if (parts.length == 1) continue;
    var dir = parts.first;
    if (dir == outputPath || dir == 'lib') continue;
    rootDirs.add(parts.first);
  }
  return rootDirs;
}

Future<AssetId> _writeAsset(
  AssetId id,
  Directory outputDir,
  String root,
  PackageGraph packageGraph,
  AssetReader reader,
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

    var outputId = AssetId(packageGraph.root.name, assetPath);
    try {
      if (symlinkOnly) {
        // We assert at the top of `createMergedOutputDirectories` that the
        // reader filesystem is `IoFilesystem`, so symlinks make sense.
        await Link(_filePathFor(outputDir, outputId)).create(
          reader.assetPathProvider.pathFor(
            reader.generatedAssetHider.maybeHide(id, packageGraph.root.name),
          ),
          recursive: true,
        );
      } else {
        await _writeAsBytes(outputDir, outputId, await reader.readAsBytes(id));
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
    return outputId;
  });
}

Future<void> _writeAsBytes(Directory outputDir, AssetId id, List<int> bytes) =>
    _fileFor(outputDir, id).then((file) => file.writeAsBytes(bytes));

Future<void> _writeAsString(Directory outputDir, AssetId id, String contents) =>
    _fileFor(outputDir, id).then((file) => file.writeAsString(contents));

Future<File> _fileFor(Directory outputDir, AssetId id) {
  return File(_filePathFor(outputDir, id)).create(recursive: true);
}

String _filePathFor(Directory outputDir, AssetId id) {
  String relativePath;
  if (id.path.startsWith('lib')) {
    relativePath = p.join(
      'packages',
      id.package,
      p.joinAll(p.url.split(id.path).skip(1)),
    );
  } else {
    relativePath = id.path;
  }
  return p.join(outputDir.path, relativePath);
}

/// Checks for a manifest file in [outputDir] and deletes all referenced files.
///
/// Prompts the user with a few options if no manifest file is found.
///
/// Returns whether or not the directory was successfully cleaned up.
Future<bool> _cleanUpOutputDir(
  Directory outputDir,
  BuildEnvironment environment,
) async {
  var outputPath = outputDir.path;
  var manifestFile = File(p.join(outputPath, _manifestName));
  if (!manifestFile.existsSync()) {
    if (outputDir.listSync(recursive: false).isNotEmpty) {
      var choices = [
        'Leave the directory unchanged and skip writing the build output',
        'Delete the directory and all contents',
        'Leave the directory in place and write over any existing files',
      ];
      int choice;
      try {
        choice = await environment.prompt(
          'Found existing directory `$outputPath` but no manifest file.\n'
          'Please choose one of the following options:',
          choices,
        );
      } on NonInteractiveBuildException catch (_) {
        buildLog.error(
          'Unable to create merged directory $outputPath. Choose a different '
          'directory or delete the contents of that directory.',
        );
        return false;
      }
      switch (choice) {
        case 0:
          return false;
        case 1:
          try {
            outputDir.deleteSync(recursive: true);
          } catch (e) {
            buildLog.error(
              'Failed to delete output dir at `$outputPath` with error:\n\n'
              '$e',
            );
            return false;
          }
          // Actually recreate the directory, but as an empty one.
          outputDir.createSync();
          break;
        case 2:
          // Just do nothing here, we overwrite files by default.
          break;
      }
    }
  } else {
    var previousOutputs = manifestFile.readAsStringSync().split(
      _manifestSeparator,
    );

    for (var path in previousOutputs) {
      var file = File(p.join(outputPath, path));
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
  for (var directory
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
    var directory = Directory(directoryPath);
    if (!directory.existsSync() || directory.listSync().isNotEmpty) return;
    directory.deleteSync();
    directoryPath = p.dirname(directoryPath);
  }
}
