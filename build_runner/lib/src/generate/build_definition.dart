// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import '../asset/reader.dart';
import '../asset_graph/exceptions.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';
import '../util/constants.dart';
import 'exceptions.dart';
import 'input_set.dart';
import 'phase.dart';

class BuildDefinition {
  final AssetGraph assetGraph;

  /// The serialized asset graph and generated files which need updates.
  final Set<AssetId> safeDeletes;

  /// Assets which should be generated but already exist on disk and can't be
  /// proven to be from the last build.
  final Set<AssetId> conflictingAssets;

  BuildDefinition(this.assetGraph, this.safeDeletes, this.conflictingAssets);
}

class BuildDefinitionLoader {
  final _logger = new Logger('BuildDefinitionLoader');
  final RunnerAssetReader _reader;
  final PackageGraph _packageGraph;
  final List<BuildAction> _buildActions;
  final bool _writeToCache;

  BuildDefinitionLoader(
      this._reader, this._packageGraph, this._buildActions, this._writeToCache);

  Future<BuildDefinition> load() async {
    final assetGraphId = new AssetId(_packageGraph.root.name, assetGraphPath);
    AssetGraph assetGraph;
    final safeDeletes = new Set<AssetId>();
    final conflictingOutputs = new Set<AssetId>();
    _logger.info('Initializing inputs');
    var currentSources = await _findCurrentSources();
    await logWithTime(_logger, 'Reading cached dependency graph', () async {
      if (await _reader.canRead(assetGraphId)) {
        assetGraph = await _readAssetGraph(assetGraphId);
        safeDeletes.add(assetGraphId);
      }
      if (assetGraph != null &&
          (await _buildScriptUpdateTime()).isAfter(assetGraph.validAsOf)) {
        _logger.warning('Invalidating asset graph due to build script update');
        assetGraph = null;
      }
      if (assetGraph == null) {
        assetGraph = new AssetGraph.build(_buildActions, currentSources);
        conflictingOutputs
            .addAll(assetGraph.outputs.where(currentSources.contains).toSet());
      } else {
        _logger
            .info('Updating dependency graph with changes since last build.');
        var updates = <AssetId, ChangeType>{};
        var newSources = new Set<AssetId>.from(currentSources)
          ..removeAll(assetGraph.allNodes.map((n) => n.id));
        updates.addAll(
            new Map.fromIterable(newSources, value: (_) => ChangeType.ADD));
        updates.addAll(await _getUpdates(assetGraph));
        safeDeletes
            .addAll(assetGraph.updateAndInvalidate(_buildActions, updates));
      }
    });
    return new BuildDefinition(assetGraph, safeDeletes, conflictingOutputs);
  }

  Future<BuildDefinition> fromGraph(
      AssetGraph assetGraph, Map<AssetId, ChangeType> updates) async {
    if ((await _buildScriptUpdateTime()).isAfter(assetGraph.validAsOf)) {
      throw new BuildScriptUpdatedException();
    }
    var safeDeletes = new Set<AssetId>();
    _logger.info('Updating dependency graph with changes since last build.');
    safeDeletes.addAll(assetGraph.updateAndInvalidate(_buildActions, updates));
    return new BuildDefinition(assetGraph, safeDeletes, new Set<AssetId>());
  }

  /// Reads in an [AssetGraph] from disk.
  Future<AssetGraph> _readAssetGraph(AssetId assetGraphId) async {
    try {
      return new AssetGraph.deserialize(
          JSON.decode(await _reader.readAsString(assetGraphId)) as Map);
    } on AssetGraphVersionException catch (_) {
      // Start fresh if the cached asset_graph version doesn't match up with
      // the current version. We don't currently support old graph versions.
      _logger.info('Throwing away cached asset graph due to version mismatch.');
      return null;
    }
  }

