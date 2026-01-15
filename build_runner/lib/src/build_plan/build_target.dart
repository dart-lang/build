// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart' as build_config;
import 'package:built_collection/built_collection.dart';
import 'package:glob/glob.dart';

import 'input_matcher.dart';

/// A build target specified in `build.yaml` to apply and/or configure builders.
class BuildTarget {
  final String package;
  final String key;

  final bool autoApplyBuilders;
  final BuiltMap<String, build_config.TargetBuilderConfig> builders;
  final BuiltList<String> dependencies;
  final build_config.InputSet sources;

  final InputMatcher _sourcesMatcher;

  BuildTarget(
    build_config.BuildTarget buildTarget, {
    required BuiltList<String> defaultInclude,
  }) : package = buildTarget.package,
       key = buildTarget.key,
       autoApplyBuilders = buildTarget.autoApplyBuilders,
       builders = buildTarget.builders.build(),
       dependencies = buildTarget.dependencies.build(),
       sources = buildTarget.sources,
       _sourcesMatcher = InputMatcher(
         buildTarget.sources,
         defaultInclude: defaultInclude,
       );

  List<Glob> get sourceIncludes =>
      // Never null because `defaultInclude` was passed.
      _sourcesMatcher.includeGlobs!;

  bool excludesSource(AssetId id) => _sourcesMatcher.excludes(id);

  bool matchesSource(AssetId id) => _sourcesMatcher.matches(id);

  @override
  String toString() => key;
}
