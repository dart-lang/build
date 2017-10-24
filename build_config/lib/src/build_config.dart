// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'pubspec.dart';

/// The parsed values from a `build.yaml` file.
class BuildConfig {
  /// Supported values for the `platforms` attribute.
  static const _allPlatforms = const [
    _vmPlatform,
    _webPlatform,
    _flutterPlatform,
  ];
  static const _vmPlatform = 'vm';
  static const _webPlatform = 'web';
  static const _flutterPlatform = 'flutter';

  static const _targetOptions = const [
    _builders,
    _default,
    _dependencies,
    _excludeSources,
    _generateFor,
    _platforms,
    _sources,
  ];
  static const _builders = 'builders';
  static const _default = 'default';
  static const _dependencies = 'dependencies';
  static const _excludeSources = 'exclude_sources';
  static const _generateFor = 'generate_for';
  static const _platforms = 'platforms';
  static const _sources = 'sources';

  static const _builderOptions = const [
    _builderFactories,
    _import,
    _buildExtensions,
    _target,
  ];
  static const _builderFactories = 'builder_factories';
  static const _import = 'import';
  static const _buildExtensions = 'build_extensions';
  static const _target = 'target';

  /// Returns a parsed [BuildConfig] file in [path], if one exists.
  ///
  /// Otherwise uses the default setup.
  static Future<BuildConfig> fromPackageDir(Pubspec pubspec, String path,
      {bool includeWebSources: false}) async {
    final configPath = p.join(path, 'build.yaml');
    final file = new File(configPath);
    if (await file.exists()) {
      return new BuildConfig.parse(pubspec, await file.readAsString(),
          includeWebSources: includeWebSources);
    } else {
      return new BuildConfig.useDefault(pubspec,
          includeWebSources: includeWebSources);
    }
  }

  final String packageName;

  /// All the `builders` defined in a `build.yaml` file.
  final builderDefinitions = <String, BuilderDefinition>{};

  /// All the `targets` defined in a `build.yaml` file.
  final buildTargets = <String, BuildTarget>{};

  /// The default config if you have no `build.yaml` file.
  BuildConfig.useDefault(Pubspec pubspec,
      {bool includeWebSources: false,
      List<String> platforms: const [],
      Iterable<String> excludeSources: const []})
      : packageName = pubspec.pubPackageName {
    var sources = ["lib/**"];
    if (includeWebSources) sources.add("web/**");
    buildTargets[packageName] = new BuildTarget(
        dependencies: pubspec.dependencies,
        platforms: platforms,
        isDefault: true,
        name: packageName,
        package: pubspec.pubPackageName,
        sources: sources,
        excludeSources: excludeSources);
  }

  /// Create a [BuildConfig] by parsing [configYaml].
  BuildConfig.parse(Pubspec pubspec, String configYaml,
      {bool includeWebSources: false})
      : packageName = pubspec.pubPackageName {
    final config = loadYaml(configYaml);

    final Map<String, Map> targetConfigs =
        config['targets'] as Map<String, Map> ?? {};
    for (var targetName in targetConfigs.keys) {
      var targetConfig = _readMapOrThrow(
          targetConfigs, targetName, _targetOptions, 'target `$targetName`');

      final builders = _readBuildersOrThrow(targetConfig, _builders);

      final dependencies = _readListOfStringsOrThrow(
          targetConfig, _dependencies,
          defaultValue: []);

      final excludeSources = _readListOfStringsOrThrow(
          targetConfig, _excludeSources,
          defaultValue: []);

      var isDefault =
          _readBoolOrThrow(targetConfig, _default, defaultValue: false);

      final platforms = _readListOfStringsOrThrow(targetConfig, _platforms,
          defaultValue: [], validValues: _allPlatforms);

      final sources = _readListOfStringsOrThrow(targetConfig, _sources);

      final generateFor = _readListOfStringsOrThrow(targetConfig, _generateFor,
          allowNull: true);

      buildTargets[targetName] = new BuildTarget(
        builders: builders,
        dependencies: dependencies,
        platforms: platforms,
        excludeSources: excludeSources,
        generateFor: generateFor,
        isDefault: isDefault,
        name: targetName,
        package: packageName,
        sources: sources,
      );
    }

    // Add the default dart library if there are no targets discovered.
    if (buildTargets.isEmpty) {
      var sources = ["lib/**"];
      if (includeWebSources) sources.add("web/**");
      buildTargets[pubspec.pubPackageName] = new BuildTarget(
          dependencies: pubspec.dependencies,
          isDefault: true,
          name: pubspec.pubPackageName,
          package: pubspec.pubPackageName,
          sources: sources);
    }

    if (buildTargets.values.where((l) => l.isDefault).length != 1) {
      throw new ArgumentError('Found no targets with `$_default: true`. '
          'Expected exactly one.');
    }

    final Map<String, Map> builderConfigs =
        config['builders'] as Map<String, Map> ?? {};
    for (var builderName in builderConfigs.keys) {
      final builderConfig = _readMapOrThrow(builderConfigs, builderName,
          _builderOptions, 'builder `$builderName`',
          defaultValue: <String, dynamic>{});

      final builderFactories =
          _readListOfStringsOrThrow(builderConfig, _builderFactories);
      final import = _readStringOrThrow(builderConfig, _import);
      final buildExtensions = _readBuildExtensions(builderConfig);
      final target = _readStringOrThrow(builderConfig, _target);

      builderDefinitions[builderName] = new BuilderDefinition(
        builderFactories: builderFactories,
        import: import,
        buildExtensions: buildExtensions,
        name: builderName,
        package: pubspec.pubPackageName,
        target: target,
      );
    }
  }

