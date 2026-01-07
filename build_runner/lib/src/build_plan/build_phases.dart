// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:built_collection/built_collection.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:graphs/graphs.dart';

import '../exceptions.dart';
import '../logging/build_log.dart';
import 'builder_application.dart';
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
        'generate files for another package unless the BuilderApplication'
        'specified "hideOutput".'
        '\n\n'
        'Did you mean to write:\n'
        '  new BuilderApplication(..., toRoot())\n'
        'or\n'
        '  new BuilderApplication(..., hideOutput: true)\n'
        '... instead?',
      );
      throw const CannotBuildException();
    }
  }
}

/// Creates a [BuildPhase] to apply each builder in [builderApplications] to
/// each target in [targetGraph] such that all builders are run for dependencies
/// before moving on to later packages.
///
/// When there is a package cycle the builders are applied to each packages
/// within the cycle before moving on to packages that depend on any package
/// within the cycle.
///
/// Builders may be filtered, for instance to run only on package which have a
/// dependency on some other package by choosing the appropriate
/// [BuilderApplication].
Future<BuildPhases> createBuildPhases(
  TargetGraph targetGraph,
  Iterable<BuilderApplication> builderApplications,
  BuiltMap<String, BuiltMap<String, dynamic>> builderConfigOverrides,
  bool isReleaseMode,
) async {
  warnForUnknownBuilders(
    builderApplications,
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
  final applyWith = _applyWith(builderApplications);
  final allBuilders = Map<String, BuilderApplication>.fromIterable(
    builderApplications,
    key: (b) => (b as BuilderApplication).builderKey,
  );
  final expandedPhases =
      cycles
          .expand(
            (cycle) => _createBuildPhasesWithinCycle(
              cycle,
              builderApplications,
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
  Iterable<TargetNode> cycle,
  Iterable<BuilderApplication> builderApplications,
  Map<String, BuilderOptions> globalOptions,
  Map<String, List<BuilderApplication>> applyWith,
  Map<String, BuilderApplication> allBuilders,
  bool isReleaseMode,
) => builderApplications.expand(
  (builderApplication) => _createBuildPhasesForBuilderInCycle(
    cycle,
    builderApplication,
    globalOptions[builderApplication.builderKey] ?? BuilderOptions.empty,
    applyWith,
    allBuilders,
    isReleaseMode,
  ),
);

Iterable<BuildPhase> _createBuildPhasesForBuilderInCycle(
  Iterable<TargetNode> cycle,
  BuilderApplication builderApplication,
  BuilderOptions globalOptionOverrides,
  Map<String, List<BuilderApplication>> applyWith,
  Map<String, BuilderApplication> allBuilders,
  bool isReleaseMode,
) {
  TargetBuilderConfig? targetConfig(TargetNode node) =>
      node.target.builders[builderApplication.builderKey];
  return builderApplication.buildPhaseFactories.expand(
    (createPhase) => cycle
        .where(
          (targetNode) => _shouldApply(
            builderApplication,
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
          return createPhase(
            node.package,
            options,
            node.target.sources,
            builderConfig?.generateFor,
            isReleaseMode,
          );
        }),
  );
}

bool _shouldApply(
  BuilderApplication builderApplication,
  TargetNode node,
  Map<String, List<BuilderApplication>> applyWith,
  Map<String, BuilderApplication> allBuilders,
) {
  if (!(builderApplication.hideOutput &&
          builderApplication.appliesBuilders.every(
            (b) => allBuilders[b]?.hideOutput ?? true,
          )) &&
      !node.package.isRoot) {
    return false;
  }
  final builderConfig = node.target.builders[builderApplication.builderKey];
  if (builderConfig?.isEnabled != null) {
    return builderConfig!.isEnabled;
  }
  final shouldAutoApply =
      node.target.autoApplyBuilders &&
      builderApplication.autoAppliesTo(node.package);
  return shouldAutoApply ||
      (applyWith[builderApplication.builderKey] ?? const []).any(
        (anchorBuilder) =>
            _shouldApply(anchorBuilder, node, applyWith, allBuilders),
      );
}

/// Inverts the dependency map from 'applies builders' to 'applied with
/// builders'.
Map<String, List<BuilderApplication>> _applyWith(
  Iterable<BuilderApplication> builderApplications,
) {
  final applyWith = <String, List<BuilderApplication>>{};
  for (final builderApplication in builderApplications) {
    for (final alsoApply in builderApplication.appliesBuilders) {
      applyWith.putIfAbsent(alsoApply, () => []).add(builderApplication);
    }
  }
  return applyWith;
}

BuilderOptions _options(Map<String, dynamic>? options) =>
    options?.isEmpty ?? true ? BuilderOptions.empty : BuilderOptions(options!);

/// Warns about configuration related to unknown builders.
void warnForUnknownBuilders(
  Iterable<BuilderApplication> builders,
  BuildConfig rootPackageConfig,
  BuiltMap<String, BuiltMap<String, dynamic>> builderConfigOverrides,
) {
  final builderKeys = builders.map((b) => b.builderKey).toSet();
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
