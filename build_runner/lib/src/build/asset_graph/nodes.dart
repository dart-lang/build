// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';

import 'node.dart';

/// Nodes in the `AssetGraph`.
class Nodes {
  final Map<AssetId, AssetNode> _nodes = {};

  /// The result of [computeOutputs] for reuse, or `null` if outputs have not
  /// been computed.
  Map<AssetId, Set<AssetId>>? _outputs;

  /// Sorted nodes by package, or `null` if they have not been computed.
  Map<String, List<AssetId>>? _sortedFileIdsByPackage;

  /// Whether [_sortedFileIdsByPackage] has already been calculated during
  /// this build.
  ///
  /// Sorted file IDs are calculated at most once per build as files are not
  /// added or removed during the build. This bool is used to check and throw if
  /// that does not hold.
  ///
  /// Note that "missing source" IDs are added during the build, but they don't
  /// count as files. Post process build steps can delete their input but that
  /// happens after the last possible use of `_sortedFileIdsByPackage` because
  /// post process steps can't glob for files.
  ///
  /// After the build and before the next build files can be added or removed,
  /// [clearComputationResults] will be called to reset.
  bool _sortedFileIdsByPackageWasComputed = false;

  Nodes();

  /// Whether [id] is in the graph.
  bool contains(AssetId id) => _nodes.containsKey(id);

  /// Gets the node for [id], or `null` if it doesn't exist.
  AssetNode? get(AssetId id) => _nodes[id];

  /// Updates a node in the graph with [updates].
  ///
  /// If it does not exist, [StateError] is thrown.
  ///
  /// Returns the updated node.
  AssetNode updateNode(AssetId id, void Function(AssetNodeBuilder) updates) {
    final node = get(id);
    if (node == null) throw StateError('Missing node: $id');
    final updatedNode = node.rebuild(updates);
    _nodes[id] = updatedNode;

    if (node.inputs != updatedNode.inputs) {
      _outputs = null;
    }
    if (node.isFile != updatedNode.isFile) {
      _sortedFileIdsByPackage = null;
    }

    return updatedNode;
  }

  /// Updates a node in the graph with [updates].
  ///
  /// If it does not exist, does nothing and returns `null`.
  ///
  /// If it does exist, returns the updated node.
  AssetNode? updateNodeIfPresent(
    AssetId id,
    void Function(AssetNodeBuilder) updates,
  ) {
    final node = get(id);
    if (node == null) return null;
    final updatedNode = node.rebuild(updates);
    _nodes[id] = updatedNode;

    if (node.inputs != updatedNode.inputs) {
      _outputs = null;
    }
    if (node.isFile != updatedNode.isFile) {
      _sortedFileIdsByPackage = null;
    }

    return updatedNode;
  }

  /// Adds [node] to the graph if it doesn't exist.
  ///
  /// Throws a [StateError] if it already exists in the graph.
  ///
  /// Returns the updated node: if it replaces an [AssetNode.missingSource] then
  /// `outputs` and `primaryOutputs` are copied to it from that.
  AssetNode add(AssetNode node) {
    if (node.isFile) _sortedFileIdsByPackage = null;
    final existing = get(node.id);
    if (existing != null) {
      if (existing.type == NodeType.missingSource) {
        _nodes.remove(existing.id);
        node = node.rebuild((b) {
          b.primaryOutputs.addAll(existing.primaryOutputs);
        });
      } else {
        throw StateError(
          'Tried to add node ${node.id} to the asset graph but it already '
          'exists.',
        );
      }
    }
    _nodes[node.id] = node;
    if (node.inputs?.isNotEmpty ?? false) {
      _outputs = null;
    }

    return node;
  }

  /// Removes [id] from the graph, if present.
  void remove(AssetId id) {
    final removed = _nodes.remove(id);
    if (removed != null && removed.isFile) {
      _sortedFileIdsByPackage = null;
    }
  }

  /// All nodes in the graph.
  Iterable<AssetNode> get allNodes => _nodes.values;

  /// All IDs in `package` that refer to files and match.
  ///
  /// A node refers to a file if [AssetNode.isFile].
  ///
  /// If [glob] is passed, return only IDs for which the glob matches the path.
  Iterable<AssetId> packageFileIds(String package, {Glob? glob}) {
    _sortedFileIdsByPackage ??= _computeSortedFileIdsByPackage();
    final list = _sortedFileIdsByPackage![package];
    if (list == null) return const [];
    if (glob == null) return list;

    final simplePrefix = simpleGlobPrefix(glob);
    Iterable<AssetId> result = list;
    if (simplePrefix.isNotEmpty) {
      result = list.filterToPrefix(simplePrefix);
    }

    return result.where((id) => glob.matches(id.path));
  }