  BuildTarget get defaultBuildTarget =>
      buildTargets.values.singleWhere((l) => l.isDefault);

  static Map<String, Map<String, dynamic>> _readBuildersOrThrow(
      Map<String, dynamic> options, String option) {
    var values = options[option];
    if (values == null) return const {};

    if (values is! List) {
      throw new ArgumentError(
          'Got `$values` for `$option` but expected a List.');
    }

    final normalizedValues = <String, Map<String, dynamic>>{};
    for (var value in values) {
      if (value is String) {
        normalizedValues[value] = {};
      } else if (value is Map<String, dynamic>) {
        if (value.length == 1) {
          normalizedValues[value.keys.first] =
              value.values.first as Map<String, dynamic>;
        } else {
          throw value;
        }
      } else {
        throw new ArgumentError(
            'Got `$value` for builder but expected a String or Map');
      }
    }
    return normalizedValues;
  }

  static List<String> _readListOfStringsOrThrow(
      Map<String, dynamic> options, String option,
      {List<String> defaultValue,
      Iterable<String> validValues,
      bool allowNull: false}) {
    var value = options[option] ?? defaultValue;
    if (value == null && allowNull) return null;

    if (value is! List || (value as List).any((v) => v is! String)) {
      throw new ArgumentError(
          'Got `$value` for `$option` but expected a List<String>.');
    }
    if (validValues != null) {
      var invalidValues =
          (value as List).where((v) => !validValues.contains(v));
      if (invalidValues.isNotEmpty) {
        throw new ArgumentError('Got invalid values ``$invalidValues` for '
            '`$option`. Only `$validValues` are supported.');
      }
    }
    return new List<String>.from(value as List);
  }

  static Map<String, List<String>> _readBuildExtensions(
      Map<String, dynamic> options) {
    dynamic value = options[_buildExtensions];
    if (value == null) {
      throw new ArgumentError('Missing configuratino for build_extensions');
    }
    if (value is! Map<String, List<String>>) {
      throw new ArgumentError('Invalid value for build_extensions, '
          'got `$value` but expected a Map');
    }
    return value as Map<String, List<String>>;
  }

  static Map<String, dynamic> _readMapOrThrow(Map<String, dynamic> options,
      String option, Iterable<String> validKeys, String description,
      {Map<String, dynamic> defaultValue}) {
    var value = options[option] ?? defaultValue;
    if (value is! Map) {
      throw new ArgumentError('Invalid options for `$option`, got `$value` but '
          'expected a Map.');
    }
    var mapValue = value as Map<String, dynamic>;
    var invalidOptions = mapValue.keys.toList()
      ..removeWhere((k) => validKeys.contains(k));
    if (invalidOptions.isNotEmpty) {
      throw new ArgumentError('Got invalid options `$invalidOptions` for '
          '$description. Only `$validKeys` are supported keys.');
    }
    return mapValue;
  }

  static String _readStringOrThrow(Map<String, dynamic> options, String option,
      {String defaultValue, bool allowNull: false}) {
    var value = options[option];
    if (value == null && allowNull) return null;
    if (value is! String) {
      throw new ArgumentError(
          'Expected a String for `$option` but got `$value`.');
    }
    return value as String;
  }

  static bool _readBoolOrThrow(Map<String, dynamic> options, String option,
      {bool defaultValue}) {
    var value = options[option] ?? defaultValue;
    if (value is! bool) {
      throw new ArgumentError(
          'Expected a boolean for `$option` but got `$value`.');
    }
    return value as bool;
  }
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

  BuilderDefinition(
      {this.builderFactories,
      this.buildExtensions,
      this.import,
      this.name,
      this.package,
      this.target});
}

class BuildTarget {
  final Iterable<String> dependencies;

  final Iterable<String> excludeSources;

  final String name;

  final String package;

  final Iterable<String> sources;

  /// A map from builder name to the configuration used for this target.
  final Map<String, Map<String, dynamic>> builders;

  /// The platforms supported by this target.
  ///
  /// May be limited by, for isntance, importing core libraries that are not
  /// cross platform. An empty list indicates all platforms are supported.
  final List<String> platforms;

  /// Whether or not this is the default dart library for the package.
  final bool isDefault;

  /// Sources to use as inputs for `builders`. May be `null`, in which case
  /// it should fall back on `sources`.
  final Iterable<String> generateFor;

  BuildTarget(
      {this.builders: const {},
      this.dependencies,
      this.platforms: const [],
      this.excludeSources: const [],
      this.generateFor,
      this.isDefault: false,
      this.name,
      this.package,
      this.sources: const ['lib/**']});
}
