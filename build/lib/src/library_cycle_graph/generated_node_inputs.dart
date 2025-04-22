// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../asset/id.dart';

part 'generated_node_inputs.g.dart';

abstract class GeneratedNodeInputs
    implements Built<GeneratedNodeInputs, GeneratedNodeInputsBuilder> {
  static Serializer<GeneratedNodeInputs> get serializer =>
      _$generatedNodeInputsSerializer;

  BuiltSet<AssetId> get assets;
  BuiltSet<AssetId> get graphs;
  BuiltSet<AssetId> get unused;

  factory GeneratedNodeInputs([
    void Function(GeneratedNodeInputsBuilder) updates,
  ]) = _$GeneratedNodeInputs;
  GeneratedNodeInputs._();

  bool get isNotEmpty =>
      // TODO(davidmorgan): what about "unused"?
      assets.isNotEmpty || graphs.isNotEmpty;
}
