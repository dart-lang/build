// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart' as build_config;
import 'package:built_collection/built_collection.dart';
import 'package:graphs/graphs.dart';

import '../exceptions.dart';
import '../logging/build_log.dart';
import '../logging/build_log_logger.dart';
import 'build_phases.dart';
import 'builder_definition.dart';
import 'builder_factories.dart';
import 'phase.dart';
import 'target_graph.dart';

/// Creates [BuildPhases] from [BuilderDefinition]s.
class BuildPhaseCreator {
  final BuilderFactories builderFactories;
  final TargetGraph targetGraph;
  final BuiltList<BuilderDefinition> builderDefinitions;
  final BuiltMap<String, BuiltMap<String, dynamic>> builderConfigOverrides;
  final bool isReleaseBuild;

  final Map<String, BuilderDefinition> _builderDefinitionByKey = {};

  /// For each builder key, the builders that apply that builder.
  ///
  /// This is the reverse of what is specified in `build.yaml`, which is the
  /// list of applied builders for each builder.
  final Map<String, List<BuilderDefinition>> _builderAppliersByKey = {};

  BuildPhaseCreator({
    required this.builderFactories,
    required this.targetGraph,
    required Iterable<BuilderDefinition> builderDefinitions,
    required this.builderConfigOverrides,
    required this.isReleaseBuild,
  }) : builderDefinitions = builderDefinitions.toBuiltList() {
    for (final builderDefinition in builderDefinitions) {
      _builderDefinitionByKey[builderDefinition.key] = builderDefinition;
      for (final alsoApply in builderDefinition.appliesBuilders) {
        _builderAppliersByKey
            .putIfAbsent(alsoApply, () => [])
            .add(builderDefinition);
      }
    }
  }

  /// Creates a [BuildPhase] to apply each builder in [builderDefinitions] to
  /// each target in [targetGraph] such that all builders are run for
  /// dependencies before moving on to later packages.
  ///
  /// When there is a package cycle the builders are applied to each packages
  /// within the cycle before moving on to packages that depend on any package
  /// within the cycle.
  ///
  /// Builders may be filtered, for instance to run only on package which have a
  /// dependency on some other package by choosing the appropriate
  /// [BuilderDefinition].
  Future<BuildPhases> createBuildPhases() async {
    warnForUnknownBuilders(
      builderDefinitions,
      targetGraph.rootPackageConfig,
      builderConfigOverrides,
    );
    final globalOptions = targetGraph.rootPackageConfig.globalOptions.map(
      (key, config) => MapEntry(
        key,
        config.options.toBuilderOptions().overrideWith(
          isReleaseBuild
              ? config.releaseOptions.toBuilderOptions()
              : config.devOptions.toBuilderOptions(),
        ),
      ),
    );
    for (final key in builderConfigOverrides.keys) {
      final overrides = BuilderOptions(builderConfigOverrides[key]!.asMap());
      globalOptions[key] = (globalOptions[key] ?? BuilderOptions.empty)
          .overrideWith(overrides);
    }

    final cycles = stronglyConnectedComponents<TargetNode>(
      targetGraph.allModules.values,
      (node) => node.target.dependencies.map((key) {
        if (!targetGraph.allModules.containsKey(key)) {
          buildLog.error(
            '${node.target.key} declares a dependency on $key '
            'but it does not exist.',
          );
          throw const CannotBuildException();
        }
        return targetGraph.allModules[key]!;
      }),
      equals: (a, b) => a.target.key == b.target.key,
      hashCode: (node) => node.target.key.hashCode,
    );

    final inBuildPhases = <InBuildPhase>[];
    final postBuildActions = <PostBuildAction>[];
    for (final cycle in cycles) {
      for (final builderDefinition in builderDefinitions) {
        if (builderDefinition.isPostProcessBuilder) {
          postBuildActions.addAll(
            _createPostBuildActions(
              cycle,
              builderDefinition,
              globalOptions[builderDefinition.key] ?? BuilderOptions.empty,
            ),
          );
        } else {
          inBuildPhases.addAll(
            _createInBuildPhases(
              cycle,
              builderDefinition,
              globalOptions[builderDefinition.key] ?? BuilderOptions.empty,
            ),
          );
        }
      }
    }

    return BuildPhases(
      inBuildPhases,
      postBuildActions.isEmpty ? null : PostBuildPhase(postBuildActions),
    );
  }

