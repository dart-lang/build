// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:graphs/graphs.dart';

import '../builder/post_process_builder.dart';
import '../generate/phase.dart';
import 'package_graph.dart';
import 'target_graph.dart';

typedef BuildAction BuildActionFactory(String package, BuilderOptions options,
    InputSet targetSources, InputSet generateFor);

typedef PostProcessBuilder PostProcessBuilderFactory(BuilderOptions options);

typedef bool PackageFilter(PackageNode node);

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

PackageFilter toRoot() => (p) => p.isRoot;

/// Apply [builder] to the root package.
///
/// Creates a `BuilderApplication` which corresponds to an empty builder key so
/// that no other `build.yaml` based configuration will apply.
BuilderApplication applyToRoot(Builder builder,
        {bool isOptional: false,
        bool hideOutput: false,
        InputSet generateFor}) =>
    new BuilderApplication.forBuilder('', [(_) => builder], toRoot(),
        isOptional: isOptional,
        hideOutput: hideOutput,
        defaultGenerateFor: generateFor);

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
BuilderApplication apply(String builderKey,
        List<BuilderFactory> builderFactories, PackageFilter filter,
        {bool isOptional,
        bool hideOutput,
        InputSet defaultGenerateFor,
        Iterable<String> appliesBuilders}) =>
    new BuilderApplication.forBuilder(
      builderKey,
      builderFactories,
      filter,
      isOptional: isOptional,
      hideOutput: hideOutput,
      defaultGenerateFor: defaultGenerateFor,
      appliesBuilders: appliesBuilders,
    );

/// Same as [apply] except it takes [PostProcessBuilderFactory]s.
///
/// Does not provide options for `isOptional` or `hideOutput` because they
/// aren't configurable for these types of builders. They are never optional and
/// always hidden.
BuilderApplication applyPostProcess(
        String builderKey, PostProcessBuilderFactory builderFactory,
        {InputSet defaultGenerateFor}) =>
    new BuilderApplication.forPostProcessBuilder(
      builderKey,
      builderFactory,
      defaultGenerateFor: defaultGenerateFor,
    );

/// A description of which packages need a given [Builder] or
/// [PostProcessBuilder] applied.
class BuilderApplication {
  /// Factories that create [BuildAction]s for all [Builder]s or
  /// [PostProcessBuilder]s that should be applied.
  final List<BuildActionFactory> buildActionFactories;

  /// Determines whether a given package needs builder applied.
  final PackageFilter filter;

  /// Builder keys which, when applied to a target, will also apply this Builder
  /// even if [filter] does not match.
  final Iterable<String> appliesBuilders;

  /// A uniqe key for this builder.
  final String builderKey;

  /// Whether genereated assets should be placed in the build cache.
  final bool hideOutput;

  const BuilderApplication._(
    this.builderKey,
    this.buildActionFactories,
    this.filter,
    this.hideOutput,
    Iterable<String> appliesBuilders,
  ) : appliesBuilders = appliesBuilders ?? const [];

  factory BuilderApplication.forBuilder(
    String builderKey,
    List<BuilderFactory> builderFactories,
    PackageFilter filter, {
    bool isOptional,
    bool hideOutput,
    InputSet defaultGenerateFor,
    Iterable<String> appliesBuilders,
  }) {
    hideOutput ??= true;
    var actionFactories = builderFactories.map((builderFactory) {
      return (String package, BuilderOptions options, InputSet targetSources,
          InputSet generateFor) {
        generateFor ??= defaultGenerateFor;
        var builder = builderFactory(options);
        return new BuilderBuildAction(builder, package,
            targetSources: targetSources,
            generateFor: generateFor,
            builderOptions: options,
            hideOutput: hideOutput,
            isOptional: isOptional);
      };
    }).toList();
    return new BuilderApplication._(
        builderKey, actionFactories, filter, hideOutput, appliesBuilders);
  }

