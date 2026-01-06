// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';

import '../exceptions.dart';
import '../logging/build_log.dart';
import '../logging/build_log_logger.dart';
import 'builder_application.dart';
import 'package_graph.dart';
import 'phase.dart';

/// Run a builder on all packages in the package graph.
PackageFilter toAllPackages() => (_) => true;

/// Require manual configuration to opt in to a builder.
PackageFilter toNoneByDefault() => (_) => false;

/// Run a builder on all packages with an immediate dependency on [packageName].
PackageFilter toDependentsOf(String packageName) =>
    (p) => p.dependencies.any((d) => d.name == packageName);

/// Run a builder on a single package.
PackageFilter toPackage(String package) => (p) => p.name == package;

/// Run a builder on a collection of packages.
PackageFilter toPackages(Set<String> packages) =>
    (p) => packages.contains(p.name);

/// Run a builders if the package matches any of [filters]
PackageFilter toAll(Iterable<PackageFilter> filters) =>
    (p) => filters.any((f) => f(p));

PackageFilter toRoot() => (p) => p.build;

/// Apply [builder] to the root package.
///
/// Creates a `BuilderApplication` which corresponds to an empty builder key so
/// that no other `build.yaml` based configuration will apply.
BuilderApplication applyToRoot(
  Builder builder, {
  bool isOptional = false,
  bool hideOutput = false,
  InputSet generateFor = const InputSet(),
}) => _forBuilder(
  '',
  [(_) => builder],
  toRoot(),
  isOptional: isOptional,
  hideOutput: hideOutput,
  defaultGenerateFor: generateFor,
);

/// Apply each builder from [builderFactories] to the packages matching
/// [filter].
///
/// If the builder should only run on a subset of files within a target pass
/// globs to [defaultGenerateFor]. This can be overridden by any target which
/// configured the builder manually.
///
/// If [isOptional] is true the builder will only run if one of its outputs is
/// read by a later builder, or is used as a primary input to a later builder.
/// If no build actions read the output of an optional action, then it will
/// never run.
///
/// Any existing Builders which match a key in [appliesBuilders] will
/// automatically be applied to any target which runs this Builder, whether
/// because it matches [filter] or because it was enabled manually.
BuilderApplication apply(
  String builderKey,
  Iterable<BuilderFactory> builderFactories,
  PackageFilter filter, {
  bool isOptional = false,
  bool hideOutput = true,
  InputSet defaultGenerateFor = const InputSet(),
  BuilderOptions defaultOptions = BuilderOptions.empty,
  BuilderOptions? defaultDevOptions,
  BuilderOptions? defaultReleaseOptions,
  Iterable<String> appliesBuilders = const [],
}) => _forBuilder(
  builderKey,
  builderFactories,
  filter,
  isOptional: isOptional,
  hideOutput: hideOutput,
  defaultGenerateFor: defaultGenerateFor,
  defaultOptions: defaultOptions,
  defaultDevOptions: defaultDevOptions,
  defaultReleaseOptions: defaultReleaseOptions,
  appliesBuilders: appliesBuilders,
);

/// Same as [apply] except it takes [PostProcessBuilderFactory]s.
///
/// Does not provide options for `isOptional` or `hideOutput` because they
/// aren't configurable for these types of builders. They are never optional and
/// always hidden.
BuilderApplication applyPostProcess(
  String builderKey,
  PostProcessBuilderFactory builderFactory, {
  InputSet defaultGenerateFor = const InputSet(),
  BuilderOptions defaultOptions = BuilderOptions.empty,
  BuilderOptions? defaultDevOptions,
  BuilderOptions? defaultReleaseOptions,
}) => _forPostProcessBuilder(
  builderKey,
  builderFactory,
  defaultGenerateFor: defaultGenerateFor,
  defaultOptions: defaultOptions,
  defaultDevOptions: defaultDevOptions,
  defaultReleaseOptions: defaultReleaseOptions,
);

BuilderApplication _forBuilder(
  String key,
  Iterable<BuilderFactory> builderFactories,
  PackageFilter filter, {
  bool isOptional = false,
  bool hideOutput = true,
  InputSet defaultGenerateFor = const InputSet(),
  BuilderOptions defaultOptions = BuilderOptions.empty,
  BuilderOptions? defaultDevOptions,
  BuilderOptions? defaultReleaseOptions,
  Iterable<String> appliesBuilders = const [],
}) {
  final phaseFactories =
      builderFactories.map((builderFactory) {
        return (
          PackageNode package,
          BuilderOptions options,
          InputSet targetSources,
          InputSet? generateFor,
          bool isReleaseBuild,
        ) {
          generateFor ??= defaultGenerateFor;

          var optionsWithDefaults = defaultOptions
              .overrideWith(
                isReleaseBuild ? defaultReleaseOptions : defaultDevOptions,
              )
              .overrideWith(options);
          if (package.build) {
            optionsWithDefaults = optionsWithDefaults.overrideWith(
              BuilderOptions.forRoot,
            );
          }

          final builder = BuildLogLogger.scopeLogSync(
            () => builderFactory(optionsWithDefaults),
            buildLog.loggerForOther(key),
          );
          if (builder == null) throw const CannotBuildException();
          _validateBuilder(builder);
          return InBuildPhase(
            builder: builder,
            key: key,
            package: package.name,
            targetSources: targetSources,
            generateFor: generateFor,
            options: optionsWithDefaults,
            hideOutput: hideOutput,
            isOptional: isOptional,
          );
        };
      }).toList();
  return BuilderApplication(
    key,
    phaseFactories,
    filter,
    hideOutput,
    appliesBuilders,
  );
}

/// Note that these builder applications each create their own phase, but they
/// will all eventually be merged into a single phase.
BuilderApplication _forPostProcessBuilder(
  String builderKey,
  PostProcessBuilderFactory builderFactory, {
  InputSet defaultGenerateFor = const InputSet(),
  BuilderOptions defaultOptions = BuilderOptions.empty,
  BuilderOptions? defaultDevOptions,
  BuilderOptions? defaultReleaseOptions,
}) {
  PostBuildPhase phaseFactory(
    PackageNode package,
    BuilderOptions options,
    InputSet targetSources,
    InputSet? generateFor,
    bool isReleaseBuild,
  ) {
    generateFor ??= defaultGenerateFor;

    var optionsWithDefaults = defaultOptions
        .overrideWith(
          isReleaseBuild ? defaultReleaseOptions : defaultDevOptions,
        )
        .overrideWith(options);
    if (package.build) {
      optionsWithDefaults = optionsWithDefaults.overrideWith(
        BuilderOptions.forRoot,
      );
    }

    final builder = BuildLogLogger.scopeLogSync(
      () => builderFactory(optionsWithDefaults),
      buildLog.loggerForOther(builderKey),
    );
    if (builder == null) throw const CannotBuildException();
    _validatePostProcessBuilder(builder);
    final builderAction = PostBuildAction(
      builder: builder,
      package: package.name,
      options: optionsWithDefaults,
      generateFor: generateFor,
      targetSources: targetSources,
    );
    return PostBuildPhase([builderAction]);
  }

  return BuilderApplication(
    builderKey,
    [phaseFactory],
    toNoneByDefault(),
    true,
    [],
  );
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
