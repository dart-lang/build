// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';
import 'package:build_runner/src/package_graph/package_graph.dart';
import 'package:build_runner/src/util/constants.dart';

AssetGraph assetGraph;
PackageGraph packageGraph;

Future main(List<String> args) async {
  stdout.writeln(
      'Warning: this tool is unsupported and usage may change at any time, '
      'use at your own risk.');

  if (args.length != 1) {
    throw new ArgumentError(
        'Expected exactly one argument, the path to a build script to '
        'analyze.');
  }
  var scriptPath = args.first;
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
  stdout.writeln('Loading asset graph at ${assetGraphFile.path}...');

  assetGraph = new AssetGraph.deserialize(
      JSON.decode(assetGraphFile.readAsStringSync()) as Map);
  packageGraph = new PackageGraph.forThisPackage();

  var commandRunner = new CommandRunner(
      "", "A tool for inspecting the AssetGraph for your build")
    ..addCommand(new InspectNodeCommand())
    ..addCommand(new GraphCommand());

  stdout.writeln('Ready, please type in a command:');

  while (true) {
    stdout.writeln('');
    stdout.write('> ');
    var nextCommand = stdin.readLineSync();
    stdout.writeln('');
    try {
      await commandRunner.run(nextCommand.split(' '));
    } on UsageException {
      stdout.writeln('Unrecognized option');
      await commandRunner.run(['help']);
    }
  }
}

class InspectNodeCommand extends Command {
  @override
  String get name => 'inspect';

  @override
  String get description =>
      'Lists all the information about an asset using a relative or package: uri';

  @override
  String get invocation => '${super.invocation} <dart-uri>';

  InspectNodeCommand() {
    argParser.addFlag('verbose', abbr: 'v');
  }

  @override
  run() {
    var stringUris = argResults.rest;
    if (stringUris.isEmpty) {
      stderr.writeln('Expected at least one uri for a node to inspect.');
    }
    for (var stringUri in stringUris) {
      var id = _idFromString(stringUri);
      if (id == null) {
        continue;
      }
      var node = assetGraph.get(id);
      if (node == null) {
        stderr.writeln('Unable to find an asset node for $stringUri.');
        continue;
      }

      var description = new StringBuffer()
        ..writeln('Asset: $stringUri')
        ..writeln('  type: ${node.runtimeType}');

      if (node is GeneratedAssetNode) {
        description.writeln('  needsUpdate: ${node.needsUpdate}');
        description.writeln('  wasOutput: ${node.wasOutput}');
      }

      _printAsset(AssetId asset) =>
          _listAsset(asset, description, indentation: '    ');

      if (argResults['verbose'] == true) {
        description.writeln('  primary outputs:');
        node.primaryOutputs.forEach(_printAsset);

        description.writeln('  secondary outputs:');
        node.outputs.difference(node.primaryOutputs).forEach(_printAsset);

        if (node is GeneratedAssetNode) {
          description.writeln('  inputs:');
          var inputs = assetGraph.allNodes
              .where((n) => n.outputs.contains(node.id))
              .map((n) => n.id);
          inputs.forEach(_printAsset);
        }
      }

      stdout.write(description);
    }
  }
}

class GraphCommand extends Command {
  @override
  String get name => 'graph';

  @override
  String get description => 'Lists all the nodes in the graph.';

  @override
  String get invocation => '${super.invocation} <dart-uri>';

  GraphCommand() {
    argParser.addFlag('generated',
        abbr: 'g', help: 'Show only generated assets.', defaultsTo: false);
    argParser.addFlag('original',
        abbr: 'o',
        help: 'Show only original source assets.',
        defaultsTo: false);
    argParser.addOption('package',
        abbr: 'p', help: 'Filters nodes to a certain package');
    argParser.addOption('pattern',
        abbr: 'm', help: 'glob pattern for path matching');
  }

  @override
  run() {
    var showGenerated = argResults['generated'] as bool;
    var showSources = argResults['original'] as bool;
    Iterable<AssetId> assets;
    if (showGenerated) {
      assets = assetGraph.outputs;
    } else if (showSources) {
      assets = assetGraph.sources;
    } else {
      assets = assetGraph.allNodes.map((n) => n.id);
    }

    var package = argResults['package'] as String;
    if (package != null) {
      assets = assets.where((id) => id.package == package);
    }

    var pattern = argResults['pattern'] as String;
    if (pattern != null) {
      var glob = new Glob(pattern);
      assets = assets.where((id) => glob.matches(id.path));
    }

    for (var id in assets) {
      _listAsset(id, stdout, indentation: '  ');
    }
  }
}

AssetId _idFromString(String stringUri) {
  var uri = Uri.parse(stringUri);
  if (uri.scheme == 'package') {
    return new AssetId(uri.pathSegments.first,
        p.url.join('lib', p.url.joinAll(uri.pathSegments.skip(1))));
  } else if (!uri.isAbsolute && (uri.scheme == '' || uri.scheme == 'file')) {
    return new AssetId(packageGraph.root.name, uri.path);
  } else {
    stderr.writeln('Unrecognized uri $uri, must be a package: uri or a '
        'relative path.');
    return null;
  }
}

_listAsset(AssetId output, StringSink buffer, {String indentation: '  '}) {
  var outputUri = output.uri;
  if (outputUri.scheme == 'package') {
    buffer.writeln('$indentation${output.uri}');
  } else {
    buffer.writeln('$indentation${output.path}');
  }
}
