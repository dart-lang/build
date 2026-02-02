// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_config/build_config.dart'
    show AutoApply, TargetBuilderConfigDefaults;
import 'package:build_config/build_config.dart' as build_config;
import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

import '../io/reader_writer.dart';
import 'build_configs.dart';
import 'build_package.dart';
import 'build_packages.dart';
import 'builder_ordering.dart';

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
  /// each package in [buildPackages].
  static Future<BuiltList<AbstractBuilderDefinition>> load({
    required BuildPackages buildPackages,
    required ReaderWriter readerWriter,
  }) async {
    final overrides = await findBuildConfigOverrides(
      buildPackages: buildPackages,
      readerWriter: readerWriter,
      configKey: null,
    );

    Future<build_config.BuildConfig> packageBuildConfig(
      String packageName,
    ) async {
      if (overrides.containsKey(packageName)) {
        return overrides[packageName]!;
      }
      final package = buildPackages[packageName]!;
      try {
        return await build_config.BuildConfig.fromBuildConfigDir(
          package.name,
          package.dependencies,
          package.path,
        );
      } on ArgumentError // ignore: avoid_catching_errors
      catch (_) {
        // During the build an error will be logged.
        return build_config.BuildConfig.useDefault(
          package.name,
          package.dependencies,
        );
      }
    }

    final orderedConfigs = await Future.wait(
      buildPackages.orderedPackages.map(packageBuildConfig),
    );
    final builderDefinitions = orderedConfigs
        .expand((c) => c.builderDefinitions.values)
        .where(
          (c) =>
              c.import.startsWith('package:') ||
              c.package == buildPackages.outputRoot,
        );

    final rootBuildConfig = orderedConfigs.last;
    final orderedBuilders =
        findBuilderOrder(
          builderDefinitions,
          rootBuildConfig.globalOptions,
        ).toList();

    final postProcessBuilderDefinitions = orderedConfigs
        .expand((c) => c.postProcessBuilderDefinitions.values)
        .where(
          (c) =>
              c.import.startsWith('package:') ||
              c.package == buildPackages.outputRoot,
        );

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
  ///
  /// If [restrictForWorkspacePackages], turns on more precise checking for the
  /// newer "whole workspace" build mode. These checks are also correct for real
  /// builds in "single output package" mode, but would cause problems for tests
  /// because fake test setups are used that do not add the correct dependencies
  /// onto builders.
  bool autoAppliesTo(
    BuildPackage package, {
    BuildPackages? restrictForWorkspacePackages,
  }) {
    switch (autoApply) {
      case AutoApply.none:
        return false;
      case AutoApply.allPackages:
        // In a workspace build, "allPackages" means "all peer packages". See
        // `peersOf` for the definition.
        return restrictForWorkspacePackages == null
            ? true
            : restrictForWorkspacePackages
                .peersOf(package.name)
                .contains(this.package);
      case AutoApply.rootPackage:
        // In a workspace build, "root package" means an output package that
        // depends transitively on the builder.
        return package.isOutput &&
            (restrictForWorkspacePackages == null ||
                restrictForWorkspacePackages
                    .transitiveDepsOf(package.name)
                    .contains(this.package));
      case AutoApply.dependents:
        return package.dependencies.contains(this.package);
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
