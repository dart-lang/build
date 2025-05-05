// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart' show AssetId, PostProcessBuildStep;
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:crypto/crypto.dart';

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
          ..add(MapSerializer())
          ..add(SetSerializer())
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

// TODO(davidmorgan): this is a fork of `BuiltMapSerializer` from `built_value`
// adapted for SDK maps, upstream it.
class MapSerializer implements StructuredSerializer<Map> {
  final bool structured = true;
  @override
  final Iterable<Type> types = BuiltList<Type>([
    Map,
    <Object, Object>{}.runtimeType,
  ]);
  @override
  final String wireName = 'map';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    Map builtMap, {
    FullType specifiedType = FullType.unspecified,
  }) {
    var isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);

    var keyType =
        specifiedType.parameters.isEmpty
            ? FullType.unspecified
            : specifiedType.parameters[0];
    var valueType =
        specifiedType.parameters.isEmpty
            ? FullType.unspecified
            : specifiedType.parameters[1];

    var result = <Object?>[];
    for (var key in builtMap.keys) {
      result.add(serializers.serialize(key, specifiedType: keyType));
      final value = builtMap[key];
      result.add(serializers.serialize(value, specifiedType: valueType));
    }
    return result;
  }

  @override
  Map deserialize(
    Serializers serializers,
    Iterable serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    var isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;

    var keyType =
        specifiedType.parameters.isEmpty
            ? FullType.unspecified
            : specifiedType.parameters[0];
    var valueType =
        specifiedType.parameters.isEmpty
            ? FullType.unspecified
            : specifiedType.parameters[1];

    var result =
        isUnderspecified
            ? <Object, Object>{}
            : serializers.newBuilder(specifiedType) as Map;

    if (serialized.length.isOdd) {
      throw ArgumentError('odd length');
    }

    for (var i = 0; i != serialized.length; i += 2) {
      final key = serializers.deserialize(
        serialized.elementAt(i),
        specifiedType: keyType,
      );
      final value = serializers.deserialize(
        serialized.elementAt(i + 1),
        specifiedType: valueType,
      );
      result[key] = value;
    }

    return result;
  }
}

// TODO(davidmorgan): this is a fork of `BuiltSetSerializer` from `built_value`
// adapted for SDK sets, upstream it.
class SetSerializer implements StructuredSerializer<Set> {
  final bool structured = true;
  @override
  final Iterable<Type> types = BuiltList<Type>([Set, <Object>{}.runtimeType]);
  @override
  final String wireName = 'set';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    Set builtSet, {
    FullType specifiedType = FullType.unspecified,
  }) {
    var isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);

    var elementType =
        specifiedType.parameters.isEmpty
            ? FullType.unspecified
            : specifiedType.parameters[0];

    return builtSet.map(
      (item) => serializers.serialize(item, specifiedType: elementType),
    );
  }

  @override
  Set deserialize(
    Serializers serializers,
    Iterable serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    var isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;

    var elementType =
        specifiedType.parameters.isEmpty
            ? FullType.unspecified
            : specifiedType.parameters[0];
    var result =
        isUnderspecified
            ? <Object>{}
            : serializers.newBuilder(specifiedType) as Set;

    for (final item in serialized) {
      result.add(serializers.deserialize(item, specifiedType: elementType));
    }

    return result;
  }
}
