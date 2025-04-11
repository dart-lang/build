// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
// ignore: implementation_import
import 'package:build/src/internal.dart';
import 'package:build_runner_core/src/asset_graph/serializers.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  final a1 = AssetId('a', '1');
  final a2 = AssetId('a', '2');
  final a3 = AssetId('a', '3');

  group('identity', () {
    setUp(() {
      identityAssetIdSerializer.reset();
      identityLibraryCycleGraphSerializer.reset();
    });

    group('AssetId', () {
      final testSerializers =
          (serializers.toBuilder()..addBuilderFactory(
                const FullType(BuiltList, [FullType(AssetId)]),
                ListBuilder<AssetId>.new,
              ))
              .build();

      final data = [a1, a2, a3, a1, a2, a3].build();
      final serialized = [0, 1, 2, 0, 1, 2];
      final serializedObjects = ['a|1', 'a|2', 'a|3'];

      test('serialize', () {
        expect(
          testSerializers.serialize(
            data,
            specifiedType: const FullType(BuiltList, [FullType(AssetId)]),
          ),
          serialized,
        );
        expect(
          identityAssetIdSerializer.serializedObjects(serializers),
          serializedObjects,
        );
      });

      test('deserialize', () {
        identityAssetIdSerializer.deserializeObjects(serializedObjects);
        expect(
          testSerializers.deserialize(
            serialized,
            specifiedType: const FullType(BuiltList, [FullType(AssetId)]),
          ),
          data,
        );
      });
    });

    group('LibraryCycleGraph flat', () {
      final testSerializers =
          (serializers.toBuilder()..addBuilderFactory(
                const FullType(BuiltList, [FullType(LibraryCycleGraph)]),
                ListBuilder<LibraryCycleGraph>.new,
              ))
              .build();

      final g1 = LibraryCycleGraph((b) => b..root.ids.add(a1));
      final g2 = LibraryCycleGraph((b) => b..root.ids.add(a2));
      final g3 = LibraryCycleGraph((b) => b..root.ids.add(a3));
      final data = [g1, g2, g3, g1, g2, g3].build();
      final serialized = [0, 1, 2, 0, 1, 2];
      final serializedObjects =
          json.decode(
                '[["root",["ids",[0]],"children",[]],'
                '["root",["ids",[1]],"children",[]],'
                '["root",["ids",[2]],"children",[]]]',
              )
              as List<Object?>;
      final assetIdSerializedObjects = ['a|1', 'a|2', 'a|3'];

      test('serialize', () {
        expect(
          serializers.serialize(
            data,
            specifiedType: const FullType(BuiltList, [
              FullType(LibraryCycleGraph),
            ]),
          ),
          serialized,
        );
        expect(
          identityLibraryCycleGraphSerializer.serializedObjects(serializers),
          serializedObjects,
        );
      });

      test('deserialize', () {
        identityAssetIdSerializer.deserializeObjects(assetIdSerializedObjects);
        identityLibraryCycleGraphSerializer.deserializeObjects(
          serializedObjects,
        );
        expect(
          testSerializers.deserialize(
            serialized,
            specifiedType: const FullType(BuiltList, [
              FullType(LibraryCycleGraph),
            ]),
          ),
          data,
        );
      });
    });

    group('LibraryCycleGraph nested', () {
      final testSerializers =
          (serializers.toBuilder()..addBuilderFactory(
                const FullType(BuiltList, [FullType(LibraryCycleGraph)]),
                ListBuilder<LibraryCycleGraph>.new,
              ))
              .build();

      final g1 = LibraryCycleGraph((b) => b..root.ids.add(a1));
      final g2 = LibraryCycleGraph(
        (b) =>
            b
              ..root.ids.add(a2)
              ..children.add(g1),
      );
      final g3 = LibraryCycleGraph(
        (b) =>
            b
              ..root.ids.add(a3)
              ..children.add(g2),
      );
      final data = [g1, g2, g3, g1, g2, g3].build();
      final serialized = [0, 1, 2, 0, 1, 2];
      final serializedObjects =
          json.decode(
                '[["root",["ids",[0]],"children",[]],'
                '["root",["ids",[1]],"children",[0]],'
                '["root",["ids",[2]],"children",[1]]]',
              )
              as List<Object?>;

      final assetIdSerializedObjects = ['a|1', 'a|2', 'a|3'];

      test('serialize', () {
        expect(
          serializers.serialize(
            data,
            specifiedType: const FullType(BuiltList, [
              FullType(LibraryCycleGraph),
            ]),
          ),
          serialized,
        );
        expect(
          identityLibraryCycleGraphSerializer.serializedObjects(serializers),
          serializedObjects,
        );
      });

      test('deserialize', () {
        identityAssetIdSerializer.deserializeObjects(assetIdSerializedObjects);
        identityLibraryCycleGraphSerializer.deserializeObjects(
          serializedObjects,
        );
        expect(
          testSerializers.deserialize(
            serialized,
            specifiedType: const FullType(BuiltList, [
              FullType(LibraryCycleGraph),
            ]),
          ),
          data,
        );
      });
    });

    group('LibraryCycleGraph deeply nested', () {
      final size = 1000;
      final testSerializers =
          (serializers.toBuilder()..addBuilderFactory(
                const FullType(BuiltList, [FullType(LibraryCycleGraph)]),
                ListBuilder<LibraryCycleGraph>.new,
              ))
              .build();

      final assetIds = [
        for (var i = 0; i != size; ++i) AssetId('a', '${i + 1}'),
      ];
      final graphs = <LibraryCycleGraph>[];
      for (var i = 0; i != size; ++i) {
        graphs.add(
          LibraryCycleGraph((b) {
            b.root.ids.add(assetIds[i]);
            if (i < size) b.children.add(graphs[i - 1]);
          }),
        );
      }
      final data = [graphs[0], graphs[0]].build();
      final serialized = [0, 0].build();
      final serializedObjects = [
        for (var i = 0; i != size; ++i)
          [
            'root',
            [
              'ids',
              [i],
            ],
            'children',
            [if (i < size - 1) i + 1],
          ],
      ];
      final assetIdSerializedObjects = [
        for (var i = 0; i != size; ++i) 'a|${i + 1}',
      ];

      test('serialize', () {
        expect(
          serializers.serialize(
            data,
            specifiedType: const FullType(BuiltList, [
              FullType(LibraryCycleGraph),
            ]),
          ),
          serialized,
        );
        expect(
          identityLibraryCycleGraphSerializer.serializedObjects(serializers),
          serializedObjects,
        );
      });

      test('deserialize', () {
        identityAssetIdSerializer.deserializeObjects(assetIdSerializedObjects);
        identityLibraryCycleGraphSerializer.deserializeObjects(
          serializedObjects,
        );
        final deserialized = testSerializers.deserialize(
          serialized,
          specifiedType: const FullType(BuiltList, [
            FullType(LibraryCycleGraph),
          ]),
        );
        expect(deserialized == data, isTrue);
      });
    });
  });
}
