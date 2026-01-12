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

/// A [BuilderDefinition] or a [PostProcessBuilderDefinition].
sealed class AbstractBuilderDefinition {
  /// The builder key in the form `package:name`.
  String get key;

  /// The package the builder is in.
  String get package;

  /// The defaults specified in `build.yaml` for this builder.
  TargetBuilderConfigDefaults get targetBuilderConfigDefaults;

  /// Loads [BuilderDefinition]s for the configuration in `build.yaml` in
  /// each package in [packageGraph].
  static Future<BuiltList<AbstractBuilderDefinition>> load({
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

    final result = ListBuilder<AbstractBuilderDefinition>();
    for (final builder in orderedBuilders) {
      result.add(BuilderDefinition.fromConfig(builder));
    }
    for (final builder in postProcessBuilderDefinitions) {
      result.add(PostProcessBuilderDefinition.fromConfig(builder));
    }
    return result.build();
  }
}

/// A builder definition read from `build.yaml` using
/// [build_config.BuilderDefinition].
class BuilderDefinition implements AbstractBuilderDefinition {
  @override
  final String key;

  @override
  final String package;

  @override
  final TargetBuilderConfigDefaults targetBuilderConfigDefaults;

  /// Determines which packages a builder is automatically applied to.
  final AutoApply autoApply;

  /// Builder keys which, when applied to a target, will also apply this Builder
  /// even if [autoApply] does not match.
  final BuiltList<String> appliesBuilders;

  /// Whether generated assets should be placed in the build cache.
  final bool hideOutput;

  /// Whether the builder is skipped if nothing uses its output.
  final bool isOptional;

  @visibleForTesting
  BuilderDefinition(
    this.key, {
    String? package,
    this.autoApply = AutoApply.rootPackage,
    Iterable<String> appliesBuilders = const [],
    this.hideOutput = true,
    this.isOptional = false,
    this.targetBuilderConfigDefaults = const TargetBuilderConfigDefaults(),
  }) : package = package ?? (key.contains(':') ? key.split(':').first : ''),
       appliesBuilders = appliesBuilders.toBuiltList();

  factory BuilderDefinition.fromConfig(
    build_config.BuilderDefinition builderDefinition,
  ) => BuilderDefinition(
    builderDefinition.key,
    package: builderDefinition.package,
    autoApply: builderDefinition.autoApply,
    appliesBuilders: builderDefinition.appliesBuilders,
    hideOutput: builderDefinition.buildTo == build_config.BuildTo.cache,
    isOptional: builderDefinition.isOptional,
    targetBuilderConfigDefaults: builderDefinition.defaults,
  );

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
}

/// A post process builder definition read from `build.yaml` using
/// [build_config.PostProcessBuilderDefinition]
class PostProcessBuilderDefinition implements AbstractBuilderDefinition {
  @override
  final String key;

  @override
  final String package;

  @override
  final TargetBuilderConfigDefaults targetBuilderConfigDefaults;

  @visibleForTesting
  PostProcessBuilderDefinition(
    this.key, {
    String? package,
    this.targetBuilderConfigDefaults = const TargetBuilderConfigDefaults(),
  }) : package = package ?? (key.contains(':') ? key.split(':').first : '');

  PostProcessBuilderDefinition.fromConfig(
    build_config.PostProcessBuilderDefinition builderDefinition,
  ) : package = builderDefinition.package,
      key = builderDefinition.key,
      targetBuilderConfigDefaults = builderDefinition.defaults;
}
