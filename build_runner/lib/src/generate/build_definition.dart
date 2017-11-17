// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  final DigestAssetReader reader;
  final RunnerAssetWriter writer;

  final PackageGraph packageGraph;
  final bool deleteFilesByDefault;
  final ResourceManager resourceManager;

  final BuildScriptUpdates buildScriptUpdates;

  /// Whether or not to run in a mode that conserves RAM at the cost of build
  /// speed.
  final bool enableLowResourcesMode;

  final OnDelete onDelete;

  BuildDefinition._(
      this.assetGraph,
      this.reader,
      this.writer,
      this.packageGraph,
      this.deleteFilesByDefault,
      this.resourceManager,
      this.buildScriptUpdates,
      this.enableLowResourcesMode,
      this.onDelete);

  static Future<BuildDefinition> prepareWorkspace(
          BuildOptions options, List<BuildAction> buildActions,
          {void onDelete(AssetId id)}) =>
      new _Loader(options, buildActions, onDelete).prepareWorkspace();
}

class _Loader {
  final List<BuildAction> _buildActions;
  final BuildOptions _options;
  final OnDelete _onDelete;

  _Loader(this._options, this._buildActions, this._onDelete);

  Future<BuildDefinition> prepareWorkspace() async {
    _checkBuildActions();

    _logger.info('Initializing inputs');
    var inputSources = await _findInputSources();
    var cacheDirSources = await _findCacheDirSources();
    var allSources = inputSources.union(cacheDirSources);

    var assetGraph = await _tryReadCachedAssetGraph();

    BuildScriptUpdates buildScriptUpdates;
    if (assetGraph != null) {
      var updates = await _updateAssetGraph(
          assetGraph, inputSources, cacheDirSources, allSources);

      buildScriptUpdates =
          await BuildScriptUpdates.create(_options, assetGraph);
      if (!_options.skipBuildScriptCheck &&
          buildScriptUpdates.hasBeenUpdated(updates.keys.toSet())) {
        _logger.warning('Invalidating asset graph due to build script update');
        assetGraph = null;
        buildScriptUpdates = null;
      }
    }

    if (assetGraph == null) {
      Set<AssetId> conflictingOutputs;

      await logTimedAsync(_logger, 'Building new asset graph', () async {
        assetGraph = await AssetGraph.build(_buildActions, inputSources,
            _options.packageGraph.root.name, _options.reader);
        buildScriptUpdates =
            await BuildScriptUpdates.create(_options, assetGraph);
        conflictingOutputs =
            assetGraph.outputs.where(allSources.contains).toSet();
      });

      await logTimedAsync(
          _logger,
          'Checking for unexpected pre-existing outputs.',
          () => _initialBuildCleanup(
              conflictingOutputs,
              _options.deleteFilesByDefault,
              _maybeWrapWriter(_options.writer, assetGraph)));
    }

    return new BuildDefinition._(
        assetGraph,
        _maybeWrapReader(_options.reader, assetGraph),
        _maybeWrapWriter(_options.writer, assetGraph),
        _options.packageGraph,
        _options.deleteFilesByDefault,
        new ResourceManager(),
        buildScriptUpdates,
        _options.enableLowResourcesMode,
        _onDelete);
  }

  /// Checks that the [_buildActions] are valid based on the
  /// `_options.writeToCache` setting.
  void _checkBuildActions() {
    if (!_options.writeToCache) {
      final root = _options.packageGraph.root.name;
      for (final action in _buildActions) {
        if (action.package != _options.packageGraph.root.name) {
          throw new InvalidBuildActionException.nonRootPackage(action, root);
        }
      }
    }
  }

  /// If `_options.writeToCache` is `true` then this returns the all the sources
  /// found in the cache directory, otherwise it returns an empty set.
  Future<Set<AssetId>> _findCacheDirSources() {
    if (_options.writeToCache) {
      return _listGeneratedAssetIds().toSet();
    }
    return new Future.value(new Set<AssetId>());
  }

  /// Attempts to read in an [AssetGraph] from disk, and returns `null` if it
  /// fails for any reason.
  Future<AssetGraph> _tryReadCachedAssetGraph() async {
    final assetGraphId =
        new AssetId(_options.packageGraph.root.name, assetGraphPath);
    if (!await _options.reader.canRead(assetGraphId)) {
      return null;
    }

    return logTimedAsync(_logger, 'Reading cached asset graph', () async {
      try {
        var cachedGraph = new AssetGraph.deserialize(JSON
            .decode(await _options.reader.readAsString(assetGraphId)) as Map);
        if (computeBuildActionsDigest(_buildActions) !=
            cachedGraph.buildActionsDigest) {
          _logger.warning(
              'Throwing away cached asset graph because the build actions have '
              'changed. This could happen as a result of adding a new '
              'dependency, or if you are using a build script which changes '
              'the build structure based on command line flags or other '
              'configuration.');
          return null;
        }
        return cachedGraph;
      } on AssetGraphVersionException catch (_) {
        // Start fresh if the cached asset_graph version doesn't match up with
        // the current version. We don't currently support old graph versions.
        _logger.warning(
            'Throwing away cached asset graph due to version mismatch.');
        return null;
      }
    });
  }

