// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:graphs/graphs.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

import '../constants.dart';
import '../io/asset_path_provider.dart';
import 'build_package.dart';
import 'build_packages_loader.dart';

/// The SDK package, we filter this to the core libs and dev compiler
/// resources.
final _sdkPackage = BuildPackage(name: r'$sdk', path: sdkPath);

/// The [BuildPackage]s in the build.
class BuildPackages implements AssetPathProvider {
  /// All packages by package name.
  final BuiltMap<String, BuildPackage> packages;

  /// The names of all packages in the build reverse topologically ordered.
  ///
  /// That means "dependencies first": a package only depends on packages that
  /// are earlier in the list, with the exception of packages in dependency
  /// cycles.
  final BuiltList<String> orderedPackages;

  /// When building a single package: the package `build_runner` was launched
  /// in, which is also the current directory package and the [outputRoot].
  ///
  /// When building a workspace, `null`.
  final String? singleOutputPackage;

  /// The names of packages that generated output will be written to.
  ///
  /// If [singleOutputPackage] is set, contains exactly that one package.
  /// Otherwise, contains all the packages in the workspace.
  final BuiltSet<String> outputPackages;

  /// The package where output that does not belong to a specific package is
  /// written.
  ///
  /// Equal to [singleOutputPackage] if there is one, otherwise this is the
  /// workspace root.
  ///
  /// Output includes the `.dart_tool/build` folder with the build script,
  /// compiled build script, generated output and serialized asset graph.
  ///
  /// Also the root for output of performance logs.
  ///
  /// Also the path where `build_runner` looks for `build.yaml` configuration
  /// that applies to the whole build instead of to the package it's in: global
  /// options and package-specific overrides.
  final String outputRoot;

  /// A [PackageConfig] representation of this package graph.
  final PackageConfig asPackageConfig;

  /// Transitive dependencies by package name.
  final BuiltSetMultimap<String, String> _transitiveDependencies;

  /// Peer packages by package name, see [peersOf].
  final BuiltSetMultimap<String, String> _peerPackages;

  BuildPackages({
    required this.singleOutputPackage,
    required this.outputRoot,
    required this.packages,
    required this.orderedPackages,
    required this.outputPackages,
    required this.asPackageConfig,
    required BuiltSetMultimap<String, String> transitiveDependencies,
    required BuiltSetMultimap<String, String> buildPackages,
  }) : _transitiveDependencies = transitiveDependencies,
       _peerPackages = buildPackages;

  factory BuildPackages.compute({
    String? singlePackageToBuild,
    required String outputRoot,
    required BuiltMap<String, BuildPackage> packages,
  }) {
    for (final package in packages.values) {
      for (final dependency in package.dependencies) {
        if (!packages.containsKey(dependency)) {
          throw StateError(
            'Dependency $dependency of $package not present, please run '
            '`dart pub get` or `flutter pub get` to fetch dependencies.',
          );
        }
      }
    }

    final packagesBuilder = packages.toBuilder();
    // If building in a workspace but not building the whole workspace, filter
    // to packages that are a transitive dependency of `singlePackageToBuild`.
    if (singlePackageToBuild != null) {
      final packageTransitiveDeps = _computeTransitiveDeps(
        singlePackageToBuild,
        packages,
      );
      packagesBuilder.removeWhere(
        (name, _) => !packageTransitiveDeps.contains(name),
      );
    }
    packagesBuilder.putIfAbsent(r'$sdk', () => _sdkPackage);
    packages = packagesBuilder.build();

    final asPackageConfig = _packagesToConfig(packages.values);
    final outputPackages =
        packages.values
            .where((b) => b.isOutput)
            .map((p) => p.name)
            .toBuiltSet();

    final transitiveDependencies = _computeAllTransitiveDeps(packages);
    final buildPackages = _computePeers(outputPackages, transitiveDependencies);

    return BuildPackages(
      singleOutputPackage: singlePackageToBuild,
      outputRoot: outputRoot,
      packages: packages,
      orderedPackages: transitiveDependencies.keys.toBuiltList(),
      outputPackages: outputPackages,
      asPackageConfig: asPackageConfig,
      transitiveDependencies: transitiveDependencies,
      buildPackages: buildPackages,
    );
  }

  /// Creates [BuildPackages] from [BuildPackage]s for a single package build
  /// of [package].
  @visibleForTesting
  factory BuildPackages.singlePackageBuild(
    String package,
    Iterable<BuildPackage> packages,
  ) => BuildPackages.compute(
    singlePackageToBuild: package,
    outputRoot: package,
    packages: {for (final package in packages) package.name: package}.build(),
  );

  /// Creates [BuildPackages] from [BuildPackage]s for a workspace build with
  /// workspace name [workspace].
  @visibleForTesting
  factory BuildPackages.workspaceBuild(
    String workspace,
    Iterable<BuildPackage> packages,
  ) => BuildPackages.compute(
    outputRoot: workspace,
    packages: {for (final package in packages) package.name: package}.build(),
  );

  /// Loads the build packages for building the package at [packagePath].
  ///
  /// Assumes `pubspec.yaml` exists and has a name, as this is checked by
  /// `dart run`.
  ///
  /// If [workspace], prepares to build the whole workspace, if any.
  @visibleForTesting
  static Future<BuildPackages> forPath(
    String packagePath, {
    bool workspace = false,
  }) async => BuildPackagesLoader.forPath(packagePath, workspace: workspace);

