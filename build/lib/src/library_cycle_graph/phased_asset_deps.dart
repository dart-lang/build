// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../asset/id.dart';
import 'asset_deps.dart';
import 'phased_value.dart';

part 'phased_asset_deps.g.dart';

abstract class PhasedAssetDeps
    implements Built<PhasedAssetDeps, PhasedAssetDepsBuilder> {
  static Serializer<PhasedAssetDeps> get serializer =>
      _$phasedAssetDepsSerializer;

  BuiltMap<AssetId, PhasedValue<AssetDeps>> get assetDeps;

  factory PhasedAssetDeps([void Function(PhasedAssetDepsBuilder) b]) =
      _$PhasedAssetDeps;
  PhasedAssetDeps._();

  factory PhasedAssetDeps.of(Map<AssetId, PhasedValue<AssetDeps>> assetDeps) =>
      _$PhasedAssetDeps._(assetDeps: assetDeps.build());

  @memoized
  PhasedAssetDeps get reversed {
    // Build a map from asset ID to its reverse deps. The rdeps are stored in a
    // `SplayTreeMap` in which the key is the first phase at which the dep
    // exists; zero if it always exists.
    final reverseDependencies = <AssetId, SplayTreeMap<int, Set<AssetId>>>{};

    // Add an entry `reverseDependencies` that exists at and after `atPhase`.
    // `from` and `to` are in the sense of the result graph, not the input
    // graph: this adds an entry on the `from` node of the result.
    void addReverseDependency({
      required int atPhase,
      required AssetId from,
      required AssetId to,
    }) {
      reverseDependencies
          .putIfAbsent(from, SplayTreeMap<int, Set<AssetId>>.new)
          .putIfAbsent(atPhase, () => <AssetId>{})
          .add(to);
    }

    for (final idAndPhasedAssetDeps in assetDeps.entries) {
      var previousPhase = 0;
      var previousDeps = AssetDeps.empty;

      // For each entry in the phased value record reverse deps for all newly
      // added deps.
      for (final expiringValue in idAndPhasedAssetDeps.value.values) {
        final currentDeps = expiringValue.value;
        for (final dep in currentDeps.deps) {
          if (previousDeps.deps.contains(dep)) continue;
          addReverseDependency(
            atPhase: previousPhase,
            from: dep,
            to: idAndPhasedAssetDeps.key,
          );
        }
        // If `expiresAfter` is null, there are no more values: the loop will
        // terminate.
        if (expiringValue.expiresAfter != null) {
          previousPhase = expiringValue.expiresAfter! + 1;
          previousDeps = currentDeps;
        }
      }
    }

    final resultBuilder = PhasedAssetDepsBuilder();
    for (final assetId in assetDeps.keys) {
      final newReverseDependenciesByPhase = reverseDependencies[assetId];

      if (newReverseDependenciesByPhase == null) {
        resultBuilder.assetDeps[assetId] = PhasedValue.fixed(AssetDeps.empty);
        continue;
      }

      final phases = newReverseDependenciesByPhase.keys.toList();
      final phasedBuilder = PhasedValueBuilder<AssetDeps>();
      var depsBuilder = AssetDepsBuilder();

      for (var i = 0; i != phases.length; ++i) {
        final phase = phases[i];

        if (i == 0 && phase != 0) {
          phasedBuilder.values.add(
            ExpiringValue(depsBuilder.build(), expiresAfter: phase - 1),
          );
        }

        final expiresAfter = i == phases.length - 1 ? null : phases[i + 1] - 1;
        depsBuilder.deps.addAll(newReverseDependenciesByPhase[phase]!);
        phasedBuilder.values.add(
          ExpiringValue(depsBuilder.build(), expiresAfter: expiresAfter),
        );
      }

      resultBuilder.assetDeps[assetId] = phasedBuilder.build();
    }
    return resultBuilder.build();
  }
}
