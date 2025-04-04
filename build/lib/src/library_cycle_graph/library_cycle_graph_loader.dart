// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:graphs/graphs.dart';

import '../asset/id.dart';
import 'asset_deps.dart';
import 'asset_deps_loader.dart';
import 'library_cycle.dart';
import 'library_cycle_graph.dart';
import 'phased_value.dart';

/// Loads [LibraryCycleGraph]s during a phased build.
///
/// "Phased build" means:
///
///  - The build has a "timeline" described by an `int` phase number
///  - Build actions can see output from earlier phases but not from the
///   current phase or later phases
///  - Build phases do _not_ run monotonically, but are interleaved; an action
///    in phase x might trigger an action in phase y, where y < x
///
/// And these further details apply to `build_runner` builds:
///
///  - Action outputs are predictable: for any file that might be produced, it
///    is known before the build starts what build action might produce it, and
///    in what phase
///
/// This complicates dependency tracking in two notable ways.
///
/// Firstly, it means that the transitive dependencies of a node can change: if
/// any dependency is a generated source, then at the phase _after_ the one in
/// which it's generated, it must be parsed and any direct and indirect
/// dependencies added.
///
/// Secondly, because the loader is for use _during_ the build, it might be that
/// not all files have been generated yet. So, results must be returned based on
/// incomplete data, as needed.
class LibraryCycleGraphLoader {
  /// The dependencies of loaded assets, as far as is known.
  ///
  /// Source files do not change during the build, so as soon as loaded
  /// their value is a [PhasedValue.fixed] that is valid for the whole build.
  ///
  /// A generated file that could not yet be loaded is a
  /// [PhasedValue.unavailable] specify the phase when it will be generated.
  /// When to finish loading the asset is tracked in [_assetDepsToLoadByPhase].
  ///
  /// A generated file that _has_ been loaded is a [PhasedValue.generated]
  /// specifying both the phase it was generated at and its parsed dependencies.
  final Map<AssetId, PhasedValue<AssetDeps>> _assetDeps = {};

  /// Generated assets that were loaded before they were generated.
  ///
  /// The `key` is the phase at which they have been generated and can be read.
  final Map<int, Set<AssetId>> _assetDepsToLoadByPhase = {};

  /// Newly [_load]ed assets to process for the first time in [_buildCycles].
  Set<AssetId> _newAssets = {};

  /// All loaded library cycles, by asset.
  final Map<AssetId, PhasedValue<LibraryCycle>> _cycles = {};

  /// All loaded library cycle graphs, by asset.
  ///
  /// Graphs that expire have entries in [_graphsToComputeByPhase].
  final Map<AssetId, PhasedValue<LibraryCycleGraph>> _graphs = {};

  /// Graphs that expire, by the phase at which the update value should be
  /// computed: expirey phase + 1.
  final Map<int, Set<AssetId>> _graphsToComputeByPhase = {};

  /// Clears all data.
  void clear() {
    _assetDeps.clear();
    _assetDepsToLoadByPhase.clear();
    _newAssets.clear();
    _cycles.clear();
    _graphs.clear();
  }

  /// Loads [id] and its transitive dependencies at all phases available to
  /// [assetDepsLoader].
  ///
  /// Assets are loaded to [_assetDeps].
  ///
  /// If assets are encountered that have not yet been generated, they are
  /// added to [_assetDepsToLoadByPhase], and will be loaded eagerly by any
  /// call to `_load` with an `assetDepsLoader` at a late enough phase.
  ///
  /// Newly seen assets are noted in [_newAssets] for further processing by
  /// [_buildCycles].
  Future<void> _load(AssetDepsLoader assetDepsLoader, AssetId id) async {
    final idsToLoad = [id];
    // Finish loading any assets that were `_load`ed before they were generated
    // and have now been generated.
    for (final phase in _assetDepsToLoadByPhase.keys.toList(growable: false)) {
      if (phase <= assetDepsLoader.phase) {
        idsToLoad.addAll(_assetDepsToLoadByPhase.remove(phase)!);
      }
    }

    while (idsToLoad.isNotEmpty) {
      final idToLoad = idsToLoad.removeLast();

      // Nothing to do if deps were already loaded, unless they expire and
      // [assetDepsLoader] is at a late enough phase to see the updated value.
      final alreadyLoadedAssetDeps = _assetDeps[idToLoad];
      if (alreadyLoadedAssetDeps != null &&
          !alreadyLoadedAssetDeps.isExpiredAt(phase: assetDepsLoader.phase)) {
        continue;
      }

      final assetDeps =
          _assetDeps[idToLoad] = await assetDepsLoader.load(idToLoad);

      // First time seeing the asset, mark for computation of cycles and
      // graphs given the initial state of the build.
      if (alreadyLoadedAssetDeps == null) {
        _newAssets.add(idToLoad);
      }

      if (assetDeps.isComplete) {
        // "isComplete" means it's a source file or a generated value that has
        // already been generated. It has deps, so mark them for loading.
        for (final dep in assetDeps.lastValue.deps) {
          idsToLoad.add(dep);
        }
      } else {
        // It's a generated source that has not yet been generated. Mark it for
        // loading later.
        (_assetDepsToLoadByPhase[assetDeps.values.last.expiresAfter! + 1] ??=
                {})
            .add(idToLoad);
      }
    }
  }

