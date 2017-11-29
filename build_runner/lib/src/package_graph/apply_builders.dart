// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../generate/phase.dart';
import 'dependency_ordering.dart';
import 'package_graph.dart';

typedef bool PackageFilter(PackageNode node);

/// Run a builder on all packages in the package graph.
PackageFilter toAllPackages() => (_) => true;

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

/// Apply [builder] to the root package.
BuilderApplication applyToRoot(Builder builder,
        {List<String> inputs, List<String> excludes}) =>
    new BuilderApplication._('', '', [(_) => builder], (_) => false,
        inputs: inputs, excludes: excludes, applyToRoot: true);

/// Apply each builder from [builderFactories] to the packages matching
/// [filter].
///
/// If the builder should only run on a subset of files within a package pass
/// globs to [inputs] or [excludes].
///
/// If [isOptional] is true the builder will only run if one of its outputs is
/// read by a later builder, or is used as a primary input to a later builder.
/// If no build actions read the output of an optional action, then it will
/// never run.
BuilderApplication apply(String providingPackage, String builderName,
        List<BuilderFactory> builderFactories, PackageFilter filter,
        {List<String> inputs, List<String> excludes, bool isOptional}) =>
    new BuilderApplication._(
        providingPackage, builderName, builderFactories, filter,
        inputs: inputs, excludes: excludes, isOptional: isOptional);

/// A description of which packages need a given [Builder] applied.
class BuilderApplication {
  final List<BuilderFactory> builderFactories;

  /// Determines whether a given package needs builder applied.
  final PackageFilter filter;

  /// The package which provides this builder.
  ///
  /// Along with the [builderName] makes up a key that uniquely identifies the
  /// builder.
  final String providingPackage;

  /// A name for this builder.
  ///
  /// Along with the [providingPackage] makes up a key that uniquely identifies the
  /// builder.
  final String builderName;

  final List<String> inputs;
  final List<String> excludes;
  final bool isOptional;

  /// Whether to skip [filter] and only apply this package to the root of the
  /// package graph.
  // TODO: this is a hack until we can add `isRoot` to `PackageNode`.
  final bool _applyToRoot;

  const BuilderApplication._(this.providingPackage, this.builderName,
      this.builderFactories, this.filter,
      {this.inputs, this.excludes, this.isOptional, bool applyToRoot: false})
      : _applyToRoot = applyToRoot;
}

/// Creates a [BuildAction] to apply each builder in [builderApplications] to
/// each package in [packageGraph] such that all builders are run for
/// dependencies before moving on to later packages.
///
/// When there is a package cycle the builders are applied to each packages
/// within the cycle before moving on to packages that depend on any package
/// within the cycle.
///
/// Builders may be filtered, for instance to run only on package which have a
/// dependency on some other package by choosing the appropriate
/// [BuilderApplication].
List<BuildAction> createBuildActions(PackageGraph packageGraph,
    Iterable<BuilderApplication> builderApplications) {
  var cycles = stronglyConnectedComponents<String, PackageNode>(
      [packageGraph.root], (node) => node.name, (node) => node.dependencies);
  return cycles
      .expand((cycle) => _createBuildActionsWithinCycle(
          cycle, packageGraph, builderApplications))
      .toList();
}

Iterable<BuildAction> _createBuildActionsWithinCycle(
        Iterable<PackageNode> cycle,
        PackageGraph packageGraph,
        Iterable<BuilderApplication> builderApplications) =>
    builderApplications.expand((builderApplication) =>
        _createBuildActionsForBuilderInCycle(
            cycle, packageGraph, builderApplication));

Iterable<BuildAction> _createBuildActionsForBuilderInCycle(
    Iterable<PackageNode> cycle,
    PackageGraph packageGraph,
    BuilderApplication builderApplication) {
  bool filter(PackageNode packageNode) =>
      //TODO: this is a hack until we can add `isRoot` to `PackageNode`
      (builderApplication._applyToRoot && packageNode == packageGraph.root) ||
      builderApplication.filter(packageNode);
  return builderApplication.builderFactories.expand((b) => cycle
      .where(filter)
      .map((p) => new BuildAction(b(const BuilderOptions(const {})), p.name,
          inputs: builderApplication.inputs,
          excludes: builderApplication.excludes,
          isOptional: builderApplication.isOptional)));
}
