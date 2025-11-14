// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math';

import 'package:build/build.dart';
import 'package:graphs/graphs.dart';

import 'asset_deps.dart';
import 'asset_deps_loader.dart';
import 'library_cycle.dart';
import 'library_cycle_graph.dart';
import 'phased_asset_deps.dart';
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
///
/// There can be multiple concurrent computations running on top of the same
/// state, as noted in the implementation. It is allowed to call the methods
/// `libraryCycleOf`, `libraryCycleGraphOf` and `transitiveDepsOf` while a prior
/// call to any of the methods is still running, provided each newer call is at
/// an earlier phase. This happens when a load does a read that triggers a build
/// of a generated file in an earlier phase.
class LibraryCycleGraphLoader {
  /// The phases at which evaluation is currently running.
  ///
  /// Used to check that recursive loads are always to an earlier phase.
  final List<int> _runningAtPhases = [];

  /// The dependencies of loaded assets, as far as is known.
  ///
  /// Source files do not change during the build, so as soon as loaded
  /// their value is a [PhasedValue.fixed] that is valid for the whole build.
  ///
  /// A generated file that could not yet be loaded is a
  /// [PhasedValue.unavailable] specify the phase when it will be generated.
  /// When to finish loading the asset is tracked in [_idsToLoad].
  ///
  /// A generated file that _has_ been loaded is a [PhasedValue.generated]
  /// specifying both the phase it was generated at and its parsed dependencies.
  final Map<AssetId, PhasedValue<AssetDeps>> _assetDeps = {};

