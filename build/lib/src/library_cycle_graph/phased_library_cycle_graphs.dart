// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../asset/id.dart';
import 'library_cycle_graph.dart';
import 'phased_value.dart';

part 'phased_library_cycle_graphs.g.dart';

/// The ful
abstract class PhasedLibraryCycleGraphs
    implements
        Built<PhasedLibraryCycleGraphs, PhasedLibraryCycleGraphsBuilder> {
  static Serializer<PhasedLibraryCycleGraphs> get serializer =>
      _$phasedLibraryCycleGraphsSerializer;

  BuiltMap<AssetId, PhasedValue<LibraryCycleGraph>> get graphs;

  factory PhasedLibraryCycleGraphs(
    void Function(PhasedLibraryCycleGraphsBuilder) b,
  ) = _$PhasedLibraryCycleGraphs;
  PhasedLibraryCycleGraphs._();
}
