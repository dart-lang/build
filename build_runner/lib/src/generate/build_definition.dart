// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

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
import '../environment/build_environment.dart';
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';
import '../util/constants.dart';
import 'exceptions.dart';
import 'options.dart';
import 'phase.dart';

final _logger = new Logger('BuildDefinition');

class BuildDefinition {
  final AssetGraph assetGraph;

  final AssetReader reader;
  final RunnerAssetWriter writer;

  final PackageGraph packageGraph;
  final bool deleteFilesByDefault;
  final ResourceManager resourceManager;

  final BuildScriptUpdates buildScriptUpdates;

  /// Whether or not to run in a mode that conserves RAM at the cost of build
  /// speed.
  final bool enableLowResourcesMode;

  final OnDelete onDelete;

  final BuildEnvironment environment;

  BuildDefinition._(
      this.assetGraph,
      this.reader,
      this.writer,
      this.packageGraph,
      this.deleteFilesByDefault,
      this.resourceManager,
      this.buildScriptUpdates,
      this.enableLowResourcesMode,
      this.onDelete,
      this.environment);

  static Future<BuildDefinition> prepareWorkspace(BuildEnvironment environment,
          BuildOptions options, List<BuildPhase> buildPhases,
          {void onDelete(AssetId id)}) =>
      new _Loader(environment, options, buildPhases, onDelete)
          .prepareWorkspace();
}

class _Loader {
  final List<BuildPhase> _buildPhases;
  final BuildOptions _options;
  final BuildEnvironment _environment;
  final OnDelete _onDelete;

  _Loader(this._environment, this._options, this._buildPhases, this._onDelete);

  Future<BuildDefinition> prepareWorkspace() async {
    _checkBuildPhases();

    _logger.info('Initializing inputs');

    var assetGraph = await _tryReadCachedAssetGraph();
    var inputSources = await _findInputSources();
    var cacheDirSources = await _findCacheDirSources();
    var internalSources = await _findInternalSources();

    BuildScriptUpdates buildScriptUpdates;
    if (assetGraph != null) {
      var updates = await logTimedAsync(
          _logger,
          'Checking for updates since last build',
          () => _updateAssetGraph(assetGraph, _buildPhases, inputSources,
              cacheDirSources, internalSources));

      buildScriptUpdates = await BuildScriptUpdates.create(
          _environment.reader, _options.packageGraph, assetGraph);
      if (!_options.skipBuildScriptCheck &&
          buildScriptUpdates.hasBeenUpdated(updates.keys.toSet())) {
        _logger.warning('Invalidating asset graph due to build script update');
        var deletedSourceOutputs = await _cleanupOldOutputs(assetGraph);
        inputSources.removeAll(deletedSourceOutputs);
        assetGraph = null;
        buildScriptUpdates = null;
      }
    }

    if (assetGraph == null) {
      Set<AssetId> conflictingOutputs;

      await logTimedAsync(_logger, 'Building new asset graph', () async {
        assetGraph = await AssetGraph.build(_buildPhases, inputSources,
            internalSources, _options.packageGraph, _environment.reader);
        buildScriptUpdates = await BuildScriptUpdates.create(
            _environment.reader, _options.packageGraph, assetGraph);
        conflictingOutputs = assetGraph.outputs
            .where((n) => n.package == _options.packageGraph.root.name)
            .where(inputSources.contains)
            .toSet();
        final conflictsInDeps = assetGraph.outputs
            .where((n) => n.package != _options.packageGraph.root.name)
            .where(inputSources.contains)
            .toSet();
        if (conflictsInDeps.isNotEmpty) {
          throw new UnexpectedExistingOutputsException(conflictsInDeps);
        }
      });

      await logTimedAsync(
          _logger,
          'Checking for unexpected pre-existing outputs.',
          () => _initialBuildCleanup(conflictingOutputs,
              _wrapWriter(_environment.writer, assetGraph)));
    }

    return new BuildDefinition._(
        assetGraph,
        _wrapReader(_environment.reader, assetGraph),
        _wrapWriter(_environment.writer, assetGraph),
        _options.packageGraph,
        _options.deleteFilesByDefault,
        new ResourceManager(),
        buildScriptUpdates,
        _options.enableLowResourcesMode,
        _onDelete,
        _environment);
  }

  /// Checks that the [_buildPhases] are valid based on whether they are
  /// written to the build cache.
  void _checkBuildPhases() {
    final root = _options.packageGraph.root.name;
    for (final action in _buildPhases) {
      if (!action.hideOutput) {
        // Only `BuilderBuildAction`s can be not hidden.
        if (action is InBuildPhase &&
            action.package != _options.packageGraph.root.name) {
          throw new InvalidBuildPhaseException.nonRootPackage(action, root);
        }
      }
    }
  }

  /// Deletes the generated output directory.
  ///
  /// Typically this should be done whenever an asset graph is thrown away.
  Future<Null> _deleteGeneratedDir() async {
    var generatedDir = new Directory(generatedOutputDirectory);
    if (await generatedDir.exists()) {
      await generatedDir.delete(recursive: true);
    }
  }