  /// Computes [_cycles] for all [_newAssets] at phase 0, then for all assets
  /// with expiring graphs up to and including [upToPhase].
  ///
  /// Call [_load] first so there are [_newAssets] assets to process. Clears
  /// [_newAssets] of processed IDs.
  ///
  /// Graphs which are still not complete--they have one or more assets that
  /// expire after [upToPhase]--are added to [_graphsToComputeByPhase] to
  /// be completed later.
  /// [_graphsToComputeByPhase].
  void _buildCycles(int upToPhase) {
    // Process phases that have work to do in ascending order.
    while (true) {
      int phase;
      Set<AssetId> idsToComputeCyclesFrom;
      if (_newAssets.isNotEmpty) {
        // New assets: work to do at phase 0, the initial build state.
        phase = 0;
        idsToComputeCyclesFrom = _newAssets;
        _newAssets = {};
      } else {
        // Work through phases <= `upToPhase` at which graphs expire,
        // so there are new values to compute.
        if (_graphsToComputeByPhase.isEmpty) break;
        phase = _graphsToComputeByPhase.keys.reduce(min);
        if (phase > upToPhase) break;
        idsToComputeCyclesFrom = _graphsToComputeByPhase.remove(phase)!;
      }

      // Edges for strongly connected components computation.
      Iterable<AssetId> edgesFromId(AssetId id) {
        final deps = _assetDeps[id]!.valueAt(phase: phase).deps;

        // Check edge against cycles that have already been computed
        // at the current `phase`. Newly discovered assets at the same phase
        // cannot be part of already-computed cycles, so prevent recomputation
        // of those same cycles by hiding deps onto them.
        return deps.where(
          (id) => _cycles[id]?.isExpiredAt(phase: phase) ?? true,
        );
      }

      // Do the strongly connected components computation and convert
      // from its output, a list of lists of IDs, to a list of [LibraryCycle].
      final newComponentLists = stronglyConnectedComponents(
        idsToComputeCyclesFrom,
        edgesFromId,
      );
      final newCycles =
          newComponentLists.map((list) {
            // Compare to the library cycle computed at `phase - 1`. If the
            // cycles are the same size then they must have the same contents,
            // because cycles only change by growing as phases progress. In that
            // case, reuse the existing [LibraryCycle].
            final maybePhasedCycle = _cycles[list.first];
            if (maybePhasedCycle != null) {
              final value = maybePhasedCycle.valueAt(phase: phase - 1);
              if (value.ids.length == list.length) {
                return value;
              }
            }
            // The cycle is new or has changed, return a new value.
            return LibraryCycle((b) => b..ids.replace(list));
          }).toList();

      // Build graphs from cycles.
      _buildGraphs(phase, newCycles: newCycles);

      for (final cycle in newCycles) {
        // A cycle expires at the earliest expiry phase of all its transitive
        // deps, because new deps of any transitive dep might change the
        // cycle. Get this from the graph built by `_buildGraphs`.
        final expiresAt =
            _graphs[cycle.ids.first]!
                .expiringValueAt(phase: phase)
                .expiresAfter;

        // Merge the computed cycle into any existing phased value for each ID.
        // The phased value can differ by ID: they are in the same cycle at this
        // phase, but might not have been in the same cycle earlier.
        //
        // Nevertheless, the case in which the phased values are the same is a
        // common one, so use a temporary map from old value to new value to
        // avoid creating many equal but not identical phased values.
        final updatedValueByOldValue =
            Map<
              PhasedValue<LibraryCycle>?,
              PhasedValue<LibraryCycle>
            >.identity();

        for (final id in cycle.ids) {
          final existingCycle = _cycles[id];
          _cycles[id] = updatedValueByOldValue.putIfAbsent(existingCycle, () {
            if (existingCycle == null) {
              return PhasedValue.of(cycle, expiresAfter: expiresAt);
            }
            return existingCycle.followedBy(
              ExpiringValue<LibraryCycle>(cycle, expiresAfter: expiresAt),
            );
          });
        }
      }
    }
  }

