// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import 'deps_node.dart';

part 'deps_cycle.g.dart';

abstract class DepsCycle implements Built<DepsCycle, DepsCycleBuilder> {
  BuiltSet<DepsNode> get nodes;

  factory DepsCycle([void Function(DepsCycleBuilder) updates]) = _$DepsCycle;
  DepsCycle._();
}
