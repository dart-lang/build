// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:build_runner_core/build_runner_core.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset_graph/graph.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:watcher/watcher.dart';

import 'asset_change.dart';

/// Returns if a given asset change should be considered for building.
FutureOr<bool> shouldProcess(
  AssetChange change,
  AssetGraph assetGraph,
  BuildOptions buildOptions,
  bool willCreateOutputDir,
  Set<AssetId> expectedDeletes,
  AssetReader reader,
) {
  if (_isCacheFile(change) && !assetGraph.contains(change.id)) return false;
  var node = assetGraph.get(change.id);
  if (node != null) {
    if (!willCreateOutputDir && !node.changesRequireRebuild) return false;
    if (_isAddOrEditOnGeneratedFile(node, change.type)) return false;
    if (change.type == ChangeType.MODIFY) {
      // Was it really modified or just touched?
      reader.cache.invalidate([change.id]);
      return reader
          .digest(change.id)
          .then((newDigest) => node.digest != newDigest);
    }
  } else {
    if (change.type != ChangeType.ADD) return false;
    if (!buildOptions.targetGraph.anyMatchesAsset(change.id)) return false;
  }
  if (_isExpectedDelete(change, expectedDeletes)) return false;
  return true;
}

bool _isAddOrEditOnGeneratedFile(AssetNode node, ChangeType changeType) =>
    node.type == NodeType.generated && changeType != ChangeType.REMOVE;

bool _isCacheFile(AssetChange change) => change.id.path.startsWith(cacheDir);

bool _isExpectedDelete(AssetChange change, Set<AssetId> expectedDeletes) =>
    expectedDeletes.remove(change.id);
