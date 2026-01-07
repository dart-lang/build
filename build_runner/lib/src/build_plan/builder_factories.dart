// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart' as build_config;
import 'package:built_collection/built_collection.dart';
import 'package:graphs/graphs.dart';
import 'package:meta/meta.dart';

import '../io/reader_writer.dart';
import 'builder_application.dart';
import 'builder_ordering.dart';
import 'package_graph.dart';
import 'target_graph.dart';

/// The builder code plugged into `build_runner`.
class BuilderFactories {
  /// Builder factories by builder key.
  final BuiltMap<String, BuiltList<BuilderFactory>> builderFactories;

  /// Post process builder factories by builder key.
  final BuiltMap<String, PostProcessBuilderFactory> postProcessBuilderFactories;

  BuilderFactories({
    Map<String, List<BuilderFactory>>? builderFactories,
    Map<String, PostProcessBuilderFactory>? postProcessBuilderFactories,
  }) : builderFactories =
           (builderFactories ?? {})
               .map<String, BuiltList<BuilderFactory>>(
                 (k, v) => MapEntry(k, v.build()),
               )
               .build(),
       postProcessBuilderFactories =
           (postProcessBuilderFactories ?? {}).build();

  /// Creates with one empty-named builder for use with `testPhases`.
  @visibleForTesting
  factory BuilderFactories.forTesting(Builder builder) => BuilderFactories(
    builderFactories: {
      '': [(_) => builder],
    },
  );

  /// Creates [BuilderDefinition]s for the configuration in `build.yaml` in
  /// each package in [packageGraph].
  ///
  /// The builders specified in the configuration must be present in
  /// [builderFactories] or [postProcessBuilderFactories]. If they are not,
  /// `null` is returned to indicate that the current build script is out of
  /// date and a restart is needed.
  /// TODO: move out
  static Future<BuiltList<BuilderDefinition>?> createBuilderApplications({
    required PackageGraph packageGraph,
    required ReaderWriter readerWriter,
  }) async {
    final orderedPackages = stronglyConnectedComponents<PackageNode>(
      [packageGraph.root],
      (node) => node.dependencies,
      equals: (a, b) => a.name == b.name,
      hashCode: (n) => n.name.hashCode,
    ).expand((c) => c);
    final overrides = await findBuildConfigOverrides(
      packageGraph: packageGraph,
      readerWriter: readerWriter,
      configKey: null,
    );

    Future<build_config.BuildConfig> packageBuildConfig(
      PackageNode package,
    ) async {
      if (overrides.containsKey(package.name)) {
        return overrides[package.name]!;
      }
      try {
        return await build_config.BuildConfig.fromBuildConfigDir(
          package.name,
          package.dependencies.map((n) => n.name),
          package.path,
        );
      } on ArgumentError // ignore: avoid_catching_errors
      catch (_) {
        // During the build an error will be logged.
        return build_config.BuildConfig.useDefault(
          package.name,
          package.dependencies.map((n) => n.name),
        );
      }
    }

    bool isPackageImportOrForRoot(dynamic definition) {
      // ignore: avoid_dynamic_calls
      final import = definition.import as String;
      // ignore: avoid_dynamic_calls
      final package = definition.package as String;
      return import.startsWith('package:') || package == packageGraph.root.name;
    }

    final orderedConfigs = await Future.wait(
      orderedPackages.map(packageBuildConfig),
    );
    final builderDefinitions = orderedConfigs
        .expand((c) => c.builderDefinitions.values)
        .where(isPackageImportOrForRoot);

    final rootBuildConfig = orderedConfigs.last;
    final orderedBuilders =
        findBuilderOrder(
          builderDefinitions,
          rootBuildConfig.globalOptions,
        ).toList();

    final postProcessBuilderDefinitions = orderedConfigs
        .expand((c) => c.postProcessBuilderDefinitions.values)
        .where(isPackageImportOrForRoot);

    final result = ListBuilder<BuilderDefinition>();
    for (final builder in orderedBuilders) {
      result.add(BuilderDefinition(builder));
    }
    for (final builder in postProcessBuilderDefinitions) {
      result.add(BuilderDefinition.postProcess(builder));
    }
    return result.build();
  }
}