  List<InBuildPhase> _createInBuildPhases(
    Iterable<TargetNode> cycle,
    BuilderDefinition builderDefinition,
    BuilderOptions globalOptionOverrides,
  ) {
    final builderFactories =
        this.builderFactories.builderFactories[builderDefinition.key]!;
    final result = <InBuildPhase>[];
    for (final builderFactory in builderFactories) {
      for (final node in cycle) {
        if (!_shouldApply(builderDefinition, node)) continue;

        final builderConfig = builderDefinition.targetBuilderConfigDefaults;
        final targetConfig = node.target.builders[builderDefinition.key];
        final options = _createOptions(
          builderConfig: builderConfig,
          targetConfig: targetConfig,
          globalOptionOverrides: globalOptionOverrides,
          isRoot: node.package.isRoot,
        );

        final builder = BuildLogLogger.scopeLogSync(
          () => builderFactory(options),
          buildLog.loggerForOther(builderDefinition.key),
        );
        if (builder == null) throw const CannotBuildException();
        _validateBuilder(builder);

        result.add(
          InBuildPhase(
            builder: builder,
            key: builderDefinition.key,
            package: node.package.name,
            targetSources: node.target.sources,
            generateFor: targetConfig?.generateFor ?? builderConfig.generateFor,
            options: options,
            hideOutput: builderDefinition.hideOutput,
            isOptional: builderDefinition.isOptional,
          ),
        );
      }
    }
    return result;
  }

  List<PostBuildAction> _createPostBuildActions(
    Iterable<TargetNode> cycle,
    BuilderDefinition builderDefinition,
    BuilderOptions globalOptionOverrides,
  ) {
    final postProcessBuilderFactory =
        builderFactories.postProcessBuilderFactories[builderDefinition.key]!;
    final result = <PostBuildAction>[];
    for (final node in cycle) {
      if (!_shouldApply(builderDefinition, node)) continue;

      final builderConfig = builderDefinition.targetBuilderConfigDefaults;
      final targetConfig = node.target.builders[builderDefinition.key];
      final options = _createOptions(
        builderConfig: builderConfig,
        targetConfig: targetConfig,
        globalOptionOverrides: globalOptionOverrides,
        isRoot: node.package.isRoot,
      );

      final builder = BuildLogLogger.scopeLogSync(
        () => postProcessBuilderFactory(options),
        buildLog.loggerForOther(builderDefinition.key),
      );
      if (builder == null) throw const CannotBuildException();
      _validatePostProcessBuilder(builder);

      final builderAction = PostBuildAction(
        builder: builder,
        package: node.package.name,
        options: options,
        generateFor: targetConfig?.generateFor ?? builderConfig.generateFor,
        targetSources: node.target.sources,
      );
      result.add(builderAction);
    }

    return result;
  }

  /// Creates builder options using a series of overrides.
  ///
  /// Lowest priority are the defaults from the builder's `build.yaml` passed
  /// in [builderConfig].
  ///
  /// Then, release-specific or dev-specific options in [builderConfig].
  ///
  /// Then, options in the target `build.yaml`, passed in [targetConfig].
  ///
  /// Then, release-specific or dev-specific options in the target `build.yaml`.
  ///
  /// Finally, [globalOptionOverrides] are highest priority and override
  /// anything.
  ///
  /// [BuilderOptions.isRoot] is set to [isRoot].
  BuilderOptions _createOptions({
    required TargetBuilderConfigDefaults builderConfig,
    required build_config.TargetBuilderConfig? targetConfig,
    required BuilderOptions globalOptionOverrides,
    required bool isRoot,
  }) {
    var result = BuilderOptions(builderConfig.options)
        .overrideWith(
          isReleaseBuild
              ? BuilderOptions(builderConfig.releaseOptions)
              : BuilderOptions(builderConfig.devOptions),
        )
        .overrideWith((targetConfig?.options).toBuilderOptions())
        .overrideWith(
          isReleaseBuild
              ? targetConfig?.releaseOptions.toBuilderOptions()
              : targetConfig?.devOptions.toBuilderOptions(),
        )
        .overrideWith(globalOptionOverrides);
    if (isRoot) {
      result = result.overrideWith(BuilderOptions.forRoot);
    }
    return result;
  }

