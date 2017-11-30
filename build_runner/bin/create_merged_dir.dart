// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'package:build_runner/src/asset/build_cache.dart';
import 'package:build_runner/src/asset/file_based.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';
import 'package:build_runner/src/package_graph/package_graph.dart';
import 'package:build_runner/src/util/constants.dart';

AssetGraph assetGraph;
PackageGraph packageGraph;

Future main(List<String> args) async {
  stdout.writeln(
      'Warning: this tool is unsupported and usage may change at any time, '
      'use at your own risk.\n\n'
      'This tool also assumes you are using the `writeToCache=true` option.');

  var parsedArgs = argParser.parse(args);

  var scriptPath = parsedArgs['script'] as String;
  if (scriptPath == null) {
    throw new ArgumentError.notNull('--script');
  }

  var scriptFile = new File(scriptPath);
  if (!scriptFile.existsSync()) {
    throw new ArgumentError(
        'Expected a build script at $scriptPath but didn\'t find one.');
  }

  var assetGraphFile = new File(assetGraphPathFor(p.absolute(scriptPath)));
  if (!assetGraphFile.existsSync()) {
    throw new ArgumentError(
        'Unable to find AssetGraph for $scriptPath at ${assetGraphFile.path}');
  }

  var outputDir = new Directory(parsedArgs['output-dir'] as String);
  if (outputDir.existsSync()) {
    stdout.writeln('Deleting existing output dir `$outputDir`');
    outputDir.deleteSync(recursive: true);
  }
  outputDir.createSync(recursive: true);

  stdout.writeln('Loading asset graph at ${assetGraphFile.path}...');

  assetGraph = new AssetGraph.deserialize(
      JSON.decode(assetGraphFile.readAsStringSync()) as Map);

  packageGraph = new PackageGraph.forThisPackage();

  stdout.writeln('Creating output dir at ${outputDir.path}...');
  var rootDirs = new Set<String>();
  for (var node in assetGraph.packageNodes(packageGraph.root.name)) {
    var parts = p.url.split(node.id.path);
    if (parts.length == 1) continue;
    var dir = parts.first;
    if (dir == outputDir.path) continue;
    rootDirs.add(parts.first);
  }

  var reader = new BuildCacheReader(new FileBasedAssetReader(packageGraph),
      assetGraph, packageGraph.root.name);

  for (var node in assetGraph.allNodes) {
    if (node is SyntheticAssetNode) continue;
    if (node is GeneratedAssetNode && !node.wasOutput) continue;
    if (node.id.path == '.packages') continue;
    var assetPaths = <String>[];
    if (node.id.path.startsWith('lib')) {
      assetPaths.add(p.url.join(
          'packages', node.id.package, node.id.path.substring('lib/'.length)));
    } else {
      assetPaths.add(node.id.path);
    }
    for (var path in assetPaths) {
      var outputId = new AssetId(packageGraph.root.name, path);
      writeAsBytes(outputDir, outputId, await reader.readAsBytes(node.id));
    }
  }

  var packagesFileContent =
      packageGraph.allPackages.keys.map((p) => '$p:packages/$p/').join('\r\n');
  for (var dir in rootDirs) {
    writeAsString(
        outputDir,
        new AssetId(packageGraph.root.name, p.url.join(dir, '.packages')),
        packagesFileContent);
    var link = new Link(p.join(outputDir.path, dir, 'packages'));
    link.createSync(p.join('..', 'packages'), recursive: true);
  }
}

void writeAsBytes(Directory outputDir, AssetId id, List<int> bytes) {
  var file = fileFor(outputDir, id);
  file.writeAsBytesSync(bytes);
}

void writeAsString(Directory outputDir, AssetId id, String contents) {
  var file = fileFor(outputDir, id);
  file.writeAsStringSync(contents);
}

File fileFor(Directory outputDir, AssetId id) {
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

final argParser = new ArgParser()
  ..addFlag('help', negatable: false)
  ..addOption('script', help: 'The build script to load the asset graph for.')
  ..addOption('output-dir',
      abbr: 'o', help: 'The output directory.', defaultsTo: 'build');
