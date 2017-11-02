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
import '../asset/reader.dart';
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

  final DigestAssetReader reader;
  final RunnerAssetWriter writer;

  final PackageGraph packageGraph;
  final bool deleteFilesByDefault;
  final ResourceManager resourceManager;

  BuildDefinition._(
      this.assetGraph,
      this.updates,
      this.conflictingAssets,
      this.reader,
      this.writer,
      this.packageGraph,
      this.deleteFilesByDefault,
      this.resourceManager);

  static Future<BuildDefinition> load(
          BuildOptions options, List<BuildAction> buildActions) =>
      new _Loader(options, buildActions).load();
}

class _Loader {
  final List<BuildAction> _buildActions;
  final BuildOptions _options;

  _Loader(this._options, this._buildActions);

  Future<BuildDefinition> load() async {
    if (!_options.writeToCache) {
      final root = _options.packageGraph.root.name;
      for (final action in _buildActions) {
        if (action.package != _options.packageGraph.root.name) {
          throw new InvalidBuildActionException.nonRootPackage(action, root);
        }
      }
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
    DigestAssetReader reader = _options.reader;
    if (await _options.reader.canRead(assetGraphId)) {
      assetGraph = await logTimedAsync(_logger, 'Reading cached asset graph',
          () => _readAssetGraph(assetGraphId));
    }
    if (assetGraph != null && !_options.skipBuildScriptCheck) {
      await logTimedAsync(_logger, 'Checking build script for updates',
          () async {
        if (await new BuildScriptUpdates(_options, assetGraph)
            .hasBeenUpdated()) {
          _logger
              .warning('Invalidating asset graph due to build script update');
          assetGraph = null;
        }
      });
    }
    if (assetGraph == null) {
      await logTimedAsync(_logger, 'Building new asset graph', () async {
        assetGraph = await AssetGraph.build(_buildActions, inputSources,
            _options.packageGraph.root.name, reader);
        conflictingOutputs
            .addAll(assetGraph.outputs.where(allSources.contains).toSet());
      });
      await logTimedAsync(_logger, 'Recording initial build script state',
          () async {
        await new BuildScriptUpdates(_options, assetGraph)
            .recordInitialDigests();
      });
    } else {
      await logTimedAsync(
          _logger, 'Updating asset graph with changes since last build',
          () async {
        updates.addAll(await _findUpdates(
            assetGraph, inputSources, cacheDirSources, allSources));
      });
    }
    var writer = _options.writer;
    if (_options.writeToCache) {
      reader = new BuildCacheReader(
          reader, assetGraph, _options.packageGraph.root.name);
      writer = new BuildCacheWriter(
          writer, assetGraph, _options.packageGraph.root.name);
    }
    return new BuildDefinition._(
        assetGraph,
        updates,
        conflictingOutputs,
        reader,
        writer,
        _options.packageGraph,
        _options.deleteFilesByDefault,
        new ResourceManager());
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

    var newSources = inputSources.difference(assetGraph.allNodes
        .where((node) => node is! SyntheticAssetNode)
        .map((node) => node.id)
        .toSet());
    addUpdates(newSources, ChangeType.ADD);
    var removedAssets = assetGraph.allNodes
        .where((n) {
          if (n is SyntheticAssetNode) return false;
          if (n is GeneratedAssetNode) return n.wasOutput;
          return true;
        })
        .map((n) => n.id)
        .where((id) => !allSources.contains((id)));

    addUpdates(removedAssets, ChangeType.REMOVE);

    var remainingSources =
        assetGraph.sources.toSet().intersection(inputSources);
    var modifyChecks = remainingSources.map((id) async {
      var node = assetGraph.get(id);
      var originalDigest = node.lastKnownDigest;
      var currentDigest = await _options.reader.digest(id);
      if (currentDigest != originalDigest) {
        updates[id] = ChangeType.MODIFY;
      }
    });
    await Future.wait(modifyChecks);
    return updates;
  }

  /// Returns the set of original package inputs on disk.
  Future<Set<AssetId>> _findInputSources() async {
    var inputSets = _options.packageGraph.allPackages.values.map((package) =>
        new InputSet(package.name, package.includes,
            excludes: package.excludes));
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