  /// Builds [_graphs] at [phase] from [newCycles].
  ///
  /// [newCycles] must be ordered so that a cycle is preceded by all its
  /// dependencies. Fortunately, [stronglyConnectedComponents] already returns
  /// cycles in that order.
  ///
  /// A [_graphs] entry will be created for each ID in [newCycles].
  void _buildGraphs(int phase, {required List<LibraryCycle> newCycles}) {
    // Build lookup from ID to [LibraryCycle] including new and existing cycles.
    final existingCycles = <LibraryCycle>[];
    for (final phasedCycle in _cycles.values) {
      if (phasedCycle.isExpiredAt(phase: phase)) continue;
      existingCycles.add(phasedCycle.valueAt(phase: phase));
    }
    final cycleById = <AssetId, LibraryCycle>{};
    for (final cycle in existingCycles) {
      for (final id in cycle.ids) {
        cycleById[id] = cycle;
      }
    }
    for (final cycle in newCycles) {
      for (final id in cycle.ids) {
        cycleById[id] = cycle;
      }
    }

    // Create the graph for each cycle in [newCycles].
    for (final root in newCycles) {
      final graph = LibraryCycleGraphBuilder()..root.replace(root);

      // The graph expires at first phase in which any asset in the graph
      // expires. Start this calculation by finding the earliest expirey phase
      // of all assets in the graph root cycle. It will be updated for each
      // child graph below.
      var expiresAt = root.ids
          .map(
            (id) => _assetDeps[id]!.expiringValueAt(phase: phase).expiresAfter,
          )
          .reduce(earliestPhase);

      // Look up child cycles based on individual id dependencies, then look
      // up graphs for those cycles. All child graphs have already been computed
      // because of the order of [newCycles].
      final alreadyAddedChildren = Set<LibraryCycle>.identity();
      for (final id in root.ids) {
        final assetDeps = _assetDeps[id]!.valueAt(phase: phase);
        for (final dep in assetDeps.deps) {
          final depCycle = cycleById[dep]!;
          if (identical(depCycle, root)) continue;
          if (alreadyAddedChildren.add(depCycle)) {
            final childGraph = _graphs[dep]!.expiringValueAt(phase: phase);
            graph.children.add(childGraph.value);
            expiresAt = earliestPhase(expiresAt, childGraph.expiresAfter);
          }
        }
      }

      // If the graph expires, mark it for computation later.
      if (expiresAt != null) {
        (_graphsToComputeByPhase[expiresAt + 1] ??= {}).addAll(root.ids);
      }

      // Merge the computed graph into any existing phased value for each ID
      // in the root cycle.
      //
      // The phased value can differ by ID: they are in the same cycle at this
      // phase, but might not have been in the same cycle earlier.
      //
      // Nevertheless, the case in which the phased values are the same is a
      // common one, so use a temporary map from old value to new value to
      // avoid creating many equal but not identical phased values.
      final updatedValueByOldValue =
          Map<
            PhasedValue<LibraryCycleGraph>?,
            PhasedValue<LibraryCycleGraph>
          >.identity();

      for (final idToUpdate in root.ids) {
        final oldValue = _graphs[idToUpdate];
        _graphs[idToUpdate] = updatedValueByOldValue.putIfAbsent(oldValue, () {
          if (oldValue == null) {
            return PhasedValue.of(graph.build(), expiresAfter: expiresAt);
          }
          return oldValue.followedBy(
            ExpiringValue(graph.build(), expiresAfter: expiresAt),
          );
        });
      }
    }
  }

  /// Returns the [LibraryCycle] of [id] at all phases before the
  /// [assetDepsLoader] phase.
  ///
  /// Previously computed state is used if possible, anything additional is
  /// loaded using [assetDepsLoader].
  Future<PhasedValue<LibraryCycle>> libraryCycleOf(
    AssetDepsLoader assetDepsLoader,
    AssetId id,
  ) async {
    await _load(assetDepsLoader, id);
    _buildCycles(assetDepsLoader.phase);
    return _cycles[id]!;
  }

  /// Returns the [LibraryCycleGraph] of [id] at all phases before the
  /// [assetDepsLoader] phase.
  ///
  /// Previously computed state is used if possible, anything additional is
  /// loaded using [assetDepsLoader].
  Future<PhasedValue<LibraryCycleGraph>> libraryCycleGraphOf(
    AssetDepsLoader assetDepsLoader,
    AssetId id,
  ) async {
    await libraryCycleOf(assetDepsLoader, id);
    return _graphs[id]!;
  }

  /// Returns the transitive dependencies of Dart source [id] at the
  /// [assetDepsLoader] phase.
  ///
  /// A "dependency" is a mention in `import`, `export`, `part` or `part of`.
  /// Dependencies are considered at the [assetDepsLoader] phase, meaning that
  /// files generated in that phase or later count as empty and have no deps.
  ///
  /// Note that sources generated _at_ the [assetDepsLoader] phase are
  /// not readable during the phase and are not used.
  ///
  /// Previously computed state is used if possible, anything additional is
  /// loaded using [assetDepsLoader].
  Future<Iterable<AssetId>> transitiveDepsOf(
    AssetDepsLoader assetDepsLoader,
    AssetId id,
  ) async {
    final graph = await libraryCycleGraphOf(assetDepsLoader, id);
    return graph.valueAt(phase: assetDepsLoader.phase).transitiveDeps;
  }

  @override
  String toString() => '''
LibraryCycleGraphLoader(
  _assetDeps: $_assetDeps,
  _assetDepsToLoadByPhase: $_assetDepsToLoadByPhase,
  _newAssets: $_newAssets,
  _cycles: $_cycles,
  _graphs: $_graphs,
  _graphsToComputeByPhase: $_graphsToComputeByPhase,
)''';
}