  /// Updates [assetGraph] based on a the new view of the world.
  ///
  /// Once done, this returns a map of [AssetId] to [ChangeType] for all the
  /// changes.
  Future<Map<AssetId, ChangeType>> _updateAssetGraph(
      AssetGraph assetGraph,
      Set<AssetId> inputSources,
      Set<AssetId> cacheDirSources,
      Set<AssetId> allSources) async {
    var updates = await _findUpdates(
        assetGraph, inputSources, cacheDirSources, allSources);
    await assetGraph.updateAndInvalidate(
        _buildActions,
        updates,
        _options.packageGraph.root.name,
        (id) => _delete(id, _maybeWrapWriter(_options.writer, assetGraph)),
        _maybeWrapReader(_options.reader, assetGraph));
    return updates;
  }

  /// Wraps [original] in a [BuildCacheWriter] if `_options.writeToCache` is
  /// `true`.
  RunnerAssetWriter _maybeWrapWriter(
      RunnerAssetWriter original, AssetGraph assetGraph) {
    assert(assetGraph != null);
    if (!_options.writeToCache) return original;
    return new BuildCacheWriter(
        original, assetGraph, _options.packageGraph.root.name);
  }

  /// Wraps [original] in a [BuildCacheReader] if `_options.writeToCache` is
  /// `true`.
  DigestAssetReader _maybeWrapReader(
      DigestAssetReader original, AssetGraph assetGraph) {
    assert(assetGraph != null);
    if (!_options.writeToCache) return original;
    return new BuildCacheReader(
        original, assetGraph, _options.packageGraph.root.name);
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
    var inputSets =
        _options.packageGraph.allPackages.values.map(_inputSetForPackage);
    var sources = (await _listAssetIds(inputSets).toSet())
      ..addAll(await _options.reader
          .findAssets(new Glob('$entryPointDir/**'))
          .toSet());
    return sources;
  }

  /// Only allow reads into `lib/` for non-root packages.
  ///
  /// As an optimization, also limit the SDK package to the files necessary for
  /// DDC.
  InputSet _inputSetForPackage(PackageNode package) {
    List<String> includes = package.name == r'$sdk'
        ? const ['lib/dev_compiler/**.js']
        : package.name == _options.packageGraph.root.name
            ? const ['**']
            : const ['lib/**'];
    return new InputSet(package.name, includes);
  }

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

  /// Handles cleanup of pre-existing outputs for initial builds (where there is
  /// no cached graph).
  Future<Null> _initialBuildCleanup(Set<AssetId> conflictingAssets,
      bool deleteFilesByDefault, RunnerAssetWriter writer) async {
    if (conflictingAssets.isEmpty) return;

    // Skip the prompt if using this option.
    if (deleteFilesByDefault) {
      _logger.info('Deleting ${conflictingAssets.length} declared outputs '
          'which already existed on disk.');
      await Future.wait(conflictingAssets.map((id) => _delete(id, writer)));
      return;
    }

    // Prompt the user to delete files that are declared as outputs.
    _logger.info('Found ${conflictingAssets.length} declared outputs '
        'which already exist on disk. This is likely because the'
        '`$cacheDir` folder was deleted, or you are submitting generated '
        'files to your source repository.');

    // If not in a standard terminal then we just exit, since there is no way
    // for the user to provide a yes/no answer.
    bool runningInPubRunTest() => Platform.script.scheme == 'data';
    if (stdioType(stdin) != StdioType.TERMINAL || runningInPubRunTest()) {
      throw new UnexpectedExistingOutputsException(conflictingAssets);
    }

    // Give a little extra space after the last message, need to make it clear
    // this is a prompt.
    stdout.writeln();
    var done = false;
    while (!done) {
      stdout.write('\nDelete these files (y/n) (or list them (l))?: ');
      var input = stdin.readLineSync();
      switch (input.toLowerCase()) {
        case 'y':
          stdout.writeln('Deleting files...');
          done = true;
          await Future.wait(conflictingAssets.map((id) => _delete(id, writer)));
          break;
        case 'n':
          throw new UnexpectedExistingOutputsException(conflictingAssets);
          break;
        case 'l':
          for (var output in conflictingAssets) {
            stdout.writeln(output);
          }
          break;
        default:
          stdout.writeln('Unrecognized option $input, (y/n/l) expected.');
      }
    }
  }

  Future _delete(AssetId id, RunnerAssetWriter writer) {
    _onDelete?.call(id);
    return writer.delete(id);
  }
}
