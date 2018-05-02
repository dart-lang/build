// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../asset_graph/optional_output_tracker.dart';
import '../environment/build_environment.dart';
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';

final _logger = new Logger('CreateOutputDir');
const _manifestName = '.build.manifest';
const _manifestSeparator = '\n';

/// Creates merged output directories for each value in [outputMap].
///
/// Returns whether it succeeded or not.
Future<bool> createMergedOutputDirectories(
    Map<String, String> outputMap,
    AssetGraph assetGraph,
    PackageGraph packageGraph,
    AssetReader reader,
    BuildEnvironment environment,
    OptionalOutputTracker optionalOutputTracker) async {
  for (var output in outputMap.keys) {
    if (!await _createMergedOutputDir(output, outputMap[output], assetGraph,
        packageGraph, reader, environment, optionalOutputTracker)) {
      _logger.severe('Unable to create merged directory for $output.\n'
          'Choose a different directory or delete the contents of that '
          'directory.');
      return false;
    }
  }
  return true;
}

Future<bool> _createMergedOutputDir(
  String outputPath,
  String root,
  AssetGraph assetGraph,
  PackageGraph packageGraph,
  AssetReader reader,
  BuildEnvironment environment,
  OptionalOutputTracker optionalOutputTracker,
) async {
  var outputDir = new Directory(outputPath);
  var outputDirExists = await outputDir.exists();
  if (outputDirExists) {
    var result = await _cleanUpOutputDir(outputDir, environment);
    if (!result) return result;
  }

  var outputAssets = new Set<AssetId>();
  var originalOutputAssets = new Set<AssetId>();

  await logTimedAsync(_logger, 'Creating merged output dir `$outputPath`',
      () async {
    if (!outputDirExists) {
      await outputDir.create(recursive: true);
    }

    for (var node in assetGraph.allNodes) {
      if (_shouldSkipNode(node, root, optionalOutputTracker)) {
        continue;
      }
      originalOutputAssets.add(node.id);
      node.lastKnownDigest ??= await reader.digest(node.id);
      outputAssets.add(
          await _writeAsset(node.id, outputDir, root, packageGraph, reader));
    }

    var packagesFileContent = packageGraph.allPackages.keys
        .map((p) => '$p:packages/$p/')
        .join('\r\n');
    var packagesAsset = new AssetId(packageGraph.root.name, '.packages');
    _writeAsString(outputDir, packagesAsset, packagesFileContent);
    outputAssets.add(packagesAsset);

    if (root == null) {
      for (var dir in _findRootDirs(
          outputPath, assetGraph, packageGraph, optionalOutputTracker)) {
        var link = new Link(p.join(outputDir.path, dir, 'packages'));
        if (!link.existsSync()) {
          link.createSync(p.join('..', 'packages'), recursive: true);
        }
      }
    }
  });

  logTimedSync(_logger, 'Writing asset manifest', () {
    var paths = outputAssets.map((id) => id.path).toList()..sort();
    var content = paths.join(_manifestSeparator);
    _writeAsString(
        outputDir, new AssetId(packageGraph.root.name, _manifestName), content);
  });

  return true;
}

Set<String> _findRootDirs(String outputPath, AssetGraph assetGraph,
    PackageGraph packageGraph, OptionalOutputTracker optionalOutputTracker) {
  var rootDirs = new Set<String>();
  for (var node in assetGraph.packageNodes(packageGraph.root.name)) {
    if (_shouldSkipNode(node, null, optionalOutputTracker)) {
      continue;
    }
    var parts = p.url.split(node.id.path);
    if (parts.length == 1) continue;
    var dir = parts.first;
    if (dir == outputPath || dir == 'lib') continue;
    rootDirs.add(parts.first);
  }
  return rootDirs;
}

bool _shouldSkipNode(
    AssetNode node, String root, OptionalOutputTracker optionalOutputTracker) {
  if (!node.isReadable) return true;
  if (node.isDeleted) return true;
  if (root != null &&
      !(node.id.path.startsWith('lib/')) &&
      !p.isWithin(root, node.id.path)) {
    return true;
  }
  if (node is InternalAssetNode) return true;
  if (node is GeneratedAssetNode) {
    if (!node.wasOutput ||
        node.isFailure ||
        node.state != GeneratedNodeState.upToDate) {
      return true;
    }
    return !optionalOutputTracker.isRequired(node.id);
  }
  if (node.id.path == '.packages') return true;
  return false;
}

