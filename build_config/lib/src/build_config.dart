// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'parse.dart';
import 'pubspec.dart';

/// The parsed values from a `build.yaml` file.
class BuildConfig {
  /// Returns a parsed [BuildConfig] file in [path], if one exist, otherwise a
  /// default config.
  ///
  /// [path] must be a directory which contains a `pubspec.yaml` file and
  /// optionally a `build.yaml`.
  static Future<BuildConfig> fromPackageDir(String path,
      {bool includeWebSources: false}) async {
    final pubspec = await Pubspec.fromPackageDir(path);
    return fromBuildConfigDir(
        pubspec.pubPackageName, pubspec.dependencies, path,
        includeWebSources: includeWebSources);
  }

  /// Returns a parsed [BuildConfig] file in [path], if one exists, otherwise a
  /// default config.
  ///
  /// [path] should the path to a directory which may contain a `build.yaml`.
  static Future<BuildConfig> fromBuildConfigDir(
      String packageName, Iterable<String> dependencies, String path,
      {bool includeWebSources: false}) async {
    final configPath = p.join(path, 'build.yaml');
    final file = new File(configPath);
    if (await file.exists()) {
      return new BuildConfig.parse(
          packageName, dependencies, await file.readAsString(),
          includeWebSources: includeWebSources);
    } else {
      return new BuildConfig.useDefault(packageName, dependencies,
          includeWebSources: includeWebSources);
    }
  }

  final String packageName;

  /// All the `builders` defined in a `build.yaml` file.
  final Map<String, BuilderDefinition> builderDefinitions;

  /// All the `targets` defined in a `build.yaml` file.
  final Map<String, BuildTarget> buildTargets;

  /// The default config if you have no `build.yaml` file.
  factory BuildConfig.useDefault(
      String packageName, Iterable<String> dependencies,
      {bool includeWebSources: false,
      List<String> platforms: const [],
      Iterable<String> excludeSources: const []}) {
    final sources = ["lib/**"];
    if (includeWebSources) sources.add("web/**");
    final buildTargets = {
      packageName: new BuildTarget(
          dependencies: dependencies,
          platforms: platforms,
          isDefault: true,
          name: packageName,
          package: packageName,
          sources: sources,
          excludeSources: excludeSources)
    };
    return new BuildConfig(
      packageName: packageName,
      buildTargets: buildTargets,
    );
  }

  /// Create a [BuildConfig] by parsing [configYaml].
  factory BuildConfig.parse(
          String packageName, Iterable<String> dependencies, String configYaml,
          {bool includeWebSources: false}) =>
      parseFromYaml(packageName, dependencies, configYaml,
          includeWebSources: includeWebSources);

  BuildConfig({
    @required this.packageName,
    @required this.buildTargets,
    this.builderDefinitions: const {},
  });

  BuildTarget get defaultBuildTarget =>
      buildTargets.values.singleWhere((l) => l.isDefault);
}

class BuilderDefinition {
  final String name;

  final String package;

  /// The names of the top-level methods in [import] from args -> Builder.
  final List<String> builderFactories;

  /// The import to be used to load `clazz`.
  final String import;

  /// A map from input extension to the output extensions created for matching
  /// inputs.
  final Map<String, List<String>> buildExtensions;

  /// The name of the dart_library target that contains `import`.
  final String target;

  /// Which packages should have this builder applied automatically.
  final AutoApply autoApply;

  /// A list of file extensions which are required to run this builder.
  ///
  /// No builder which outputs any extension in this list is allowed to run
  /// after this builder.
  final List<String> requiredInputs;

  /// Whether this Builder should be deferred until it's output is requested.
  ///
  /// Optional builders are lazy and will not run unless some later builder
  /// requests one of it's possible outputs through either `readAs*` or
  /// `canRead`.
  final bool isOptional;

  /// Where the outputs of this builder should be written.
  final BuildTo buildTo;

  BuilderDefinition({
    this.builderFactories,
    this.buildExtensions,
    this.import,
    this.name,
    this.package,
    this.target,
    this.autoApply,
    this.requiredInputs,
    this.isOptional,
    this.buildTo,
  });
}

enum AutoApply { none, dependents, allPackages, rootPackage }

enum BuildTo {
  /// Generated files are written to the source directory next to their primary
  /// inputs.
  source,

  /// Generated files are written to the hidden 'generated' directory.
  cache
}

class BuildTarget {
  final Iterable<String> dependencies;

  final Iterable<String> excludeSources;

  final String name;

  final String package;

  final Iterable<String> sources;

  /// A map from builder key to the configuration used for this target.
  ///
  /// Builder keys are in the format `"$package|$builder"`.
  final Map<String, BuilderConfig> builders;

  /// The platforms supported by this target.
  ///
  /// May be limited by, for isntance, importing core libraries that are not
  /// cross platform. An empty list indicates all platforms are supported.
  final List<String> platforms;

  /// Whether or not this is the default dart library for the package.
  final bool isDefault;

  BuildTarget(
      {this.builders: const {},
      this.dependencies,
      this.platforms: const [],
      this.excludeSources: const [],
      this.isDefault: false,
      this.name,
      this.package,
      this.sources: const ['lib/**']});

  @override
  String toString() => {
        'package': package,
        'name': name,
        'isDefault': isDefault,
        'sources': sources,
        'excludeSources': excludeSources,
        'builders': builders
      }.toString();
}

/// The configuration a particular [BuildTarget] applies to a Builder.
///
/// Build targets may have builders applied automatically based on
/// [BuilderDefinition.autoApply] and may override with more specific
/// configuration.
class BuilderConfig {
  /// Overrides the setting of whether the Builder would run on this target.
  ///
  /// Builders may run on this target by default based on the `apply_to`
  /// argument. If this value is set it overrides the default.
  final bool isEnabled;

  /// Sources to use as inputs for this Builder in glob format.
  ///
  /// This is always a subset of the `include` argument in the containing
  /// [BuildTarget].
  ///
  /// May be `null`, in which case it should fall back on `sources`.
  final Iterable<String> generateFor;

  final BuilderOptions options;

  BuilderConfig({
    this.isEnabled,
    this.generateFor,
    this.options: const BuilderOptions(const {}),
  });

  @override
  String toString() => {
        'isEnable': isEnabled,
        'generateFor': generateFor,
        'options': options?.config
      }.toString();
}