  /// Returns the all the sources found in the cache directory.
  Future<Set<AssetId>> _findCacheDirSources() =>
      _listGeneratedAssetIds().toSet();

  /// Returns all the internal sources, such as those under [entryPointDir].
  Future<Set<AssetId>> _findInternalSources() {
    return _environment.reader
        .findAssets(new Glob('$entryPointDir/**'))
        .toSet();
  }

  /// Attempts to read in an [AssetGraph] from disk, and returns `null` if it
  /// fails for any reason.
  Future<AssetGraph> _tryReadCachedAssetGraph() async {
    final assetGraphId =
        new AssetId(_options.packageGraph.root.name, assetGraphPath);
    if (!await _environment.reader.canRead(assetGraphId)) {
      return null;
    }

    return logTimedAsync(_logger, 'Reading cached asset graph', () async {
      try {
        var cachedGraph = new AssetGraph.deserialize(
            await _environment.reader.readAsBytes(assetGraphId));
        if (computeBuildPhasesDigest(_buildPhases) !=
            cachedGraph.buildPhasesDigest) {
          _logger.warning(
              'Throwing away cached asset graph because the build phases have '
              'changed. This most commonly would happen as a result of adding a '
              'new dependency or updating your dependencies.');
          await _cleanupOldOutputs(cachedGraph);
          return null;
        }
        if (cachedGraph.dartVersion != Platform.version) {
          _logger.warning(
              'Throwing away cached asset graph due to Dart SDK update.');
          await _cleanupOldOutputs(cachedGraph);
          return null;
        }
        return cachedGraph;
      } on AssetGraphVersionException catch (_) {
        // Start fresh if the cached asset_graph version doesn't match up with
        // the current version. We don't currently support old graph versions.
        _logger.warning(
            'Throwing away cached asset graph due to version mismatch.');
        await _deleteGeneratedDir();
        return null;
      }
    });
  }

  /// Deletes all the old outputs from [graph] that were written to the source
  /// tree, and deletes the entire generated directory.
  Future<Iterable<AssetId>> _cleanupOldOutputs(AssetGraph graph) async {
    var deletedSources = <AssetId>[];
    await logTimedAsync(_logger, 'Cleaning up outputs from previous builds.',
        () async {
      // Delete all the non-hidden outputs.
      await Future.wait(graph.outputs.map((id) {
        var node = graph.get(id) as GeneratedAssetNode;
        if (node.wasOutput && !node.isHidden) {
          deletedSources.add(id);
          return _environment.writer.delete(id);
        }
      }).where((v) => v is Future));

      await _deleteGeneratedDir();
    });
    return deletedSources;
  }

  /// Updates [assetGraph] based on a the new view of the world.
  ///
  /// Once done, this returns a map of [AssetId] to [ChangeType] for all the
  /// changes.
  Future<Map<AssetId, ChangeType>> _updateAssetGraph(
      AssetGraph assetGraph,
      List<BuildPhase> buildPhases,
      Set<AssetId> inputSources,
      Set<AssetId> cacheDirSources,
      Set<AssetId> internalSources) async {
    var updates = await _findSourceUpdates(
        assetGraph, inputSources, cacheDirSources, internalSources);
    updates.addAll(_computeBuilderOptionsUpdates(assetGraph, buildPhases));
    await assetGraph.updateAndInvalidate(
        _buildPhases,
        updates,
        _options.packageGraph.root.name,
        (id) => _delete(id, _wrapWriter(_environment.writer, assetGraph)),
        _wrapReader(_environment.reader, assetGraph));
    return updates;
  }

  /// Wraps [original] in a [BuildCacheWriter].
  RunnerAssetWriter _wrapWriter(
      RunnerAssetWriter original, AssetGraph assetGraph) {
    assert(assetGraph != null);
    return new BuildCacheWriter(
        original, assetGraph, _options.packageGraph.root.name);
  }

  /// Wraps [original] in a [BuildCacheReader].
  AssetReader _wrapReader(AssetReader original, AssetGraph assetGraph) {
    assert(assetGraph != null);
    return new BuildCacheReader(
        original, assetGraph, _options.packageGraph.root.name);
  }

