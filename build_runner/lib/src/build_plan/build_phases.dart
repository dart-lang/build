// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart' as build_config;
import 'package:built_collection/built_collection.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:graphs/graphs.dart';

import '../exceptions.dart';
import '../logging/build_log.dart';
import '../logging/build_log_logger.dart';
import 'builder_application.dart';
import 'builder_factories.dart';
import 'phase.dart';
import 'target_graph.dart';

/// The [BuildPhases] defining the sequence of actions in a build, and their
/// [Digest] and options digests.
class BuildPhases {
  /// The sequence of actions in the main build.
  final BuiltList<InBuildPhase> inBuildPhases;

  /// For each [inBuildPhases], its `builderOptions` digest.
  final BuiltList<Digest> inBuildPhasesOptionsDigests;

  /// The post build phase of the build.
  final PostBuildPhase postBuildPhase;

  /// For each [PostBuildAction] in [postBuildPhase], its `builderOptions`
  /// digest.
  final BuiltList<Digest> postBuildActionsOptionsDigests;

  /// A [Digest] that can be used to detect any change to the phases.
  final Digest digest;

  BuildPhases(
    Iterable<InBuildPhase> inBuildPhases, [
    PostBuildPhase? postBuildPhase,
  ]) : inBuildPhases = inBuildPhases.toBuiltList(),
       inBuildPhasesOptionsDigests = _digestsOf(inBuildPhases),
       postBuildPhase = postBuildPhase ?? PostBuildPhase(const []),
       postBuildActionsOptionsDigests = _digestsOf(
         postBuildPhase?.builderActions ?? [],
       ),
       digest = _computeDigest([
         ...inBuildPhases,
         if (postBuildPhase != null) postBuildPhase,
       ]);

  /// The phases, [inBuildPhases] followed by [postBuildPhase], by number.
  BuildPhase operator [](int index) {
    if (index < inBuildPhases.length) {
      return inBuildPhases[index];
    } else if (index == inBuildPhases.length &&
        postBuildPhase.builderActions.isNotEmpty) {
      return postBuildPhase;
    } else {
      throw RangeError.index(index, this);
    }
  }

  /// The number of [inBuildPhases] plus one for [postBuildPhase] if it's
  /// non-empty.
  int get length =>
      inBuildPhases.length + (postBuildPhase.builderActions.isEmpty ? 0 : 1);

  static Digest _computeDigest(Iterable<BuildPhase> phases) {
    final digestSink = AccumulatorSink<Digest>();
    md5.startChunkedConversion(digestSink)
      ..add(phases.map((phase) => phase.identity).toList())
      ..close();
    assert(digestSink.events.length == 1);
    return digestSink.events.first;
  }

  static BuiltList<Digest> _digestsOf(Iterable<BuildAction> actions) {
    final result = ListBuilder<Digest>();
    for (final action in actions) {
      result.add(_digestOf(action.options));
    }
    return result.build();
  }

  static Digest _digestOf(BuilderOptions builderOptions) =>
      md5.convert(utf8.encode(json.encode(builderOptions.config)));

  /// Checks that outputs are to allowed locations.
  ///
  /// To be valid, all outputs must be under the package [root], or hidden,
  /// meaning they will generate to the hidden generated output directory.
  ///
  /// If the phases are not valid, logs then throws
  /// [CannotBuildException].
  ///
  ///  [PostBuildPhase]s are always hidden, so they are always valid.
  void checkOutputLocations(String root) {
    for (final action in inBuildPhases) {
      if (action.hideOutput) continue;
      if (action.package == root) continue;
      // This should happen only with a manual build script since the build
      // script generation filters these out.
      buildLog.error(
        'A build phase (${action.displayName}) is attempting '
        'to operate on package "${action.package}", but the build script '
        'is located in package "$root". It\'s not valid to attempt to '
        'generate files for another package unless the BuilderDefinition'
        'specified "hideOutput".',
      );
      throw const CannotBuildException();
    }
  }
}