  /// Creates a [BuildPackages] for the package in which you are currently
  /// running.
  ///
  /// If [workspace], prepares to build for the whole workspace, if any.
  static Future<BuildPackages> forThisPackage({bool workspace = false}) =>
      BuildPackages.forPath(p.current, workspace: workspace);

  static PackageConfig _packagesToConfig(Iterable<BuildPackage> packages) {
    final relativeLib = Uri.parse('lib/');

    return PackageConfig([
      for (final package in packages)
        if (package.name != _sdkPackage.name)
          Package(
            package.name,
            Uri.file(
              package.path.endsWith('/') ? package.path : '${package.path}/',
            ),
            languageVersion: package.languageVersion,
            packageUriRoot: relativeLib,
          ),
    ]);
  }

  /// Returns the package named [packageName], or `null` if not present.
  BuildPackage? operator [](String packageName) => packages[packageName];

  /// Map from package name to package language version.
  BuiltMap<String, LanguageVersion?> get languageVersions =>
      {
        for (final package in packages.values)
          package.name: package.languageVersion,
      }.build();

  @override
  String pathFor(
    AssetId id, {
    required bool hide,
    bool checkDeleteAllowed = false,
  }) {
    if (checkDeleteAllowed) {
      // Delete is allowed if it's a hidden output in `outputRoot` or if it's a
      // package in the build.
      final isUnderCacheDirectory = id.path.startsWith('$cacheDirectoryPath/');
      final deleteIsAllowed =
          hide ||
          (isUnderCacheDirectory && id.package == outputRoot) ||
          outputPackages.contains(id.package);
      if (!deleteIsAllowed) {
        if (isUnderCacheDirectory) {
          throw InvalidOutputException(
            id,
            'Tried to delete from $cacheDirectoryPath in wrong package, should '
            'be $outputRoot.',
          );
        } else {
          throw InvalidOutputException(
            id,
            'Tried to delete from package not in the build. Packages in the '
            'build are: ${outputPackages.join(', ')}',
          );
        }
      }
    }

    if (hide) {
      id = AssetPathProvider.hide(id, outputRoot);
    }
    final package = packages[id.package];
    if (package == null) {
      throw PackageNotFoundException(id.package);
    }
    var path = id.path;
    if (Platform.pathSeparator != '/') {
      path = path.replaceAll('/', Platform.pathSeparator);
    }
    return p.join(package.path, path);
  }

  /// Gets transitive deps of [packageName].
  ///
  /// Includes [packageName] itself.
  BuiltSet<String> transitiveDepsOf(String packageName) =>
      _transitiveDependencies[packageName]!;

  /// Gets peer packages of [packageName].
  ///
  /// Two packages are peers if they are both a transitive dependency of the
  /// same output package, meaning they are "in the same single package build".
  /// Builders can only auto apply from a package in the same build.
  BuiltSet<String> peersOf(String packageName) => _peerPackages[packageName]!;

  @override
  String toString() {
    final buffer = StringBuffer();
    for (final package in packages.values) {
      buffer.writeln('$package');
    }
    return buffer.toString();
  }
}

/// Returns the peer packages of each package.
///
/// See [BuildPackages.peersOf] for the definition of a peer package.
BuiltSetMultimap<String, String> _computePeers(
  Iterable<String> outputPackages,
  BuiltSetMultimap<String, String> transitiveDeps,
) {
  final result = SetMultimapBuilder<String, String>();

  for (final package in outputPackages) {
    final packageTransitiveDeps = transitiveDeps[package]!;
    for (final dependency in packageTransitiveDeps) {
      result.addValues(dependency, packageTransitiveDeps);
    }
  }

  return result.build();
}

/// Returns transitive deps of all packages in [packages].
///
/// The keys of the result map are ordered in reverse topological order.
BuiltSetMultimap<String, String> _computeAllTransitiveDeps(
  BuiltMap<String, BuildPackage> packages,
) {
  // Computes dep cycles in reverse topological order, "deps first", so they
  // can be processed in order without encountering unprocessed deps.
  final components = stronglyConnectedComponents<String>(
    packages.keys,
    (id) => packages[id]!.dependencies,
  );

  // Compute transitive deps for each strongly connected component.
  final result = <String, Set<String>>{};
  for (final component in components) {
    final componentSet = component.toSet();
    final componentTransitiveDeps = <String>{...componentSet};

    // For each package in the component add all transitive deps for
    // all direct deps not in the component.
    for (final package in component) {
      for (final dep in packages[package]!.dependencies) {
        if (componentSet.contains(dep)) continue;
        componentTransitiveDeps.addAll(result[dep]!);
      }
    }

    // Set the result for all packages in the component.
    for (final package in component) {
      result[package] = componentTransitiveDeps;
    }
  }

  return BuiltSetMultimap<String, String>(result);
}

/// Returns the transitive deps of [package].
Set<String> _computeTransitiveDeps(
  String package,
  BuiltMap<String, BuildPackage> packages,
) {
  final result = {package};
  final queue = result.toList();

  while (queue.isNotEmpty) {
    final next = queue.removeLast();
    for (final dependency in packages[next]!.dependencies) {
      if (!result.contains(dependency)) {
        result.add(dependency);
        queue.add(dependency);
      }
    }
  }
  return result;
}
