// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_config/build_config.dart' as build_config;
import 'package:build_config/build_config.dart'
    show AutoApply, TargetBuilderConfigDefaults;

import 'package:built_collection/built_collection.dart';
import 'package:graphs/graphs.dart';
import 'package:meta/meta.dart';

import '../io/reader_writer.dart';
import 'builder_ordering.dart';
import 'package_graph.dart';
import 'target_graph.dart';

export 'package:build_config/build_config.dart'
    show AutoApply, TargetBuilderConfigDefaults;

/// A builder definition read from `build.yaml` using
/// [build_config.BuilderDefinition] or
/// [build_config.PostProcessBuilderDefinition].
class BuilderDefinition {
  /// Whether this is a post process builder.
  ///
  /// If so, [hideOutput] is always `true`, [isOptional] is always false and
  /// [autoApply] is always [AutoApply.none].
  final bool isPostProcessBuilder;

  /// The package the builder is in.
  final String package;

  /// The builder key in the form `package:name`.
  final String key;

  /// Determines which packages a builder is automatically applied to.
  final AutoApply autoApply;

  /// Builder keys which, when applied to a target, will also apply this Builder
  /// even if [autoApply] does not match.
  final BuiltList<String> appliesBuilders;

  /// Whether generated assets should be placed in the build cache.
  final bool hideOutput;

  /// Whether the builder is skipped if nothing uses its output.
  final bool isOptional;

  /// The defaults specified in `build.yaml` for this builder.
  final TargetBuilderConfigDefaults targetBuilderConfigDefaults;

  @visibleForTesting
  BuilderDefinition(
    this.key, {
    this.isPostProcessBuilder = false,
    String? package,
    AutoApply autoApply = AutoApply.rootPackage,
    Iterable<String> appliesBuilders = const [],
    bool hideOutput = true,
    bool isOptional = false,
    this.targetBuilderConfigDefaults = const TargetBuilderConfigDefaults(),
  }) : appliesBuilders = appliesBuilders.toBuiltList(),
       autoApply = isPostProcessBuilder ? AutoApply.none : autoApply,
       package = package ?? (key.contains(':') ? key.split(':').first : ''),
       hideOutput = isPostProcessBuilder ? true : hideOutput,
       isOptional = isPostProcessBuilder ? false : isOptional;

  BuilderDefinition.fromConfig(build_config.BuilderDefinition builderDefinition)
    : isPostProcessBuilder = false,
      package = builderDefinition.package,
      key = builderDefinition.key,
      autoApply = builderDefinition.autoApply,
      appliesBuilders = builderDefinition.appliesBuilders.build(),
      hideOutput = builderDefinition.buildTo == build_config.BuildTo.cache,
      isOptional = builderDefinition.isOptional,
      targetBuilderConfigDefaults = builderDefinition.defaults;

  BuilderDefinition.fromPostProcessConfig(
    build_config.PostProcessBuilderDefinition builderDefinition,
  ) : isPostProcessBuilder = true,
      package = builderDefinition.package,
      key = builderDefinition.key,
      autoApply = build_config.AutoApply.allPackages,
      appliesBuilders = BuiltList(),
      hideOutput = true,
      isOptional = false,
      targetBuilderConfigDefaults = builderDefinition.defaults;

  /// Whether this builder application is auto applied to [package].
  bool autoAppliesTo(PackageNode package) {
    switch (autoApply) {
      case AutoApply.none:
        return false;
      case AutoApply.allPackages:
        return true;
      case AutoApply.rootPackage:
        return package.isRoot;
      case AutoApply.dependents:
        return package.dependencies.any((p) => p.name == this.package);
    }
  }

  /// Loads [BuilderDefinition]s for the configuration in `build.yaml` in
  /// each package in [packageGraph].
  static Future<BuiltList<BuilderDefinition>> load({
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
      result.add(BuilderDefinition.fromConfig(builder));
    }
    for (final builder in postProcessBuilderDefinitions) {
      result.add(BuilderDefinition.fromPostProcessConfig(builder));
    }
    return result.build();
  }
}