  /// Computes a `Map` from package names to sorted IDs of files in the package.
  ///
  /// An asset ID is a file if [AssetNode.isFile].
  Map<String, List<AssetId>> _computeSortedFileIdsByPackage() {
    if (_sortedFileIdsByPackageWasComputed) {
      throw StateError(
        'Sorted file IDs by package were already computed this build.',
      );
    }
    _sortedFileIdsByPackageWasComputed = true;
    final result = <String, List<AssetId>>{};
    for (final value in _nodes.values) {
      if (value.isFile) {
        result.putIfAbsent(value.id.package, () => []).add(value.id);
      }
    }
    for (final value in result.values) {
      value.sort();
    }
    return result;
  }

  /// Computes node outputs: the inverse of the graph described by the `inputs`
  /// fields on glob and generated nodes.
  ///
  /// The result is cached until any node is updated with different `inputs` or
  /// [clearComputationResults] is called.
  Map<AssetId, Set<AssetId>> computeOutputs() {
    if (_outputs != null) return _outputs!;
    final result = <AssetId, Set<AssetId>>{};
    for (final node in allNodes) {
      if (node.type == NodeType.generated) {
        for (final input in node.generatedNodeState!.inputs) {
          result.putIfAbsent(input, () => {}).add(node.id);
        }
      } else if (node.type == NodeType.glob) {
        for (final input in node.globNodeState!.inputs) {
          result.putIfAbsent(input, () => {}).add(node.id);
        }
      }
    }
    return _outputs = result;
  }

  /// Call this after modifications to the graph and before the next build, to
  /// reset computed values.
  void clearComputationResults() {
    _outputs = null;
    _sortedFileIdsByPackageWasComputed = false;
  }
}

/// Extension on `List<AssetId>` that assumes the list is sorted so it can do a
/// binary search.
extension ListOfAssetIdsExtension on List<AssetId> {
  /// IDs in the list filtered to path prefix [prefix].
  Iterable<AssetId> filterToPrefix(String prefix) {
    return fromFirstWithPrefix(
      prefix,
    ).takeWhile((id) => id.path.startsWith(prefix));
  }

  /// IDs in the list starting from the first with path prefix [prefix].
  @visibleForTesting
  Iterable<AssetId> fromFirstWithPrefix(String prefix) {
    final fromIndex = findFirstWithPrefix(prefix);
    return fromIndex == -1 ? const [] : getRange(fromIndex, length);
  }

  /// Index of the first ID in the list with path prefix [prefix], or -1 if
  /// there is no matching ID.
  @visibleForTesting
  int findFirstWithPrefix(String prefix) {
    var min = 0;
    var max = length;
    while (min < max) {
      final mid = (min + max) ~/ 2;
      if (this[mid].path.compareTo(prefix) >= 0) {
        max = mid;
      } else {
        min = mid + 1;
      }
    }
    if (min >= length || !this[min].path.startsWith(prefix)) return -1;
    return min;
  }
}

/// The prefix of the [glob] pattern up to but not including the first special
/// character.
@visibleForTesting
String simpleGlobPrefix(Glob glob) {
  final pattern = glob.pattern;
  for (var i = 0; i != pattern.length; ++i) {
    final codeUnit = pattern.codeUnitAt(i);

    /// Code units signalling the start of non-literal content in a glob
    /// pattern, see: https://pub.dev/packages/glob
    if (codeUnit == $STAR ||
        codeUnit == $QUESTION ||
        codeUnit == $OPEN_SQUARE_BRACKET ||
        codeUnit == $BACKSLASH ||
        codeUnit == $OPEN_CURLY_BRACKET) {
      return pattern.substring(0, i);
    }
  }
  return pattern;
}

// Constants copied from `fe_analyzer_shared`.
// ignore_for_file: constant_identifier_names
const int $STAR = 42;
const int $QUESTION = 63;
const int $OPEN_SQUARE_BRACKET = 91;
const int $BACKSLASH = 92;
const int $OPEN_CURLY_BRACKET = 123;
