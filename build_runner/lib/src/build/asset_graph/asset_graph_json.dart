// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import '../../build_plan/build_plan_digest.dart';
import 'graph.dart';
import 'serializers.dart';

/// State stored in `asset_graph.json`.
///
/// Enough information to determine whether an incremental build is possible,
/// and if so exactly what should be rebuilt.
class AssetGraphJson {
  final BuildPlanDigest buildPlanDigest;
  final AssetGraph assetGraph;

  AssetGraphJson({required this.buildPlanDigest, required this.assetGraph});

  /// Serializes for `asset_graph.json`.
  static Uint8List serialize({
    required BuildPlanDigest buildPlanDigest,
    required AssetGraph assetGraph,
  }) {
    final result = {
      'version': _version,
      'assetGraph': serializeAssetGraph(assetGraph),
      'buildPlanDigest': serializers.serializeWith(
        BuildPlanDigest.serializer,
        buildPlanDigest,
      ),
    };
    return jsonUtf8.encode(result) as Uint8List;
  }

  /// Deserializes from `asset_graph.json`.
  ///
  /// Returns `null` if there is a version mismatch or any format mismatch.
  static AssetGraphJson? deserialize(Uint8List bytes) {
    try {
      final deserialized = jsonUtf8.decode(bytes);
      if (deserialized is! Map) return null;
      if (deserialized['version'] != _version) return null;

      final buildPlanDigest = serializers.deserializeWith(
        BuildPlanDigest.serializer,
        deserialized['buildPlanDigest'],
      );

      final assetGraph = deserializeAssetGraph(
        deserialized['assetGraph'] as Map,
      );

      return AssetGraphJson(
        assetGraph: assetGraph!,
        buildPlanDigest: buildPlanDigest!,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Increment whenever older `asset_graph.json` files should be rejected.
const _version = 35;
final jsonUtf8 = json.fuse(utf8);
