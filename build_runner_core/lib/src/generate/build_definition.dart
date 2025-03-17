// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../asset/writer.dart';
import '../asset_graph/exceptions.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../changes/build_script_updates.dart';
import '../environment/build_environment.dart';
import '../logging/failure_reporter.dart';
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';
import '../util/constants.dart';
import '../util/sdk_version_match.dart';
import 'asset_tracker.dart';
import 'exceptions.dart';
import 'options.dart';
import 'phase.dart';

final _logger = Logger('BuildDefinition');

// TODO(davidmorgan): rename/refactor this, it's now just about loading state,
// not a build definition.
class BuildDefinition {
  final AssetGraph assetGraph;
  final BuildScriptUpdates? buildScriptUpdates;

  BuildDefinition._(this.assetGraph, this.buildScriptUpdates);

  static Future<BuildDefinition> prepareWorkspace(
    BuildEnvironment environment,
    BuildOptions options,
    List<BuildPhase> buildPhases,
  ) => _Loader(environment, options, buildPhases).prepareWorkspace();
}

class _Loader {
  final List<BuildPhase> _buildPhases;
  final BuildOptions _options;
  final BuildEnvironment _environment;

  _Loader(this._environment, this._options, this._buildPhases);

  Future<BuildDefinition> prepareWorkspace() async {
    _checkBuildPhases();

    _logger.info('Initializing inputs');

    var assetGraph = await _tryReadCachedAssetGraph();
    var assetTracker = AssetTracker(_environment.reader, _options.targetGraph);
    var inputSources = await assetTracker.findInputSources();
    var cacheDirSources = await assetTracker.findCacheDirSources();
    var internalSources = await assetTracker.findInternalSources();

    BuildScriptUpdates? buildScriptUpdates;
    if (assetGraph != null) {
      var updates = await logTimedAsync(
        _logger,
        'Checking for updates since last build',
        () => _updateAssetGraph(
          assetGraph!,
          assetTracker,
          _buildPhases,
          inputSources,
          cacheDirSources,
          internalSources,
        ),
      );
      buildScriptUpdates = await BuildScriptUpdates.create(
        _environment.reader,
        _options.packageGraph,
        assetGraph,
        disabled: _options.skipBuildScriptCheck,
      );

      var buildScriptUpdated =
          !_options.skipBuildScriptCheck &&
          buildScriptUpdates.hasBeenUpdated(updates.keys.toSet());
      if (buildScriptUpdated) {
        _logger.warning('Invalidating asset graph due to build script update!');

        var deletedSourceOutputs = await _cleanupOldOutputs(assetGraph);

        if (_runningFromSnapshot) {
          // We have to be regenerated if running from a snapshot.
          throw const BuildScriptChangedException();
        }

        inputSources.removeAll(deletedSourceOutputs);
        assetGraph = null;
        buildScriptUpdates = null;
      }
    }

    if (assetGraph == null) {
      late Set<AssetId> conflictingOutputs;

      await logTimedAsync(_logger, 'Building new asset graph', () async {
        try {
          assetGraph = await AssetGraph.build(
            _buildPhases,
            inputSources,
            internalSources,
            _options.packageGraph,
            _environment.reader,
          );
        } on DuplicateAssetNodeException catch (e, st) {
          _logger.severe('Conflicting outputs', e, st);
          throw const CannotBuildException();
        }
        buildScriptUpdates = await BuildScriptUpdates.create(
          _environment.reader,
          _options.packageGraph,
          assetGraph!,
          disabled: _options.skipBuildScriptCheck,
        );

        conflictingOutputs =
            assetGraph!.outputs
                .where((n) => n.package == _options.packageGraph.root.name)
                .where(inputSources.contains)
                .toSet();
        final conflictsInDeps =
            assetGraph!.outputs
                .where((n) => n.package != _options.packageGraph.root.name)
                .where(inputSources.contains)
                .toSet();
        if (conflictsInDeps.isNotEmpty) {
          log.severe(
            'There are existing files in dependencies which conflict '
            'with files that a Builder may produce. These must be removed or '
            'the Builders disabled before a build can continue: '
            '${conflictsInDeps.map((a) => a.uri).join('\n')}',
          );
          throw const CannotBuildException();
        }
      });

      await logTimedAsync(
        _logger,
        'Checking for unexpected pre-existing outputs.',
        () => _initialBuildCleanup(
          conflictingOutputs,
          _environment.writer.copyWith(generatedAssetHider: assetGraph),
        ),
      );
    }

    return BuildDefinition._(assetGraph!, buildScriptUpdates);
  }

  /// Checks that the [_buildPhases] are valid based on whether they are
  /// written to the build cache.
  void _checkBuildPhases() {
    final root = _options.packageGraph.root.name;
    for (final action in _buildPhases) {
      if (!action.hideOutput) {
        // Only `InBuildPhase`s can be not hidden.
        if (action is InBuildPhase && action.package != root) {
          // This should happen only with a manual build script since the build
          // script generation filters these out.
          _logger.severe(
            'A build phase (${action.builderLabel}) is attempting '
            'to operate on package "${action.package}", but the build script '
            'is located in package "$root". It\'s not valid to attempt to '
            'generate files for another package unless the BuilderApplication'
            'specified "hideOutput".'
            '\n\n'
            'Did you mean to write:\n'
            '  new BuilderApplication(..., toRoot())\n'
            'or\n'
            '  new BuilderApplication(..., hideOutput: true)\n'
            '... instead?',
          );
          throw const CannotBuildException();
        }
      }
    }
  }

