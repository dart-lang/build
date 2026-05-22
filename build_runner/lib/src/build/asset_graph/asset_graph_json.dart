// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import '../../build_plan/build_plan_digest.dart';
import '../library_cycle_graph/phased_asset_deps.dart';
import 'graph.dart';
import 'serializers.dart';

/// State stored in `asset_graph.json`.
///
/// Enough information to determine whether an incremental build is possible,
/// and if so exactly what should be rebuilt.
class AssetGraphJson {
  final BuildPlanDigest buildPlanDigest;
  final BuildState buildState;
  final PhasedAssetDeps phasedAssetDeps;

  AssetGraphJson({
    required this.buildPlanDigest,
    required this.buildState,
    required this.phasedAssetDeps,
  });

  /// Serializes for `asset_graph.json`.
  static Uint8List serialize({
    required BuildPlanDigest buildPlanDigest,
    required BuildState buildState,
    required PhasedAssetDeps phasedAssetDeps,
  }) {
    // Serialize fields first so all `AssetId` instances are seen by
    // `identityAssetIdSeralizer`.
    final serializedBuildState = serializeBuildState(buildState);
    final serializedBuildPlanDigest = serializers.serializeWith(
      BuildPlanDigest.serializer,
      buildPlanDigest,
    );
    final serializedPhasedAssetDeps = serializers.serializeWith(
      PhasedAssetDeps.serializer,
      phasedAssetDeps,
    );
    final result = {
      'version': _version,
      'ids': identityAssetIdSerializer.serializedObjects,
      'buildState': serializedBuildState,
      'buildPlanDigest': serializedBuildPlanDigest,
      'phasedAssetDeps': serializedPhasedAssetDeps,
    };
    identityAssetIdSerializer.reset();
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

      identityAssetIdSerializer.deserializeWithObjects(
        (deserialized['ids'] as List).map(
          (id) => assetIdSerializer.deserialize(serializers, id as Object),
        ),
      );

      final buildPlanDigest = serializers.deserializeWith(
        BuildPlanDigest.serializer,
        deserialized['buildPlanDigest'],
      );

      final buildState = deserializeBuildState(
        deserialized['buildState'] as Map,
      );

      final phasedAssetDeps = serializers.deserializeWith(
        PhasedAssetDeps.serializer,
        deserialized['phasedAssetDeps'],
      );

      return AssetGraphJson(
        buildState: buildState!,
        buildPlanDigest: buildPlanDigest!,
        phasedAssetDeps: phasedAssetDeps!,
      );
    } catch (_) {
      return null;
    } finally {
      identityAssetIdSerializer.reset();
    }
  }
}

/// Increment whenever older `asset_graph.json` files should be rejected.
const _version = 41;
final jsonUtf8 = json.fuse(utf8);