Future<AssetId> _writeAsset(AssetId id, Directory outputDir, String root,
    PackageGraph packageGraph, AssetReader reader) async {
  String assetPath;
  if (id.path.startsWith('lib/')) {
    assetPath =
        p.url.join('packages', id.package, id.path.substring('lib/'.length));
  } else {
    assetPath = id.path;
    assert(id.package == packageGraph.root.name);
    if (root != null && p.isWithin(root, id.path)) {
      assetPath = p.relative(id.path, from: root);
    }
  }

  var outputId = new AssetId(packageGraph.root.name, assetPath);
  try {
    _writeAsBytes(outputDir, outputId, await reader.readAsBytes(id));
  } on AssetNotFoundException catch (e, __) {
    if (p.basename(id.path).startsWith('.')) {
      _logger.fine('Skipping missing hidden file ${id.path}');
    } else {
      _logger.severe(
          'Missing asset ${e.assetId}, it may have been deleted during the '
          'build. Please try rebuilding and if you continue to see the '
          'error then file a bug at '
          'https://github.com/dart-lang/build/issues/new.');
      rethrow;
    }
  }
  return outputId;
}

void _writeAsBytes(Directory outputDir, AssetId id, List<int> bytes) {
  var file = _fileFor(outputDir, id);
  file.writeAsBytesSync(bytes);
}

void _writeAsString(Directory outputDir, AssetId id, String contents) {
  var file = _fileFor(outputDir, id);
  file.writeAsStringSync(contents);
}

File _fileFor(Directory outputDir, AssetId id) {
  String relativePath;
  if (id.path.startsWith('lib')) {
    relativePath =
        p.join('packages', id.package, p.joinAll(p.url.split(id.path).skip(1)));
  } else {
    relativePath = id.path;
  }
  var file = new File(p.join(outputDir.path, relativePath));
  file.createSync(recursive: true);
  return file;
}

/// Checks for a manifest file in [outputDir] and deletes all referenced files.
///
/// Prompts the user with a few options if no manifest file is found.
///
/// Returns whether or not the directory was successfully cleaned up.
Future<bool> _cleanUpOutputDir(
    Directory outputDir, BuildEnvironment environment) async {
  var outputPath = outputDir.path;
  var manifestFile = new File(p.join(outputPath, _manifestName));
  if (!manifestFile.existsSync()) {
    if (outputDir.listSync(recursive: false).isNotEmpty) {
      var choices = [
        'Skip creating the output directory',
        'Delete the existing directory entirely',
        'Leave the directory in place and write over any existing files',
      ];
      int choice;
      try {
        choice = await environment.prompt(
            'Found existing output directory `$outputPath` but no manifest '
            'file. Please choose one of the following options:',
            choices);
      } on NonInteractiveBuildException catch (_) {
        choice = 0;
      }
      switch (choice) {
        case 0:
          _logger.warning('Skipped creation of the merged output directory.');
          return false;
        case 1:
          try {
            outputDir.deleteSync(recursive: true);
          } catch (e) {
            _logger.severe(
                'Failed to delete output dir at `$outputPath` with error:\n\n'
                '$e');
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
    var previousOutputs = logTimedSync(
        _logger,
        'Reading manifest at ${manifestFile.path}',
        () => manifestFile.readAsStringSync().split(_manifestSeparator));

    logTimedSync(_logger, 'Deleting previous outputs in `$outputPath`', () {
      for (var path in previousOutputs) {
        var file = new File(p.join(outputPath, path));
        if (file.existsSync()) file.deleteSync();
      }
      _cleanEmptyDirectories(outputPath, previousOutputs);
    });
  }
  return true;
}

/// Deletes all the directories which used to contain any path in
/// [removedFilePaths] if that directory is now empty.
void _cleanEmptyDirectories(
    String outputPath, Iterable<String> removedFilePaths) {
  for (var directory in removedFilePaths.map(p.dirname).toSet()) {
    _deleteUp(directory, outputPath);
  }
}

/// Deletes the directory at [from] and and any parent directories which are
/// subdirectories of [to] if they are empty.
void _deleteUp(String from, String to) {
  var directoryPath = from;
  while (p.isWithin(to, directoryPath)) {
    var directory = new Directory(directoryPath);
    if (directory.listSync().isNotEmpty) return;
    directory.deleteSync();
    directoryPath = p.dirname(directoryPath);
  }
}
