// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../generate/phase.dart';
import 'package_graph.dart';

bool _alwaysTrue(_) => true;

bool Function(PackageNode) _dependencyFilter(String dependency) =>
    (p) => p.dependencies.any((d) => d.name == dependency);

bool Function(PackageNode) _isPackage(String package) =>
    (p) => p.name == package;

bool Function(PackageNode) _packagesContains(Set<String> packages) =>
    (p) => packages.contains(p.name);

class BuilderApplication {
  final Builder builder;

  /// Determines which package need [builder] applied.
  final bool Function(PackageNode) filter;

  /// Apply [builder] to all packages in the dependency graph.
  const BuilderApplication.allPackage(this.builder) : filter = _alwaysTrue;

  /// Apply [builder] to the pacakges which have a direct dependency on the
  /// package named [dependency].
  BuilderApplication.dependentsOf(this.builder, String dependency)
      : filter = _dependencyFilter(dependency);

  /// Apply [builder] to a single package in the graph.
  BuilderApplication.singlePackage(this.builder, String package)
      : filter = _isPackage(package);

  /// Apply [builder] to a set of explicitly listed packages.
  BuilderApplication.onPackages(this.builder, Set<String> packages)
      : filter = _packagesContains(packages);
}

/// Creates a [BuildAction] to apply each builder in [builders] to each package
/// in [packages] such that all builders are run for earlier subcomponents
/// before moving on to later packages.
///
/// For example, given the builders `[b1, b2]` and package components
/// `[[p1], [p2, p3], [p4]]` where `p2` and `p3` represent a dependenency cycle
/// which depends on `p1` this will return actions
/// `[b1p1, b2p1, b1p2, b1p3, b2p2, b2p3, b1p4, b2p4]`.
///
/// Builders may be filtered, for instance to run only on package which have a
/// dependency on some other package.
List<BuildAction> applyBuilders(Iterable<Iterable<PackageNode>> packages,
        Iterable<BuilderApplication> builders) =>
    packages
        .expand((cycle) => builders.expand((b) => cycle
            .where(b.filter)
            .map((p) => new BuildAction(b.builder, p.name))))
        .toList();
