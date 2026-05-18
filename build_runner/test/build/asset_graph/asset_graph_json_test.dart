// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'package:build_runner/src/build/asset_graph/asset_graph_json.dart';
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_runner/src/build_plan/build_plan_digest.dart';
import 'package:test/test.dart';

void main() {
  group('AssetGraphJson', () {
    test('deserialize returns null on version mismatch', () async {
      final validBytes = AssetGraphJson.serialize(
        assetGraph: AssetGraph(),
        buildPlanDigest: BuildPlanDigest.build((b) {
          b.compileDigest = '';
          b.buildTriggersDigest = '';
          b.buildPhasesDigest = '';
          b.dartVersion = '';
        }),
      );
      expect(AssetGraphJson.deserialize(validBytes), isNotNull);

      // Change the version.
      final decodedMap =
          json.fuse(utf8).decode(validBytes) as Map<String, dynamic>;
      decodedMap['version'] = -1;
      final invalidBytes = utf8.encode(json.encode(decodedMap));

      // No longer deserializes.
      expect(AssetGraphJson.deserialize(invalidBytes), isNull);
    });

    test('deserialize returns null on invalid json', () async {
      final validBytes = AssetGraphJson.serialize(
        assetGraph: AssetGraph(),
        buildPlanDigest: BuildPlanDigest.build((b) {
          b.compileDigest = '';
          b.buildTriggersDigest = '';
          b.buildPhasesDigest = '';
          b.dartVersion = '';
        }),
      );
      final invalidBytes = validBytes.sublist(0, validBytes.length - 1);
      expect(AssetGraphJson.deserialize(invalidBytes), isNull);
    });
  });
}
