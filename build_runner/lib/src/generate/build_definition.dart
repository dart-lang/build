// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:watcher/watcher.dart';

import '../asset/build_cache.dart';
import '../asset/writer.dart';
import '../asset_graph/exceptions.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../changes/build_script_updates.dart';
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';
import '../util/constants.dart';
import 'exceptions.dart';
import 'input_set.dart';
import 'options.dart';
import 'phase.dart';

final _logger = new Logger('BuildDefinition');

class BuildDefinition {
  final AssetGraph assetGraph;

  /// Assets which have changed since the cached asset graph was created.
  final Map<AssetId, ChangeType> updates;

  /// Assets which should be generated but already exist on disk and can't be
  /// proven to be from the last build.
  final Set<AssetId> conflictingAssets;

  final AssetReader reader;
  final RunnerAssetWriter writer;

  final PackageGraph packageGraph;
  final bool deleteFilesByDefault;

  BuildDefinition._(this.assetGraph, this.updates, this.conflictingAssets,
      this.reader, this.writer, this.packageGraph, this.deleteFilesByDefault);

  static Future<BuildDefinition> load(
          BuildOptions options, List<BuildAction> buildActions) =>
      new _Loader(options, buildActions).load();
}

class _Loader {
  final List<BuildAction> _buildActions;
  final BuildOptions _options;

  _Loader(this._options, this._buildActions);

  Future<BuildDefinition> load() async {
    if (!_options.writeToCache &&
        _buildActions.any((action) =>
            action.inputSet.package != _options.packageGraph.root.name)) {
      throw const InvalidBuildActionException.nonRootPackage();
    }
    final assetGraphId =
        new AssetId(_options.packageGraph.root.name, assetGraphPath);
    AssetGraph assetGraph;
    final conflictingOutputs = new Set<AssetId>();
    _logger.info('Initializing inputs');
    var inputSources = await _findInputSources();
    var cacheDirSources = new Set<AssetId>();
    if (_options.writeToCache) {
      cacheDirSources.addAll(await _listGeneratedAssetIds().toList());
    }
    var allSources = inputSources.union(cacheDirSources);
    var updates = <AssetId, ChangeType>{};
    await logTimedAsync(_logger, 'Reading cached dependency graph', () async {
      if (await _options.reader.canRead(assetGraphId)) {
        assetGraph = await _readAssetGraph(assetGraphId);
      }
      if (assetGraph != null &&
          await new BuildScriptUpdates(_options)
              .isNewerThan(assetGraph.validAsOf)) {
        _logger.warning('Invalidating asset graph due to build script update');
        assetGraph = null;
      }
      if (assetGraph == null) {
        assetGraph = new AssetGraph.build(_buildActions, inputSources);
        conflictingOutputs
            .addAll(assetGraph.outputs.where(allSources.contains).toSet());
      } else {
        _logger.info('Updating asset graph with changes since last build.');
        updates.addAll(await _findUpdates(
            assetGraph, inputSources, cacheDirSources, allSources));
      }
    });
    AssetReader reader = _options.reader;
    var writer = _options.writer;
    if (_options.writeToCache) {
      reader = new BuildCacheReader(
          reader, assetGraph, _options.packageGraph.root.name);
      writer = new BuildCacheWriter(
          writer, assetGraph, _options.packageGraph.root.name);
    }
    return new BuildDefinition._(assetGraph, updates, conflictingOutputs,
        reader, writer, _options.packageGraph, _options.deleteFilesByDefault);
  }

  /// Reads in an [AssetGraph] from disk.
  Future<AssetGraph> _readAssetGraph(AssetId assetGraphId) async {
    try {
      return new AssetGraph.deserialize(
          JSON.decode(await _options.reader.readAsString(assetGraphId)) as Map);
    } on AssetGraphVersionException catch (_) {
      // Start fresh if the cached asset_graph version doesn't match up with
      // the current version. We don't currently support old graph versions.
      _logger.info('Throwing away cached asset graph due to version mismatch.');
      return null;
    }
  }

  /// Finds the asset changes which have happened while unwatched between builds
  /// by taking a difference between the assets in the graph and the assets on
  /// disk.
  Future<Map<AssetId, ChangeType>> _findUpdates(
      AssetGraph assetGraph,
      Set<AssetId> inputSources,
      Set<AssetId> generatedSources,
      Set<AssetId> allSources) async {
    var updates = <AssetId, ChangeType>{};
    addUpdates(Iterable<AssetId> assets, ChangeType type) {
      for (var asset in assets) {
        updates[asset] = type;
      }
    }

    var newSources = inputSources
        .difference(assetGraph.allNodes.map((node) => node.id).toSet());
    addUpdates(newSources, ChangeType.ADD);
    var removedAssets = assetGraph.allNodes
        .where((n) =>
            n is! GeneratedAssetNode || (n as GeneratedAssetNode).wasOutput)
        .map((n) => n.id)
        .where((id) => !allSources.contains((id)));

    addUpdates(removedAssets, ChangeType.REMOVE);

    var remainingSources =
        assetGraph.sources.toSet().intersection(inputSources);
    var modifyChecks = remainingSources.map((id) async {
      var modified = await _options.reader.lastModified(id);
      if (modified.isAfter(assetGraph.validAsOf)) {
        updates[id] = ChangeType.MODIFY;
      }
    });
    await Future.wait(modifyChecks);
    return updates;
  }

  /// Returns the set of original package inputs on disk.
  Future<Set<AssetId>> _findInputSources() async {
    var inputSets = _options.packageGraph.allPackages.keys.map((package) =>
        new InputSet(package,
            [package == _options.packageGraph.root.name ? '**' : 'lib/**']));
    var sources = _listAssetIds(inputSets).where(_isValidInput).toSet();
    return sources;
  }

  /// Checks if an [input] is valid.
  bool _isValidInput(AssetId input) =>
      input.package != _options.packageGraph.root.name
          ? input.path.startsWith('lib/')
          : !toolDirs.any((d) => input.path.startsWith(d));

  Stream<AssetId> _listAssetIds(Iterable<InputSet> inputSets) async* {
    var seenAssets = new Set<AssetId>();
    for (var inputSet in inputSets) {
      for (var glob in inputSet.globs) {
        var assetIds =
            _options.reader.findAssets(glob, package: inputSet.package);
        await for (var id in assetIds) {
          if (!seenAssets.add(id) || !inputSet.matches(id)) continue;
          yield id;
        }
      }
    }
  }

  Stream<AssetId> _listGeneratedAssetIds() async* {
    var glob = new Glob('$generatedOutputDirectory/**');
    await for (var id in _options.reader.findAssets(glob)) {
      var packagePath = id.path.substring(generatedOutputDirectory.length + 1);
      var firstSlash = packagePath.indexOf('/');
      var package = packagePath.substring(0, firstSlash);
      var path = packagePath.substring(firstSlash + 1);
      yield new AssetId(package, path);
    }
  }
}
