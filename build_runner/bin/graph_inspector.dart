// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';

AssetGraph assetGraph;
PackageGraph packageGraph;

Future main(List<String> args) async {
  stdout.writeln(
      'Warning: this tool is unsupported and usage may change at any time, '
      'use at your own risk.');

  if (args.length != 1) {
    throw ArgumentError(
        'Expected exactly one argument, the path to a build script to '
        'analyze.');
  }
  var scriptPath = args.first;
  var scriptFile = File(scriptPath);
  if (!scriptFile.existsSync()) {
    throw ArgumentError(
        'Expected a build script at $scriptPath but didn\'t find one.');
  }

  var assetGraphFile =
      File(assetGraphPathFor(p.url.joinAll(p.split(scriptPath))));
  if (!assetGraphFile.existsSync()) {
    throw ArgumentError(
        'Unable to find AssetGraph for $scriptPath at ${assetGraphFile.path}');
  }
  stdout.writeln('Loading asset graph at ${assetGraphFile.path}...');

  assetGraph = AssetGraph.deserialize(assetGraphFile.readAsBytesSync());
  packageGraph = PackageGraph.forThisPackage();

  var commandRunner =
      CommandRunner('', 'A tool for inspecting the AssetGraph for your build')
        ..addCommand(InspectNodeCommand())
        ..addCommand(GraphCommand());

  stdout.writeln('Ready, please type in a command:');

  while (true) {
    stdout
      ..writeln('')
      ..write('> ');
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

      var description = StringBuffer()
        ..writeln('Asset: $stringUri')
        ..writeln('  type: ${node.runtimeType}');

      if (node is GeneratedAssetNode) {
        description
          ..writeln('  state: ${node.state}')
          ..writeln('  wasOutput: ${node.wasOutput}')
          ..writeln('  phase: ${node.phaseNumber}')
          ..writeln('  isFailure: ${node.isFailure}');
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
          assetGraph.allNodes
              .where((n) => n.outputs.contains(node.id))
              .map((n) => n.id)
              .forEach(_printAsset);
        }
      }

      stdout.write(description);
    }
    return null;
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
    argParser
      ..addFlag('generated',
          abbr: 'g', help: 'Show only generated assets.', defaultsTo: false)
      ..addFlag('original',
          abbr: 'o',
          help: 'Show only original source assets.',
          defaultsTo: false)
      ..addOption('package',
          abbr: 'p', help: 'Filters nodes to a certain package')
      ..addOption('pattern', abbr: 'm', help: 'glob pattern for path matching');
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
      var glob = Glob(pattern);
      assets = assets.where((id) => glob.matches(id.path));
    }

    for (var id in assets) {
      _listAsset(id, stdout, indentation: '  ');
    }
    return null;
  }
}

AssetId _idFromString(String stringUri) {
  var uri = Uri.parse(stringUri);
  if (uri.scheme == 'package') {
    return AssetId(uri.pathSegments.first,
        p.url.join('lib', p.url.joinAll(uri.pathSegments.skip(1))));
  } else if (!uri.isAbsolute && (uri.scheme == '' || uri.scheme == 'file')) {
    return AssetId(packageGraph.root.name, uri.path);
  } else {
    stderr.writeln('Unrecognized uri $uri, must be a package: uri or a '
        'relative path.');
    return null;
  }
}

_listAsset(AssetId output, StringSink buffer, {String indentation = '  '}) {
  var outputUri = output.uri;
  if (outputUri.scheme == 'package') {
    buffer.writeln('$indentation${output.uri}');
  } else {
    buffer.writeln('$indentation${output.path}');
  }
}