  /// Finds the asset changes which have happened while unwatched between builds
  /// by taking a difference between the assets in the graph and the assets on
  /// disk.
  Future<Map<AssetId, ChangeType>> _findSourceUpdates(
      AssetGraph assetGraph,
      Set<AssetId> inputSources,
      Set<AssetId> generatedSources,
      Set<AssetId> internalSources) async {
    final allSources = new Set<AssetId>()
      ..addAll(inputSources)
      ..addAll(generatedSources)
      ..addAll(internalSources);
    var updates = <AssetId, ChangeType>{};
    addUpdates(Iterable<AssetId> assets, ChangeType type) {
      for (var asset in assets) {
        updates[asset] = type;
      }
    }

    var newSources = inputSources.difference(assetGraph.allNodes
        .where((node) => node.isValidInput)
        .map((node) => node.id)
        .toSet());
    addUpdates(newSources, ChangeType.ADD);
    var removedAssets = assetGraph.allNodes
        .where((n) {
          if (!n.isReadable) return false;
          if (n is GeneratedAssetNode) return n.wasOutput;
          return true;
        })
        .map((n) => n.id)
        .where((id) => !allSources.contains((id)));

    addUpdates(removedAssets, ChangeType.REMOVE);

    var originalGraphSources = assetGraph.sources.toSet();
    var preExistingSources = originalGraphSources.intersection(inputSources)
      ..addAll(internalSources.where((id) => assetGraph.contains(id)));
    var modifyChecks = preExistingSources.map((id) async {
      var node = assetGraph.get(id);
      if (node == null) throw id;
      var originalDigest = node.lastKnownDigest;
      if (originalDigest == null) return;
      var currentDigest = await _environment.reader.digest(id);
      if (currentDigest != originalDigest) {
        updates[id] = ChangeType.MODIFY;
      }
    });
    await Future.wait(modifyChecks);
    return updates;
  }

  /// Checks for any updates to the [BuilderOptionsAssetNode]s for
  /// [buildPhases] compared to the last known state.
  Map<AssetId, ChangeType> _computeBuilderOptionsUpdates(
      AssetGraph assetGraph, List<BuildPhase> buildPhases) {
    var result = <AssetId, ChangeType>{};

    void updateBuilderOptionsNode(
        AssetId builderOptionsId, BuilderOptions options) {
      var builderOptionsNode =
          assetGraph.get(builderOptionsId) as BuilderOptionsAssetNode;
      var oldDigest = builderOptionsNode.lastKnownDigest;
      builderOptionsNode.lastKnownDigest = computeBuilderOptionsDigest(options);
      if (builderOptionsNode.lastKnownDigest != oldDigest) {
        result[builderOptionsId] = ChangeType.MODIFY;
      }
    }

    for (var phase = 0; phase < buildPhases.length; phase++) {
      var action = buildPhases[phase];
      if (action is InBuildPhase) {
        updateBuilderOptionsNode(
            builderOptionsIdForAction(action, phase), action.builderOptions);
      } else if (action is PostBuildPhase) {
        int actionNum = 0;
        for (var builderAction in action.builderActions) {
          updateBuilderOptionsNode(
              builderOptionsIdForAction(builderAction, actionNum),
              builderAction.builderOptions);
          actionNum++;
        }
      }
    }
    return result;
  }

  /// Returns the set of original package inputs on disk.
  Future<Set<AssetId>> _findInputSources() {
    final packageNames = new Stream<PackageNode>.fromIterable(
        _options.packageGraph.allPackages.values);
    return packageNames.asyncExpand(_listAssetIds).toSet();
  }

  Stream<AssetId> _listAssetIds(PackageNode package) async* {
    for (final glob in _packageIncludes(package)) {
      yield* _environment.reader
          .findAssets(new Glob(glob), package: package.name);
    }
  }

  List<String> _packageIncludes(PackageNode package) => package.isRoot
      ? _options.rootPackageFilesWhitelist
      : package.name == r'$sdk'
          ? const ['lib/dev_compiler/**.js', 'lib/_internal/**.sum']
          : const ['lib/**'];

  Stream<AssetId> _listGeneratedAssetIds() async* {
    var glob = new Glob('$generatedOutputDirectory/**');
    await for (var id in _environment.reader.findAssets(glob)) {
      var packagePath = id.path.substring(generatedOutputDirectory.length + 1);
      var firstSlash = packagePath.indexOf('/');
      if (firstSlash == -1) continue;
      var package = packagePath.substring(0, firstSlash);
      var path = packagePath.substring(firstSlash + 1);
      yield new AssetId(package, path);
    }
  }

  /// Handles cleanup of pre-existing outputs for initial builds (where there is
  /// no cached graph).
  Future<Null> _initialBuildCleanup(
      Set<AssetId> conflictingAssets, RunnerAssetWriter writer) async {
    if (conflictingAssets.isEmpty) return;

    // Skip the prompt if using this option.
    if (_options.deleteFilesByDefault) {
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

    var done = false;
    while (!done) {
      try {
        var choice = await _environment.prompt('Delete these files?',
            ['Delete', 'Cancel build', 'List conflicts']);
        switch (choice) {
          case 0:
            _logger.info('Deleting files...');
            done = true;
            await Future
                .wait(conflictingAssets.map((id) => _delete(id, writer)));
            break;
          case 1:
            throw new UnexpectedExistingOutputsException(conflictingAssets);
            break;
          case 2:
            _logger.info('Conflicts:\n${conflictingAssets.join('\n')}');
            // Logging should be sync :(
            await new Future(() {});
        }
      } on NonInteractiveBuildException {
        throw new UnexpectedExistingOutputsException(conflictingAssets);
      }
    }
  }

  Future _delete(AssetId id, RunnerAssetWriter writer) {
    _onDelete?.call(id);
    return writer.delete(id);
  }
}
