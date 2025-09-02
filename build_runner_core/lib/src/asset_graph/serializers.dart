// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart' show AssetId, PostProcessBuildStep;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:crypto/crypto.dart';

import '../library_cycle_graph/asset_deps.dart';
import '../library_cycle_graph/phased_asset_deps.dart';
import '../library_cycle_graph/phased_value.dart';
import 'identity_serializer.dart';
import 'node.dart';
import 'post_process_build_step_id.dart';

part 'serializers.g.dart';

final postProcessBuildStepOutputsInnerFullType = const FullType(Map, [
  FullType(PostProcessBuildStep),
  FullType(Set, [FullType(AssetId)]),
]);

final postProcessBuildStepOutputsFullType = FullType(Map, [
  const FullType(String),
  postProcessBuildStepOutputsInnerFullType,
]);

final assetIdSerializer = AssetIdSerializer();
final identityAssetIdSerializer = IdentitySerializer<AssetId>(
  assetIdSerializer,
);

@SerializersFor([AssetNode, PhasedAssetDeps, AssetDeps])
final Serializers serializers =
    (_$serializers.toBuilder()
          ..add(identityAssetIdSerializer)
          ..add(DigestSerializer())
          ..addBuilderFactory(
            const FullType(Set, [FullType(AssetId)]),
            () => <AssetId>{},
          )
          ..addBuilderFactory(
            postProcessBuildStepOutputsInnerFullType,
            () => <PostProcessBuildStepId, Set<AssetId>>{},
          )
          ..addBuilderFactory(
            postProcessBuildStepOutputsFullType,
            () => <String, Map<PostProcessBuildStepId, Set<AssetId>>>{},
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(Digest)]),
            ListBuilder<Digest>.new,
          )
          ..addBuilderFactory(
            const FullType(PhasedValue, [FullType(AssetDeps)]),
            PhasedValueBuilder<AssetDeps>.new,
          )
          ..addBuilderFactory(
            const FullType(ExpiringValue, [FullType(AssetDeps)]),
            ExpiringValueBuilder<AssetDeps>.new,
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [
              FullType(ExpiringValue, [FullType(AssetDeps)]),
            ]),
            ListBuilder<ExpiringValue<AssetDeps>>.new,
          ))
        .build();

/// Serializer for [AssetId].
///
/// It would also work to make `AssetId` a `built_value` class, but there's
/// little benefit and it's nicer to keep codegen local to this package.
class AssetIdSerializer implements PrimitiveSerializer<AssetId> {
  @override
  Iterable<Type> get types => [AssetId];

  @override
  String get wireName => 'AssetId';

  @override
  AssetId deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => AssetId.parse(serialized as String);

  @override
  Object serialize(
    Serializers serializers,
    AssetId object, {
    FullType specifiedType = FullType.unspecified,
  }) => object.toString();
}

/// Serializer for [Digest].
class DigestSerializer implements PrimitiveSerializer<Digest> {
  @override
  Iterable<Type> get types => [Digest];

  @override
  String get wireName => 'Digest';

  @override
  Digest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => Digest(base64.decode(serialized as String));

  @override
  Object serialize(
    Serializers serializers,
    Digest object, {
    FullType specifiedType = FullType.unspecified,
  }) => base64.encode(object.bytes);
}