/// Creates a [BuildPhase] to apply each builder in [builderDefinitions] to
/// each target in [targetGraph] such that all builders are run for dependencies
/// before moving on to later packages.
///
/// When there is a package cycle the builders are applied to each packages
/// within the cycle before moving on to packages that depend on any package
/// within the cycle.
///
/// Builders may be filtered, for instance to run only on package which have a
/// dependency on some other package by choosing the appropriate
/// [BuilderDefinition].
Future<BuildPhases> createBuildPhases(
  BuilderFactories builderFactories,
  TargetGraph targetGraph,
  Iterable<BuilderDefinition> builderDefinitions,
  BuiltMap<String, BuiltMap<String, dynamic>> builderConfigOverrides,
  bool isReleaseMode,
) async {
  warnForUnknownBuilders(
    builderDefinitions,
    targetGraph.rootPackageConfig,
    builderConfigOverrides,
  );
  final globalOptions = targetGraph.rootPackageConfig.globalOptions.map(
    (key, config) => MapEntry(
      key,
      _options(config.options).overrideWith(
        isReleaseMode
            ? _options(config.releaseOptions)
            : _options(config.devOptions),
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
  final applyWith = _applyWith(builderDefinitions);
  final allBuilders = Map<String, BuilderDefinition>.fromIterable(
    builderDefinitions,
    key: (b) => (b as BuilderDefinition).key,
  );
  final expandedPhases =
      cycles
          .expand(
            (cycle) => _createBuildPhasesWithinCycle(
              builderFactories,
              cycle,
              builderDefinitions,
              globalOptions,
              applyWith,
              allBuilders,
              isReleaseMode,
            ),
          )
          .toList();

  final inBuildPhases = expandedPhases.whereType<InBuildPhase>();

  final postBuildPhases = expandedPhases.whereType<PostBuildPhase>().toList();
  final collapsedPostBuildPhase = <PostBuildPhase>[];
  if (postBuildPhases.isNotEmpty) {
    collapsedPostBuildPhase.add(
      postBuildPhases.fold<PostBuildPhase>(PostBuildPhase([]), (
        previous,
        next,
      ) {
        previous.builderActions.addAll(next.builderActions);
        return previous;
      }),
    );
  }

  return BuildPhases(inBuildPhases, collapsedPostBuildPhase.singleOrNull);
}

Iterable<BuildPhase> _createBuildPhasesWithinCycle(
  BuilderFactories builderFactories,
  Iterable<TargetNode> cycle,
  Iterable<BuilderDefinition> builderApplications,
  Map<String, BuilderOptions> globalOptions,
  Map<String, List<BuilderDefinition>> applyWith,
  Map<String, BuilderDefinition> allBuilders,
  bool isReleaseMode,
) => builderApplications.expand(
  (builderApplication) => _createBuildPhasesForBuilderInCycle(
    builderFactories,
    cycle,
    builderApplication,
    globalOptions[builderApplication.key] ?? BuilderOptions.empty,
    applyWith,
    allBuilders,
    isReleaseMode,
  ),
);

Iterable<BuildPhase> _createBuildPhasesForBuilderInCycle(
  BuilderFactories builderFactoriesByName,
  Iterable<TargetNode> cycle,
  BuilderDefinition builderDefinition,
  BuilderOptions globalOptionOverrides,
  Map<String, List<BuilderDefinition>> applyWith,
  Map<String, BuilderDefinition> allBuilders,
  bool isReleaseMode,
) {
  build_config.TargetBuilderConfig? targetConfig(TargetNode node) =>
      node.target.builders[builderDefinition.key];
  final builderFactories =
      builderFactoriesByName.builderFactories[builderDefinition.key];
  if (builderFactories != null) {
    return builderFactories.expand(
      (builderFactory) => cycle
          .where(
            (targetNode) => _shouldApply(
              builderDefinition,
              targetNode,
              applyWith,
              allBuilders,
            ),
          )
          .map((node) {
            final builderConfig = targetConfig(node);
            final options = _options(builderConfig?.options)
                .overrideWith(
                  isReleaseMode
                      ? _options(builderConfig?.releaseOptions)
                      : _options(builderConfig?.devOptions),
                )
                .overrideWith(globalOptionOverrides);

            final package = node.package;
            final generateFor = builderConfig?.generateFor;
            var optionsWithDefaults = options;

            // TODO
            /*var optionsWithDefaults = defaultOptions
              .overrideWith(
                isReleaseBuild ? defaultReleaseOptions : defaultDevOptions,
              )
              .overrideWith(options);*/
            if (package.isRoot) {
              optionsWithDefaults = optionsWithDefaults.overrideWith(
                BuilderOptions.forRoot,
              );
            }

            final builder = BuildLogLogger.scopeLogSync(
              () => builderFactory(optionsWithDefaults),
              buildLog.loggerForOther(builderDefinition.key),
            );
            if (builder == null) throw const CannotBuildException();
            _validateBuilder(builder);
            return InBuildPhase(
              builder: builder,
              key: builderDefinition.key,
              package: package.name,
              targetSources: node.target.sources,
              generateFor:
                  generateFor ??
                  builderDefinition.targetBuilderConfigDefaults.generateFor,
              options: optionsWithDefaults,
              hideOutput: builderDefinition.hideOutput,
              isOptional: builderDefinition.isOptional,
            );
          }),
    );
  }
  final postProcessBuilderFactory =
      builderFactoriesByName.postProcessBuilderFactories[builderDefinition.key];
  if (postProcessBuilderFactory != null) {
    return cycle
        .where(
          (targetNode) => _shouldApply(
            builderDefinition,
            targetNode,
            applyWith,
            allBuilders,
          ),
        )
        .map((node) {
          final builderConfig = targetConfig(node);
          final options = _options(builderConfig?.options)
              .overrideWith(
                isReleaseMode
                    ? _options(builderConfig?.releaseOptions)
                    : _options(builderConfig?.devOptions),
              )
              .overrideWith(globalOptionOverrides);

          final package = node.package;
          final generateFor = builderConfig?.generateFor;
          var optionsWithDefaults = options;

          // TODO
          // generateFor ??= defaultGenerateFor;
          /*var optionsWithDefaults = defaultOptions
              .overrideWith(
                isReleaseBuild ? defaultReleaseOptions : defaultDevOptions,
              )
              .overrideWith(options);*/
          if (package.isRoot) {
            optionsWithDefaults = optionsWithDefaults.overrideWith(
              BuilderOptions.forRoot,
            );
          }

          final builder = BuildLogLogger.scopeLogSync(
            () => postProcessBuilderFactory(optionsWithDefaults),
            buildLog.loggerForOther(builderDefinition.key),
          );
          if (builder == null) throw const CannotBuildException();
          _validatePostProcessBuilder(builder);

          final builderAction = PostBuildAction(
            builder: builder,
            package: package.name,
            options: optionsWithDefaults,
            generateFor:
                generateFor ??
                builderDefinition.targetBuilderConfigDefaults.generateFor,
            targetSources: node.target.sources,
          );
          return PostBuildPhase([builderAction]);
        });
  }

  throw 'whoops';
}

bool _shouldApply(
  BuilderDefinition builderDefinition,
  TargetNode node,
  Map<String, List<BuilderDefinition>> applyWith,
  Map<String, BuilderDefinition> allBuilders,
) {
  if (!(builderDefinition.hideOutput &&
          builderDefinition.appliesBuilders.every(
            (b) => allBuilders[b]?.hideOutput ?? true,
          )) &&
      !node.package.isRoot) {
    return false;
  }
  final builderConfig = node.target.builders[builderDefinition.key];
  if (builderConfig?.isEnabled != null) {
    return builderConfig!.isEnabled;
  }
  final shouldAutoApply =
      node.target.autoApplyBuilders &&
      builderDefinition.autoAppliesTo(node.package);
  return shouldAutoApply ||
      (applyWith[builderDefinition.key] ?? const []).any(
        (anchorBuilder) =>
            _shouldApply(anchorBuilder, node, applyWith, allBuilders),
      );
}

/// Inverts the dependency map from 'applies builders' to 'applied with
/// builders'.
Map<String, List<BuilderDefinition>> _applyWith(
  Iterable<BuilderDefinition> builderDefinitions,
) {
  final applyWith = <String, List<BuilderDefinition>>{};
  for (final builderDefinition in builderDefinitions) {
    for (final alsoApply in builderDefinition.appliesBuilders) {
      applyWith.putIfAbsent(alsoApply, () => []).add(builderDefinition);
    }
  }
  return applyWith;
}

BuilderOptions _options(Map<String, dynamic>? options) =>
    options?.isEmpty ?? true ? BuilderOptions.empty : BuilderOptions(options!);

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