  /// Creates and returns a map of updates to assets based on [assetGraph].
  Future<Map<AssetId, ChangeType>> _getUpdates(AssetGraph assetGraph) async {
    // Collect updates to the graph based on any changed assets.
    var updates = <AssetId, ChangeType>{};
    await Future.wait(assetGraph.allNodes
        .where((node) =>
            node is! GeneratedAssetNode ||
            (node as GeneratedAssetNode).wasOutput)
        .map((node) async {
      bool exists;
      try {
        exists = await _reader.canRead(node.id);
      } on PackageNotFoundException catch (_) {
        exists = false;
      }
      if (!exists) {
        updates[node.id] = ChangeType.REMOVE;
        return;
      }
      // Only handle deletes for generated assets, their modified timestamp
      // is always newer than the asset graph.
      //
      // TODO(jakemac): https://github.com/dart-lang/build/issues/61
      if (node is GeneratedAssetNode) return;

      var lastModified = await _reader.lastModified(node.id);
      if (lastModified.compareTo(assetGraph.validAsOf) > 0) {
        updates[node.id] = ChangeType.MODIFY;
      }
    }));
    return updates;
  }

  /// Checks if the current running program has been updated since the asset graph
  /// was last built.
  ///
  /// TODO(jakemac): Come up with a better way of telling if the script has been
  /// updated since it started running.
  Future<DateTime> _buildScriptUpdateTime() async {
    var urisInUse = currentMirrorSystem().libraries.keys;
    var updateTimes = await Future.wait(urisInUse.map(_uriUpdateTime));
    return updateTimes.reduce((l, r) => l.compareTo(r) > 0 ? l : r);
  }

  Future<DateTime> _uriUpdateTime(Uri uri) async {
    switch (uri.scheme) {
      case 'dart':
        return new DateTime.fromMillisecondsSinceEpoch(0);
      case 'package':
        var parts = uri.pathSegments;
        var id = new AssetId(parts[0],
            path.url.joinAll(['lib']..addAll(parts.getRange(1, parts.length))));
        return _reader.lastModified(id);
      case 'file':

        // TODO(jakemac): Probably shouldn't use dart:io directly, but its
        // definitely the easiest solution and should be fine.
        var file = new File.fromUri(uri);
        return file.lastModified();
      case 'data':

        // Test runner uses a `data` scheme, don't invalidate for those.
        if (uri.path.contains('package:test')) {
          return new DateTime.fromMillisecondsSinceEpoch(0);
        }
    }
    _logger.info('Unsupported uri scheme `${uri.scheme}` found for '
        'library in build script, falling back on full rebuild. '
        '\nThis probably means you are running in an unsupported '
        'context, such as in an isolate or via `pub run`. Instead you '
        'should invoke this script directly like: '
        '`dart path_to_script.dart`.');
    return new DateTime.now();
  }

  /// Returns the set of available inputs on disk.
  Future<Set<AssetId>> _findCurrentSources() async {
    var inputSets = _packageGraph.allPackages.keys.map((package) =>
        new InputSet(
            package, [package == _packageGraph.root.name ? '**' : 'lib/**']));
    var sources = _listAssetIds(inputSets).where(_isValidInput).toSet();
    if (_writeToCache) {
      sources.addAll(_listGeneratedAssetIds());
    }
    return sources;
  }

  /// Checks if an [input] is valid.
  bool _isValidInput(AssetId input) => input.package != _packageGraph.root.name
      ? input.path.startsWith('lib/')
      : !toolDirs.any((d) => input.path.startsWith(d));

  Iterable<AssetId> _listAssetIds(Iterable<InputSet> inputSets) sync* {
    var seenAssets = new Set<AssetId>();
    for (var inputSet in inputSets) {
      for (var glob in inputSet.globs) {
        for (var id
            in _reader.findAssets(glob, packageName: inputSet.package)) {
          if (!seenAssets.add(id)) continue;
          yield id;
        }
      }
    }
  }

  Iterable<AssetId> _listGeneratedAssetIds() sync* {
    var glob = new Glob('$generatedOutputDirectory/**');
    for (var id in _reader.findAssets(glob)) {
      var packagePath = id.path.substring(generatedOutputDirectory.length + 1);
      var firstSlash = packagePath.indexOf('/');
      var package = packagePath.substring(0, firstSlash);
      var path = packagePath.substring(firstSlash + 1);
      yield new AssetId(package, path);
    }
  }
}