  /// Deletes the generated output directory.
  ///
  /// Typically this should be done whenever an asset graph is thrown away.
  Future<void> _deleteGeneratedDir() async {
    var generatedDir = Directory(generatedOutputDirectory);
    if (await generatedDir.exists()) {
      await generatedDir.delete(recursive: true);
    }
  }

  /// Attempts to read in an [AssetGraph] from disk, and returns `null` if it
  /// fails for any reason.
  Future<AssetGraph?> _tryReadCachedAssetGraph() async {
    final assetGraphId = AssetId(
      _options.packageGraph.root.name,
      assetGraphPath,
    );
    if (!await _environment.reader.canRead(assetGraphId)) {
      return null;
    }

    return logTimedAsync(_logger, 'Reading cached asset graph', () async {
      try {
        var cachedGraph = AssetGraph.deserialize(
          await _environment.reader.readAsBytes(assetGraphId),
        );
        var buildPhasesChanged =
            computeBuildPhasesDigest(_buildPhases) !=
            cachedGraph.buildPhasesDigest;
        var pkgVersionsChanged =
            !const DeepCollectionEquality()
                .equals(cachedGraph.packageLanguageVersions, {
                  for (var pkg in _options.packageGraph.allPackages.values)
                    pkg.name: pkg.languageVersion,
                });
        var enabledExperimentsChanged =
            !const DeepCollectionEquality.unordered().equals(
              cachedGraph.enabledExperiments,
              enabledExperiments,
            );
        if (buildPhasesChanged ||
            pkgVersionsChanged ||
            enabledExperimentsChanged) {
          if (buildPhasesChanged) {
            _logger.warning(
              'Throwing away cached asset graph because the build phases '
              'have changed. This most commonly would happen as a result of '
              'adding a new dependency or updating your dependencies.',
            );
          }
          if (pkgVersionsChanged) {
            _logger.warning(
              'Throwing away cached asset graph because the language '
              'version of some package(s) changed. This would most commonly '
              'happen when updating dependencies or changing your min sdk '
              'constraint.',
            );
          }
          if (enabledExperimentsChanged) {
            _logger.warning(
              'Throwing away cached asset graph because the enabled Dart '
              'language experiments changed:\n\n'
              'Previous value: ${cachedGraph.enabledExperiments.join(' ')}\n'
              'Current value: ${enabledExperiments.join(' ')}',
            );
          }
          await Future.wait([
            _deleteAssetGraph(_options.packageGraph),
            _cleanupOldOutputs(cachedGraph),
            FailureReporter.cleanErrorCache(),
          ]);
          if (_runningFromSnapshot) {
            throw const BuildScriptChangedException();
          }
          return null;
        }
        if (!isSameSdkVersion(cachedGraph.dartVersion, Platform.version)) {
          _logger.warning(
            'Throwing away cached asset graph due to Dart SDK update.',
          );
          await Future.wait([
            _deleteAssetGraph(_options.packageGraph),
            _cleanupOldOutputs(cachedGraph),
            FailureReporter.cleanErrorCache(),
          ]);
          if (_runningFromSnapshot) {
            throw const BuildScriptChangedException();
          }
          return null;
        }
        return cachedGraph;
      } on AssetGraphCorruptedException catch (_) {
        // Start fresh if the cached asset_graph cannot be deserialized
        _logger.warning(
          'Throwing away cached asset graph due to '
          'version mismatch or corrupted asset graph.',
        );
        await Future.wait([
          _deleteGeneratedDir(),
          FailureReporter.cleanErrorCache(),
        ]);
        return null;
      }
    });
  }

  /// Deletes all the old outputs from [graph] that were written to the source
  /// tree, and deletes the entire generated directory.
  Future<Iterable<AssetId>> _cleanupOldOutputs(AssetGraph graph) async {
    var deletedSources = <AssetId>[];
    await logTimedAsync(
      _logger,
      'Cleaning up outputs from previous builds.',
      () async {
        // Delete all the non-hidden outputs.
        await Future.wait(
          graph.outputs.map((id) {
            var node = graph.get(id)!;
            final nodeConfiguration = node.generatedNodeConfiguration!;
            final nodeState = node.generatedNodeState!;
            if (nodeState.wasOutput && !nodeConfiguration.isHidden) {
              var idToDelete = id;
              // If the package no longer exists, then the user must have
              // renamed the root package.
              //
              // In that case we change `idToDelete` to be in the root package.
              if (_options.packageGraph[id.package] == null) {
                idToDelete = AssetId(_options.packageGraph.root.name, id.path);
              }
              deletedSources.add(idToDelete);
              return _environment.writer.delete(idToDelete);
            }
            return null;
          }).whereType<Future>(),
        );

        await _deleteGeneratedDir();
      },
    );
    return deletedSources;
  }

