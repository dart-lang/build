// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart' as build_config;
import 'package:built_collection/built_collection.dart';
import 'package:graphs/graphs.dart';

import '../io/reader_writer.dart';
import 'builder_definition.dart';
import 'builder_ordering.dart';
import 'package_graph.dart';
import 'target_graph.dart';

/// The builder code plugged into `build_runner`.
class BuilderFactories {
  /// Builder factories by builder key.
  final BuiltMap<String, BuiltList<BuilderFactory>> builderFactories;

  /// Post process builder factories by builder key.
  final BuiltMap<String, PostProcessBuilderFactory> postProcessBuilderFactories;

  BuilderFactories(
    Map<String, List<BuilderFactory>> builderFactories, {
    Map<String, PostProcessBuilderFactory>? postProcessBuilderFactories,
  }) : builderFactories =
           builderFactories
               .map<String, BuiltList<BuilderFactory>>(
                 (k, v) => MapEntry(k, v.build()),
               )
               .build(),
       postProcessBuilderFactories =
           (postProcessBuilderFactories ?? {}).build();

  bool hasBuilder(String key) =>
      builderFactories.containsKey(key) ||
      postProcessBuilderFactories.containsKey(key);
}
