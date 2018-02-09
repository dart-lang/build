// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../environment/build_environment.dart';
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';

final _logger = new Logger('CreateOutputDir');
const _manifestName = '.build.manifest';
const _manifestSeparator = '\n';

/// Creates a merged output directory for a build at [outputPath].
///
/// Returns whether it succeeded or not.
Future<bool> createMergedOutputDir(
    String outputPath,
    AssetGraph assetGraph,
    PackageGraph packageGraph,
    AssetReader reader,
    BuildEnvironment environment) async {
  var outputDir = new Directory(outputPath);
  var outputDirExists = await outputDir.exists();
  if (outputDirExists) {
    var result = await _cleanUpOutputDir(outputDir, environment);
    if (!result) return result;
  }

  var outputAssets = new Set<AssetId>();
  await logTimedAsync(_logger, 'Creating merged output dir `$outputPath`',
      () async {
    if (!outputDirExists) {
      await outputDir.create(recursive: true);
    }
    var rootDirs = new Set<String>();

    for (var node in assetGraph.packageNodes(packageGraph.root.name)) {
      if (_shouldSkipNode(node)) continue;
      var parts = p.url.split(node.id.path);
      if (parts.length == 1) continue;
      var dir = parts.first;
      if (dir == outputPath || dir == 'lib') continue;
      rootDirs.add(parts.first);
    }

    for (var node in assetGraph.allNodes) {
      if (_shouldSkipNode(node)) continue;
      String assetPath;
      if (node.id.path.startsWith('lib')) {
        assetPath = p.url.join(
            'packages', node.id.package, node.id.path.substring('lib/'.length));
      } else {
        assetPath = node.id.path;
      }

      var outputId = new AssetId(packageGraph.root.name, assetPath);
      try {
        _writeAsBytes(outputDir, outputId, await reader.readAsBytes(node.id));
        outputAssets.add(outputId);
      } on AssetNotFoundException catch (e, __) {
        if (p.basename(node.id.path).startsWith('.')) {
          _logger.fine('Skipping missing hidden file ${node.id.path}');
        } else {
          _logger.severe(
              'Missing asset ${e.assetId}, it may have been deleted during the '
              'build. Please try rebuilding and if you continue to see the '
              'error then file a bug at '
              'https://github.com/dart-lang/build/issues/new.');
          rethrow;
        }
      }
    }

    outputAssets.addAll(
        await _createMissingTestHtmlFiles(outputPath, packageGraph.root.name));

    var packagesFileContent = packageGraph.allPackages.keys
        .map((p) => '$p:packages/$p/')
        .join('\r\n');
    for (var dir in rootDirs) {
      var packagesAsset =
          new AssetId(packageGraph.root.name, p.url.join(dir, '.packages'));
      _writeAsString(outputDir, packagesAsset, packagesFileContent);
      outputAssets.add(packagesAsset);
      var link = new Link(p.join(outputDir.path, dir, 'packages'));
      if (!link.existsSync()) {
        link.createSync(p.join('..', 'packages'), recursive: true);
      }
    }
  });

  logTimedSync(_logger, 'Writing asset manifest', () {
    var content = outputAssets.map((id) => id.path).join(_manifestSeparator);
    _writeAsString(
        outputDir, new AssetId(packageGraph.root.name, _manifestName), content);
  });

  return true;
}

bool _shouldSkipNode(AssetNode node) {
  if (!node.isReadable) return true;
  if (node is InternalAssetNode) return true;
  if (node is GeneratedAssetNode && !node.wasOutput) return true;
  if (node.id.path == '.packages') return true;
  return false;
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

/// Creates html files for tests in [outputDir] that are missing them.
///
/// This only exists as a hack until we have something like
/// https://github.com/dart-lang/build/issues/508.
Future<List<AssetId>> _createMissingTestHtmlFiles(
    String outputDir, String rootPackage) async {
  if (!await new Directory(p.join(outputDir, 'test')).exists()) return [];

  var dartBrowserTestSuffix = '_test.dart.browser_test.dart';
  var htmlTestSuffix = '_test.html';
  var dartFiles =
      new Glob('test/**$dartBrowserTestSuffix').list(root: outputDir);
  var outputAssets = <AssetId>[];
  await for (var file in dartFiles) {
    var dartPath = p.relative(file.path, from: outputDir);
    var htmlPath =
        dartPath.substring(0, dartPath.length - dartBrowserTestSuffix.length) +
            htmlTestSuffix;
    var htmlFile = new File(p.join(outputDir, htmlPath));
    if (!await htmlFile.exists()) {
      var originalDartPath = p.basename(
          dartPath.substring(0, dartPath.length - '.browser_test.dart'.length));
      await htmlFile.writeAsString('''
<!DOCTYPE html>
<html>
<head>
  <title>${HTML_ESCAPE.convert(htmlPath)} Test</title>
  <link rel="x-dart-test"
        href="${HTML_ESCAPE.convert(originalDartPath)}">
  <script src="packages/test/dart.js"></script>
</head>
</html>''');
      outputAssets.add(new AssetId(rootPackage, htmlPath));
    }
  }
  return outputAssets;
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
    });
  }
  return true;
}
