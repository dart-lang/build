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

/// Indcates that [builder] should be run against all packages matching
/// [filter].
///
/// If the builder should only run on a subset of files within a package pass
/// globs to [inputs] or [excludes];
BuilderApplication apply(Builder builder, PackageFilter filter,
        {List<String> inputs, List<String> excludes, bool isOptional}) =>
    new BuilderApplication(builder, filter,
        inputs: inputs, excludes: excludes, isOptional: isOptional);

/// A description of which packages need a given [Builder] applied.
class BuilderApplication {
  final Builder builder;

  /// Determines whether a given package needs [builder] applied.
  final PackageFilter filter;

  final List<String> inputs;
  final List<String> excludes;
  final bool isOptional;

  const BuilderApplication(this.builder, this.filter,
      {this.inputs, this.excludes, this.isOptional});
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
        Iterable<BuilderApplication> builderApplications) =>
    stronglyConnectedComponents<String, PackageNode>(
            [packageGraph.root], (node) => node.name, (node) => node.dependencies)
        .expand((cycle) => builderApplications.expand((b) => cycle
            .where(b.filter)
            .map((p) => new BuildAction(b.builder, p.name,
                inputs: b.inputs,
                excludes: b.excludes,
                isOptional: b.isOptional))))
        .toList();
