// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:graphs/graphs.dart';

import '../generate/phase.dart';
import 'package_graph.dart';
import 'target_graph.dart';

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
    new BuilderApplication._('', [(_) => builder], toRoot(),
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
BuilderApplication apply(String builderKey,
        List<BuilderFactory> builderFactories, PackageFilter filter,
        {bool isOptional, bool hideOutput, InputSet defaultGenerateFor}) =>
    new BuilderApplication._(builderKey, builderFactories, filter,
        isOptional: isOptional,
        hideOutput: hideOutput,
        defaultGenerateFor: defaultGenerateFor);

/// A description of which packages need a given [Builder] applied.
class BuilderApplication {
  final List<BuilderFactory> builderFactories;

  /// Determines whether a given package needs builder applied.
  final PackageFilter filter;

  /// A uniqe key for this builder.
  final String builderKey;

  final bool isOptional;

  /// Whether genereated assets should be placed in the build cache.
  final bool hideOutput;

  /// The default filter for primary inputs if the [TargetBuilderConfig] does
  /// not specify one.
  final InputSet defaultGenerateFor;

  const BuilderApplication._(
      this.builderKey, this.builderFactories, this.filter,
      {this.isOptional, bool hideOutput, this.defaultGenerateFor})
      : hideOutput = hideOutput ?? true;
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
Future<List<BuildAction>> createBuildActions(TargetGraph targetGraph,
    Iterable<BuilderApplication> builderApplications) async {
  var cycles = stronglyConnectedComponents<String, TargetNode>(
      targetGraph.allModules.values,
      (node) => node.target.key,
      (node) =>
          node.target.dependencies?.map((key) => targetGraph.allModules[key]));
  return cycles
      .expand(
          (cycle) => _createBuildActionsWithinCycle(cycle, builderApplications))
      .toList();
}

Iterable<BuildAction> _createBuildActionsWithinCycle(Iterable<TargetNode> cycle,
        Iterable<BuilderApplication> builderApplications) =>
    builderApplications.expand((builderApplication) =>
        _createBuildActionsForBuilderInCycle(cycle, builderApplication));

Iterable<BuildAction> _createBuildActionsForBuilderInCycle(
    Iterable<TargetNode> cycle, BuilderApplication builderApplication) {
  TargetBuilderConfig targetConfig(TargetNode node) =>
      node.target.builders[builderApplication.builderKey];
  bool shouldRun(TargetNode node) {
    if (!builderApplication.hideOutput && !node.package.isRoot) {
      return false;
    }
    final builderConfig = targetConfig(node);
    if (builderConfig?.isEnabled != null) {
      return builderConfig.isEnabled;
    }
    return builderApplication.filter(node.package);
  }

  return builderApplication.builderFactories
      .expand((b) => cycle.where(shouldRun).map((node) {
            final builderConfig = targetConfig(node);
            final generateFor = builderConfig?.generateFor ??
                builderApplication.defaultGenerateFor;
            final options =
                builderConfig?.options ?? const BuilderOptions(const {});
            return new BuildAction(b(options), node.package.name,
                builderOptions: options,
                targetSources: node.target.sources,
                generateFor: generateFor,
                isOptional: builderApplication.isOptional,
                hideOutput: builderApplication.hideOutput);
          }));
}
