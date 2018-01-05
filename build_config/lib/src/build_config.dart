// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'key_normalization.dart';
import 'parse.dart';
import 'pubspec.dart';

/// A filter on files inputs or sources.
///
/// Takes a list of strings in glob format for [include] and [exclude]. Matches
/// the `glob()` function in skylark.
class InputSet {
  /// The globs to include in the set.
  ///
  /// May be null or empty which means every possible path (like `'**'`).
  final List<String> include;

  /// The globs as a subset of [include] to remove from the set.
  ///
  /// May be null or empty which means every path in [include].
  final List<String> exclude;

  const InputSet({this.include, this.exclude});

  @override
  String toString() {
    final result = new StringBuffer();
    if (include == null || include.isEmpty) {
      result.write('any path');
    } else {
      result.write('paths matching $include');
    }
    if (exclude != null && exclude.isNotEmpty) {
      result.write(' except $exclude');
    }
    return '$result';
  }
}

/// The parsed values from a `build.yaml` file.
class BuildConfig {
  /// Returns a parsed [BuildConfig] file in [path], if one exist, otherwise a
  /// default config.
  ///
  /// [path] must be a directory which contains a `pubspec.yaml` file and
  /// optionally a `build.yaml`.
  static Future<BuildConfig> fromPackageDir(String path) async {
    final pubspec = await Pubspec.fromPackageDir(path);
    return fromBuildConfigDir(
        pubspec.pubPackageName, pubspec.dependencies, path);
  }

  /// Returns a parsed [BuildConfig] file in [path], if one exists, otherwise a
  /// default config.
  ///
  /// [path] should the path to a directory which may contain a `build.yaml`.
  static Future<BuildConfig> fromBuildConfigDir(
      String packageName, Iterable<String> dependencies, String path) async {
    final configPath = p.join(path, 'build.yaml');
    final file = new File(configPath);
    if (await file.exists()) {
      return new BuildConfig.parse(
          packageName, dependencies, await file.readAsString());
    } else {
      return new BuildConfig.useDefault(packageName, dependencies);
    }
  }

  final String packageName;

  /// All the `builders` defined in a `build.yaml` file.
  final Map<String, BuilderDefinition> builderDefinitions;

  /// All the `targets` defined in a `build.yaml` file.
  final Map<String, BuildTarget> buildTargets;

  /// The default config if you have no `build.yaml` file.
  factory BuildConfig.useDefault(
      String packageName, Iterable<String> dependencies) {
    final defaultTarget = '$packageName:$packageName';
    final buildTargets = {
      defaultTarget: new BuildTarget(
        dependencies: dependencies
            .map((dep) => normalizeTargetKeyUsage(dep, packageName))
            .toSet(),
        package: packageName,
        key: defaultTarget,
        sources: const InputSet(),
      )
    };
    return new BuildConfig(
      packageName: packageName,
      buildTargets: buildTargets,
    );
  }

  /// Create a [BuildConfig] by parsing [configYaml].
  factory BuildConfig.parse(String packageName, Iterable<String> dependencies,
          String configYaml) =>
      parseFromYaml(packageName, dependencies, configYaml);

  /// Create a [BuildConfig] read a map which was already parsed.
  factory BuildConfig.fromMap(String packageName, Iterable<String> dependencies,
          Map<String, dynamic> config) =>
      parseFromMap(packageName, dependencies, config);

  BuildConfig({
    @required this.packageName,
    @required this.buildTargets,
    this.builderDefinitions: const {},
  });
}

class BuilderDefinition {
  /// The package which provides this Builder.
  final String package;

  /// A unique key for this Builder in `'$package|$builder'` format.
  final String key;

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

  final TargetBuilderConfigDefaults defaults;

  BuilderDefinition({
    @required this.package,
    @required this.key,
    @required this.builderFactories,
    @required this.buildExtensions,
    @required this.import,
    @required this.target,
    this.autoApply,
    this.requiredInputs,
    this.isOptional,
    this.buildTo,
    this.defaults,
  });

  @override
  String toString() => {
        'target': target,
        'autoApply': autoApply,
        'import': import,
        'builderFactories': builderFactories,
        'buildExtensions': buildExtensions,
        'requiredInputs': requiredInputs,
        'isOptional': isOptional,
        'buildTo': buildTo,
        'defaults': defaults,
      }.toString();
}

/// Default values that builder authors can specify when users don't fill in the
/// corresponding key for [TargetBuilderConfig].
class TargetBuilderConfigDefaults {
  final InputSet generateFor;

  TargetBuilderConfigDefaults({this.generateFor});
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
  final Set<String> dependencies;

  final String package;

  /// A unique key for this target in `'$package:$target'` format.
  final String key;

  final InputSet sources;

  /// A map from builder key to the configuration used for this target.
  ///
  /// Builder keys are in the format `"$package|$builder"`. This does not
  /// represent the full set of builders that are applied to the target, only
  /// those which have configuration customized against the default.
  final Map<String, TargetBuilderConfig> builders;

  BuildTarget({
    @required this.package,
    @required this.key,
    this.sources: const InputSet(),
    this.dependencies,
    this.builders: const {},
  });

  @override
  String toString() => {
        'package': package,
        'sources': sources,
        'dependencies': dependencies,
        'builders': builders,
      }.toString();
}

/// The configuration a particular [BuildTarget] applies to a Builder.
///
/// Build targets may have builders applied automatically based on
/// [BuilderDefinition.autoApply] and may override with more specific
/// configuration.
class TargetBuilderConfig {
  /// Overrides the setting of whether the Builder would run on this target.
  ///
  /// Builders may run on this target by default based on the `apply_to`
  /// argument, set to `false` to disable a Builder which would otherwise run.
  ///
  /// By default including a config for a Builder enables that builder.
  final bool isEnabled;

  /// Sources to use as inputs for this Builder in glob format.
  ///
  /// This is always a subset of the `include` argument in the containing
  /// [BuildTarget]. May be `null` in which cases it will be all the sources in
  /// the target.
  final InputSet generateFor;

  /// The options to pass to the `BuilderFactory` when constructing this
  /// builder.
  ///
  /// The `options` key in the configuration.
  final BuilderOptions options;

  TargetBuilderConfig({
    this.isEnabled,
    this.generateFor,
    this.options: const BuilderOptions(const {}),
  });

  @override
  String toString() => {
        'isEnabled': isEnabled,
        'generateFor': generateFor,
        'options': options.config
      }.toString();
}