  /// Whether [builderDefinition] applies to [node].
  bool _shouldApply(BuilderDefinition builderDefinition, TargetNode node) {
    if (!node.package.isRoot) {
      // If the package is not root, only hidden output is allowed. Return
      // `false` if the builder or any builder it applies has non-hidden output.
      if (!(builderDefinition.hideOutput &&
          builderDefinition.appliesBuilders.every(
            (b) => _builderDefinitionByKey[b]?.hideOutput ?? true,
          ))) {
        return false;
      }
    }
    // If the builder is explicitly enabled or disabled, return that.
    final builderConfig = node.target.builders[builderDefinition.key];
    if (builderConfig?.isEnabled != null) {
      return builderConfig!.isEnabled;
    }
    // Return true if autoApply for this builder or any applier of it matches
    // the package.
    final shouldAutoApply =
        node.target.autoApplyBuilders &&
        builderDefinition.autoAppliesTo(node.package);
    return shouldAutoApply ||
        (_builderAppliersByKey[builderDefinition.key] ?? const []).any(
          (anchorBuilder) => _shouldApply(anchorBuilder, node),
        );
  }
}

extension BuilderOptionsExtension on Map<String, dynamic>? {
  BuilderOptions toBuilderOptions() =>
      this?.isEmpty ?? true ? BuilderOptions.empty : BuilderOptions(this!);
}

/// Warns about configuration related to unknown builders.
void warnForUnknownBuilders(
  Iterable<BuilderDefinition> builders,
  build_config.BuildConfig rootPackageConfig,
  BuiltMap<String, BuiltMap<String, dynamic>> builderConfigOverrides,
) {
  final builderKeys = builders.map((b) => b.key).toSet();
  for (final key in builderConfigOverrides.keys) {
    if (!builderKeys.contains(key)) {
      buildLog.warning(
        'Ignoring options overrides for '
        'unknown builder `$key`.',
      );
    }
  }
  for (final target in rootPackageConfig.buildTargets.values) {
    for (final key in target.builders.keys) {
      if (!builderKeys.contains(key)) {
        buildLog.warning(
          'Ignoring options for unknown builder `$key` '
          'in target `${target.key}`.',
        );
      }
    }
  }
  for (final key in rootPackageConfig.globalOptions.keys) {
    if (!builderKeys.contains(key)) {
      buildLog.warning('Ignoring `global_options` for unknown builder `$key`.');
    }
  }
  for (final value in rootPackageConfig.globalOptions.values) {
    for (final key in value.runsBefore) {
      if (!builderKeys.contains(key)) {
        buildLog.warning(
          'Ignoring `runs_before` in `global_options` '
          'referencing unknown builder `$key`.',
        );
      }
    }
  }
}

void _validateBuilder(Builder builder) {
  final inputExtensions = builder.buildExtensions.keys.toSet();
  final matching = inputExtensions.intersection(
    // https://github.com/dart-lang/linter/issues/4336
    // ignore: collection_methods_unrelated_type
    {for (final outputs in builder.buildExtensions.values) ...outputs},
  );
  if (matching.isNotEmpty) {
    final mapDescription = builder.buildExtensions.entries
        .map((e) => '${e.key}: ${e.value},')
        .join('\n');
    throw ArgumentError.value(
      '{ $mapDescription }',
      '${builder.runtimeType}.buildExtensions',
      'Output extensions must not match any input extensions, but got '
          'the following overlapping output extensions: $matching',
    );
  }
}

void _validatePostProcessBuilder(PostProcessBuilder builder) {
  // Regular builders may use `{{}}` to define a capture group in build
  // extensions. We don't currently support this syntax for post process
  // builders.
  if (builder.inputExtensions.any((input) => input.contains('{{}}'))) {
    throw ArgumentError(
      '${builder.runtimeType}.buildInputs contains capture groups (`{{}}`), '
      'which is not currently supported for post-process builders. \n'
      'Try generalizing input extensions and manually skip uninteresting '
      'assets in the `build()` method.',
    );
  }
}