  /// Assets to load.
  ///
  /// The `key` is the phase to load them at or after. A [SplayTreeMap] is used
  /// for its sorting, so earlier phases are processed first in [_nextIdToLoad].
  final SplayTreeMap<int, List<AssetId>> _idsToLoad = SplayTreeMap();

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
    _runningAtPhases.clear();
    _assetDeps.clear();
    _idsToLoad.clear();
    _cycles.clear();
    _graphs.clear();
    _graphsToComputeByPhase.clear();
  }

  /// Marks asset with [id] for loading at [phase].
  ///
  /// Any [_load] running at that phase or later will load it.
  void _loadAtPhase(int phase, AssetId id) {
    (_idsToLoad[phase] ??= []).add(id);
  }

  void _loadAllAtPhaseZero(Iterable<AssetId> ids) {
    if (ids.isEmpty) return;
    (_idsToLoad[0] ??= []).addAll(ids);
  }

  /// Whether there are assets to load before or at [upToPhase].
  bool _hasIdToLoad({required int upToPhase}) {
    final first = _idsToLoad.keys.firstOrNull;
    if (first == null) return false;
    if (first > upToPhase) {
      // Entries are sorted, so all further entries are also too high phase.
      return false;
    }
    return true;
  }

  /// The phase and ID of the next asset to load before or at [upToPhase].
  ///
  /// Earlier phases are processed first.
  ///
  /// Throws if not [_hasIdToLoad] at [upToPhase].
  ///
  /// When done loading call [_removeIdToLoad] with the phase and ID.
  (int, AssetId) _nextIdToLoad({required int upToPhase}) {
    final first = _idsToLoad.entries.first;
    if (first.key > upToPhase) {
      // Entries are sorted, so all further entries are also too high phase.
      throw StateError('No such element.');
    }
    // Return the last ID from the list of IDs at this phase because it's
    // cheapest to remove in `_removeIdToLoad`.
    final result = first.value.last;
    return (first.key, result);
  }

  /// Removes from [_idsToLoad].
  ///
  /// Pass a phase and ID from [_nextIdToLoad].
  void _removeIdToLoad(int phase, AssetId id) {
    final ids = _idsToLoad[phase];

    // It's possible that a recursive call to an earlier phase fully processed
    // the phase, leaving nothing to clean up.
    if (ids == null) {
      return;
    }

    // It's possible that a recursive call to an earlier phase encountered a
    // reference to an asset generated at this phase, and so added another
    // asset to load in this phase. In that case `id` is no longer the last in
    // the list: search the whole list to remove it.
    if (ids.last == id) {
      ids.removeLast();
    } else {
      final removed = ids.remove(id);
      if (!removed) {
        throw StateError('Failed to remove $id from _idsToLoad: $_idsToLoad');
      }
    }
    if (ids.isEmpty) _idsToLoad.remove(phase);
  }

  /// Loads [id] and its transitive dependencies at all phases available to
  /// [assetDepsLoader].
  ///
  /// Assets are loaded to [_assetDeps].
  ///
  /// If assets are encountered that have not yet been generated, they are
  /// added to [_idsToLoad], and will be loaded eagerly by any call to `_load`
  /// with an `assetDepsLoader` at a late enough phase.
  ///
  /// Newly seen assets are noted in [_graphsToComputeByPhase] at phase 0
  /// for further processing by [_buildCycles].
  Future<void> _load(AssetDepsLoader assetDepsLoader, AssetId id) async {
    // Mark [id] as an asset to load at any phase.
    _loadAtPhase(0, id);

    final phase = assetDepsLoader.phase;
    while (_hasIdToLoad(upToPhase: phase)) {
      final (idToLoadPhase, idToLoad) = _nextIdToLoad(upToPhase: phase);

      // Nothing to do if deps were already loaded, unless they expire and
      // [assetDepsLoader] is at a late enough phase to see the updated value.
      final alreadyLoadedAssetDeps = _assetDeps[idToLoad];
      if (alreadyLoadedAssetDeps != null &&
          !alreadyLoadedAssetDeps.isExpiredAt(phase: assetDepsLoader.phase)) {
        _removeIdToLoad(idToLoadPhase, idToLoad);
        continue;
      }

      // First time seeing the asset, mark for computation of cycles and
      // graphs given the initial state of the build.
      if (alreadyLoadedAssetDeps == null) {
        (_graphsToComputeByPhase[0] ??= {}).add(idToLoad);
      }

      // If `idToLoad` is a generated asset from an earlier phase then the call
      // to `assetDepsLoader.load` causes it to be built if not yet build. This
      // in turn might cause a recursion into `LibraryCycleGraphLoader` and back
      // into this `_load` method.
      //
      // Only recursion with an earlier phase is possible: attempted reads to a
      // later phase return nothing instead of causing a build. This is also
      // enforced in `libraryCycleOf`.
      //
      // The earlier phase `_load` might need results that this `_load` was
      // going to produce. This is handled via the shared `_idsToLoad`: the
      // earlier phase `_load` will take all the pending loads up to its own
      // phase.
      //
      // This might include the current `idToLoad`, which is left in
      // `_idsToLoad` until the load completes for that reason.
      //
      // If a recursive `_load` happens then the associated cycles and graphs
      // are also fully computed before this `_load` continues: the work that
      // remains is only work for later phases.
      final assetDeps =
          _assetDeps[idToLoad] = await assetDepsLoader.load(idToLoad);
      _removeIdToLoad(idToLoadPhase, idToLoad);

      if (assetDeps.isComplete) {
        // "isComplete" means it's a source file or a generated value that has
        // already been generated, and its deps have been parsed. Mark them
        // for loading at any phase: if the `_load` that loads them is at a too
        // early phase to see generated output they will be queued for
        // processing by a later `_load`.
        _loadAllAtPhaseZero(assetDeps.lastValue.deps);
      } else {
        // It's a generated source that has not yet been generated. Mark it for
        // loading later.
        _loadAtPhase(assetDeps.values.last.expiresAfter! + 1, idToLoad);
      }
    }
  }

  /// Computes [_cycles] then [_graphs] for all [_graphsToComputeByPhase].
  ///
  /// Call [_load] first so there are [_graphsToComputeByPhase] to process.
  ///
  /// Graphs which are still not complete--they have one or more assets that
  /// expire after [upToPhase]--are added to [_graphsToComputeByPhase] at
  /// the appropirate phase to be completed later.
  void _buildCycles(int upToPhase) {
    // Process phases that have work to do in ascending order.
    while (true) {
      int phase;

      // Work through phases <= `upToPhase` at which graphs expire,
      // so there are new values to compute.
      if (_graphsToComputeByPhase.isEmpty) break;
      phase = _graphsToComputeByPhase.keys.reduce(min);
      if (phase > upToPhase) break;
      final idsToComputeCyclesFrom = _graphsToComputeByPhase.remove(phase)!;

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
        // A cycle expires when any of its transitive deps expires, because if
        // it gets a new dep that leads back to the cycle then that whole path
        // joins the cycle. Get this expirey phase from the graph built by
        // `_buildGraphs`.
        final expiresAfter =
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
              return PhasedValue.of(cycle, expiresAfter: expiresAfter);
            }
            return existingCycle.followedBy(
              ExpiringValue<LibraryCycle>(cycle, expiresAfter: expiresAfter),
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
    // Cycles by ID at the current phase.
    final cycleById = <AssetId, LibraryCycle>{};
    for (final cycle in newCycles) {
      for (final id in cycle.ids) {
        cycleById[id] = cycle;
      }
    }

    /// Lookups up [id] in [cycleById], falling back to [_cycles] if it's not
    /// present.
    LibraryCycle lookupLibraryCycle(AssetId id) =>
        cycleById.putIfAbsent(id, () {
          return _cycles[id]!.valueAt(phase: phase);
        });

    // Create the graph for each cycle in [newCycles].
    for (final root in newCycles) {
      final graph = LibraryCycleGraphBuilder()..root.replace(root);

      // The graph expires when any asset in the graph expires. Start this
      //calculation by finding the earliest expirey phase of all assets in the
      //graph root cycle. It will be updated for each child graph below.
      var expiresAfter = root.ids
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
          final depCycle = lookupLibraryCycle(dep);
          if (identical(depCycle, root)) continue;
          if (alreadyAddedChildren.add(depCycle)) {
            final childGraph = _graphs[dep]!.expiringValueAt(phase: phase);
            graph.children.add(childGraph.value);
            expiresAfter = earliestPhase(expiresAfter, childGraph.expiresAfter);
          }
        }
      }

      // If the graph expires, mark it for computation later.
      if (expiresAfter != null) {
        (_graphsToComputeByPhase[expiresAfter + 1] ??= {}).addAll(root.ids);
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
            return PhasedValue.of(graph.build(), expiresAfter: expiresAfter);
          }
          return oldValue.followedBy(
            ExpiringValue(graph.build(), expiresAfter: expiresAfter),
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
  ///
  /// See class note about recursive calls.
  Future<PhasedValue<LibraryCycle>> libraryCycleOf(
    AssetDepsLoader assetDepsLoader,
    AssetId id,
  ) async {
    final phase = assetDepsLoader.phase;
    if (_runningAtPhases.isNotEmpty && phase >= _runningAtPhases.last) {
      throw StateError(
        'Cannot recurse at later or equal phase $phase, already running at: '
        '$_runningAtPhases',
      );
    }
    _runningAtPhases.add(assetDepsLoader.phase);

    await _load(assetDepsLoader, id);
    _buildCycles(assetDepsLoader.phase);
    final result = _cycles[id]!;

    // A recursive call always finishes before the outer call resumes.
    final removedPhase = _runningAtPhases.removeLast();
    if (removedPhase != phase) {
      throw StateError('Removed phase $removedPhase, expected $phase.');
    }

    return result;
  }

  /// Returns the [LibraryCycleGraph] of [id] at all phases before the
  /// [assetDepsLoader] phase.
  ///
  /// Previously computed state is used if possible, anything additional is
  /// loaded using [assetDepsLoader].
  ///
  /// See class note about recursive calls.
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
  ///
  /// See class note about recursive calls.
  Future<Iterable<AssetId>> transitiveDepsOf(
    AssetDepsLoader assetDepsLoader,
    AssetId id,
  ) async {
    final graph = await libraryCycleGraphOf(assetDepsLoader, id);
    return graph.valueAt(phase: assetDepsLoader.phase).transitiveDeps();
  }

  /// Serializable data from which the library cycle graphs can be
  /// reconstructed.
  PhasedAssetDeps phasedAssetDeps() =>
      PhasedAssetDeps((b) => b.assetDeps.addAll(_assetDeps));

  @override
  String toString() => '''
LibraryCycleGraphLoader(
  _runningAtPhases: $_runningAtPhases
  _assetDeps: $_assetDeps,
  _idsToLoad: $_idsToLoad,
  _cycles: $_cycles,
  _graphs: $_graphs,
  _graphsToComputeByPhase: $_graphsToComputeByPhase,
)''';
}
