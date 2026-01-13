// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';

import 'builder_definition.dart';

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

  /// Whether there are factories for all definitions in [builderDefinitions].
  ///
  /// Factories must be of the correct type: post process builder or normal
  /// builder.
  bool hasFactoriesFor(Iterable<AbstractBuilderDefinition> builderDefinitions) {
    for (final builderDefinition in builderDefinitions) {
      switch (builderDefinition) {
        case BuilderDefinition _:
          if (!builderFactories.containsKey(builderDefinition.key)) {
            return false;
          }
        case PostProcessBuilderDefinition _:
          if (!postProcessBuilderFactories.containsKey(builderDefinition.key)) {
            return false;
          }
      }
    }
    return true;
  }
}