  Future<void> _deleteAssetGraph(PackageGraph packageGraph) =>
      File(p.join(packageGraph.root.path, assetGraphPath)).delete();

  /// Updates [assetGraph] based on a the new view of the world.
  ///
  /// Once done, this returns a map of [AssetId] to [ChangeType] for all the
  /// changes.
  Future<Map<AssetId, ChangeType>> _updateAssetGraph(
    AssetGraph assetGraph,
    AssetTracker assetTracker,
    List<BuildPhase> buildPhases,
    Set<AssetId> inputSources,
    Set<AssetId> cacheDirSources,
    Set<AssetId> internalSources,
  ) async {
    var updates = await assetTracker.computeSourceUpdates(
      inputSources,
      cacheDirSources,
      internalSources,
      assetGraph,
    );
    updates.addAll(_computeBuilderOptionsUpdates(assetGraph, buildPhases));
    await assetGraph.updateAndInvalidate(
      _buildPhases,
      updates,
      _options.packageGraph.root.name,
      (id) => _environment.writer
          .copyWith(generatedAssetHider: assetGraph)
          .delete(id),
      _environment.reader.copyWith(generatedAssetHider: assetGraph),
    );
    return updates;
  }

  /// Checks for any updates to the [AssetNode.builderOptions] for
  /// [buildPhases] compared to the last known state.
  Map<AssetId, ChangeType> _computeBuilderOptionsUpdates(
    AssetGraph assetGraph,
    List<BuildPhase> buildPhases,
  ) {
    var result = <AssetId, ChangeType>{};

    void updateBuilderOptionsNode(
      AssetId builderOptionsId,
      BuilderOptions options,
    ) {
      assetGraph.updateNode(builderOptionsId, (nodeBuilder) {
        if (nodeBuilder.type != NodeType.builderOptions) {
          throw StateError(
            'Expected node of type NodeType.builderOptionsNode:'
            '${nodeBuilder.build()}',
          );
        }
        var oldDigest = nodeBuilder.lastKnownDigest;
        nodeBuilder.lastKnownDigest = computeBuilderOptionsDigest(options);
        if (nodeBuilder.lastKnownDigest != oldDigest) {
          result[builderOptionsId] = ChangeType.MODIFY;
        }
      });
    }

    for (var phase = 0; phase < buildPhases.length; phase++) {
      var action = buildPhases[phase];
      if (action is InBuildPhase) {
        updateBuilderOptionsNode(
          builderOptionsIdForAction(action, phase),
          action.builderOptions,
        );
      } else if (action is PostBuildPhase) {
        var actionNum = 0;
        for (var builderAction in action.builderActions) {
          updateBuilderOptionsNode(
            builderOptionsIdForAction(builderAction, actionNum),
            builderAction.builderOptions,
          );
          actionNum++;
        }
      }
    }
    return result;
  }

  /// Handles cleanup of pre-existing outputs for initial builds (where there is
  /// no cached graph).
  Future<void> _initialBuildCleanup(
    Set<AssetId> conflictingAssets,
    RunnerAssetWriter writer,
  ) async {
    if (conflictingAssets.isEmpty) return;

    // Skip the prompt if using this option.
    if (_options.deleteFilesByDefault) {
      _logger.info(
        'Deleting ${conflictingAssets.length} declared outputs '
        'which already existed on disk.',
      );
      await Future.wait(conflictingAssets.map((id) => writer.delete(id)));
      return;
    }

    // Prompt the user to delete files that are declared as outputs.
    _logger.info(
      'Found ${conflictingAssets.length} declared outputs '
      'which already exist on disk. This is likely because the'
      '`$cacheDir` folder was deleted, or you are submitting generated '
      'files to your source repository.',
    );

    var done = false;
    while (!done) {
      try {
        var choice = await _environment.prompt('Delete these files?', [
          'Delete',
          'Cancel build',
          'List conflicts',
        ]);
        switch (choice) {
          case 0:
            _logger.info('Deleting files...');
            done = true;
            await Future.wait(conflictingAssets.map((id) => writer.delete(id)));
            break;
          case 1:
            _logger.severe(
              'The build will not be able to contiue until the '
              'conflicting assets are removed or the Builders which may '
              'output them are disabled. The outputs are: '
              '${conflictingAssets.map((a) => a.path).join('\n')}',
            );
            throw const CannotBuildException();
          case 2:
            _logger.info('Conflicts:\n${conflictingAssets.join('\n')}');
            // Logging should be sync :(
            await Future(() {});
        }
      } on NonInteractiveBuildException {
        _logger.severe(
          'Conflicting outputs were detected and the build '
          'is unable to prompt for permission to remove them. '
          'These outputs must be removed manually or the build can be '
          'run with `--delete-conflicting-outputs`. The outputs are: '
          '${conflictingAssets.map((a) => a.path).join('\n')}',
        );
        throw const CannotBuildException();
      }
    }
  }
}

bool get _runningFromSnapshot => !Platform.script.path.endsWith('.dart');
