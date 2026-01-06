// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:built_collection/built_collection.dart';
import 'package:graphs/graphs.dart';

import '../io/reader_writer.dart';
import 'apply_builders.dart';
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

  /// Creates [BuilderApplication]s for the configuration in `build.yaml` in
  /// each package in [packageGraph].
  ///
  /// The builders specified in the configuration must be present in
  /// [builderFactories] or [postProcessBuilderFactories]. If they are not,
  /// `null` is returned to indicate that the current build script is out of
  /// date and a restart is needed.
  Future<BuiltList<BuilderApplication>?> createBuilderApplications({
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

    Future<BuildConfig> packageBuildConfig(PackageNode package) async {
      if (overrides.containsKey(package.name)) {
        return overrides[package.name]!;
      }
      try {
        return await BuildConfig.fromBuildConfigDir(
          package.name,
          package.dependencies.map((n) => n.name),
          package.path,
        );
      } on ArgumentError // ignore: avoid_catching_errors
      catch (_) {
        // During the build an error will be logged.
        return BuildConfig.useDefault(
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

    final result = ListBuilder<BuilderApplication>();
    for (final builder in orderedBuilders) {
      final factory = builderFactories[builder.key];
      if (factory == null) return null;
      result.add(_applyBuilder(builder, factory));
    }
    for (final builder in postProcessBuilderDefinitions) {
      final factory = postProcessBuilderFactories[builder.key];
      if (factory == null) return null;
      result.add(_applyPostProcessBuilder(builder, factory));
    }
    return result.build();
  }
}

BuilderApplication _applyBuilder(
  BuilderDefinition definition,
  BuiltList<BuilderFactory> builderFactories,
) {
  return apply(
    definition.package,
    definition.key,
    builderFactories,
    definition.autoApply,
    isOptional: definition.isOptional,
    hideOutput: definition.buildTo == BuildTo.cache,
    defaultGenerateFor: definition.defaults.generateFor,
    defaultOptions: BuilderOptions(definition.defaults.options),
    defaultDevOptions: BuilderOptions(definition.defaults.devOptions),
    defaultReleaseOptions: BuilderOptions(definition.defaults.releaseOptions),
    appliesBuilders: definition.appliesBuilders,
  );
}

BuilderApplication _applyPostProcessBuilder(
  PostProcessBuilderDefinition definition,
  PostProcessBuilderFactory postProcessBuilderFactory,
) {
  return applyPostProcess(
    definition.package,
    definition.key,
    postProcessBuilderFactory,
    defaultGenerateFor: definition.defaults.generateFor,
    defaultOptions: BuilderOptions(definition.defaults.options),
    defaultDevOptions: BuilderOptions(definition.defaults.devOptions),
    defaultReleaseOptions: BuilderOptions(definition.defaults.releaseOptions),
  );
}
