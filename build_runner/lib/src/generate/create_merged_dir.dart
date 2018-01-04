import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';

final _logger = new Logger('CreateOutputDir');

/// Creates a merged output directory for a build at [outputPath].
Future<Null> createMergedOutputDir(String outputPath, AssetGraph assetGraph,
    PackageGraph packageGraph, AssetReader reader) async {
  var outputDir = new Directory(outputPath);
  if (await outputDir.exists()) {
    await logTimedAsync(_logger, 'Deleting existing output dir `$outputPath`',
        () => outputDir.delete(recursive: true));
  }
  await logTimedAsync(_logger, 'Creating merged output dir at $outputPath',
      () async {
    await outputDir.create(recursive: true);
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
      var assetPaths = <String>[];
      if (node.id.path.startsWith('lib')) {
        assetPaths.add(p.url.join('packages', node.id.package,
            node.id.path.substring('lib/'.length)));
      } else {
        assetPaths.add(node.id.path);
      }
      for (var path in assetPaths) {
        var outputId = new AssetId(packageGraph.root.name, path);
        _writeAsBytes(outputDir, outputId, await reader.readAsBytes(node.id));
      }
    }

    var packagesFileContent = packageGraph.allPackages.keys
        .map((p) => '$p:packages/$p/')
        .join('\r\n');
    for (var dir in rootDirs) {
      _writeAsString(
          outputDir,
          new AssetId(packageGraph.root.name, p.url.join(dir, '.packages')),
          packagesFileContent);
      var link = new Link(p.join(outputDir.path, dir, 'packages'));
      link.createSync(p.join('..', 'packages'), recursive: true);
    }
  });
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