  /// Note that these builder applications each create their own phase, but they
  /// will all eventually be merged into a single phase.
  factory BuilderApplication.forPostProcessBuilder(
    String builderKey,
    PostProcessBuilderFactory builderFactory, {
    InputSet defaultGenerateFor,
  }) {
    var actionFactory = (String package, BuilderOptions options,
        InputSet targetSources, InputSet generateFor) {
      generateFor ??= defaultGenerateFor;
      var builder = builderFactory(options);
      var builderAction = new PostProcessBuilderAction(builder, package,
          builderOptions: options,
          generateFor: generateFor,
          targetSources: targetSources);
      return new PostProcessBuildAction([builderAction]);
    };
    return new BuilderApplication._(
        builderKey, [actionFactory], toNoneByDefault(), true, []);
  }
}

/// Creates a [BuildAction] to apply each builder in [builderApplications] to
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
Future<List<BuildAction>> createBuildActions(
    TargetGraph targetGraph,
    Iterable<BuilderApplication> builderApplications,
    Map<String, Map<String, dynamic>> builderConfigOverrides) async {
  final cycles = stronglyConnectedComponents<String, TargetNode>(
      targetGraph.allModules.values,
      (node) => node.target.key,
      (node) =>
          node.target.dependencies?.map((key) => targetGraph.allModules[key]));
  final applyWith = _applyWith(builderApplications);
  var expandedActions = cycles.expand((cycle) => _createBuildActionsWithinCycle(
      cycle, builderApplications, builderConfigOverrides, applyWith));

  var combinedActions = <BuildAction>[]
    ..addAll(expandedActions.where((action) => action is BuilderBuildAction));
  var postBuilderActions = expandedActions
      .where((action) => action is PostProcessBuildAction)
      .cast<PostProcessBuildAction>()
      .toList();
  if (postBuilderActions.isNotEmpty) {
    combinedActions.add(postBuilderActions.fold<PostProcessBuildAction>(
        new PostProcessBuildAction([]), (previous, next) {
      previous.builderActions.addAll(next.builderActions);
      return previous;
    }));
  }

  return combinedActions;
}

Iterable<BuildAction> _createBuildActionsWithinCycle(
  Iterable<TargetNode> cycle,
  Iterable<BuilderApplication> builderApplications,
  Map<String, Map<String, dynamic>> builderConfigOverrides,
  Map<String, List<BuilderApplication>> applyWith,
) =>
    builderApplications.expand((builderApplication) =>
        _createBuildActionsForBuilderInCycle(
            cycle,
            builderApplication,
            builderConfigOverrides[builderApplication.builderKey] ?? const {},
            applyWith));

Iterable<BuildAction> _createBuildActionsForBuilderInCycle(
  Iterable<TargetNode> cycle,
  BuilderApplication builderApplication,
  Map<String, dynamic> builderConfigOverrides,
  Map<String, List<BuilderApplication>> applyWith,
) {
  TargetBuilderConfig targetConfig(TargetNode node) =>
      node.target.builders[builderApplication.builderKey];
  return builderApplication.buildActionFactories.expand((createAction) => cycle
          .where((targetNode) =>
              _shouldApply(builderApplication, targetNode, applyWith))
          .map((node) {
        final builderConfig = targetConfig(node);
        var options = builderConfig?.options ?? const BuilderOptions(const {});
        options = new BuilderOptions(
            new Map<String, dynamic>.from(options.config)
              ..addAll(builderConfigOverrides));
        return createAction(node.package.name, options, node.target.sources,
            builderConfig?.generateFor);
      }));
}

bool _shouldApply(BuilderApplication builderApplication, TargetNode node,
    Map<String, List<BuilderApplication>> applyWith) {
  if (!builderApplication.hideOutput && !node.package.isRoot) {
    return false;
  }
  final builderConfig = node.target.builders[builderApplication.builderKey];
  if (builderConfig?.isEnabled != null) {
    return builderConfig.isEnabled;
  }
  return builderApplication.filter(node.package) ||
      (applyWith[builderApplication.builderKey] ?? const [])
          .any((anchorBuilder) => _shouldApply(anchorBuilder, node, applyWith));
}

/// Inverts the dependency map from 'applies builders' to 'applied with
/// builders'.
Map<String, List<BuilderApplication>> _applyWith(
    Iterable<BuilderApplication> builderApplications) {
  final applyWith = <String, List<BuilderApplication>>{};
  for (final builderApplication in builderApplications) {
    for (final alsoApply in builderApplication.appliesBuilders) {
      applyWith.putIfAbsent(alsoApply, () => []).add(builderApplication);
    }
  }
  return applyWith;
}
