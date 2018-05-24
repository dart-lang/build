// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'build_target.dart';
import 'builder_definition.dart';
import 'common.dart';
import 'expandos.dart';
import 'input_set.dart';
import 'key_normalization.dart';
import 'pubspec.dart';

part 'build_config.g.dart';

/// The parsed values from a `build.yaml` file.
@JsonSerializable(createToJson: false)
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

  @JsonKey(ignore: true)
  final String packageName;

  /// All the `builders` defined in a `build.yaml` file.
  @JsonKey(name: 'builders')
  final Map<String, BuilderDefinition> builderDefinitions;

  /// All the `post_process_builders` defined in a `build.yaml` file.
  @JsonKey(name: 'post_process_builders')
  final Map<String, PostProcessBuilderDefinition> postProcessBuilderDefinitions;

  /// All the `targets` defined in a `build.yaml` file.
  @JsonKey(name: 'targets')
  final Map<String, BuildTarget> buildTargets;

  /// The default config if you have no `build.yaml` file.
  factory BuildConfig.useDefault(
      String packageName, Iterable<String> dependencies) {
    final key = '$packageName:$packageName';
    final target = new BuildTarget(
      dependencies: dependencies
          .map((dep) => normalizeTargetKeyUsage(dep, packageName))
          .toList(),
      sources: InputSet.anything,
    );
    return new BuildConfig(
      packageName: packageName,
      buildTargets: {key: target},
    );
  }

  /// Create a [BuildConfig] by parsing [configYaml].
  factory BuildConfig.parse(
      String packageName, Iterable<String> dependencies, String configYaml) {
    var parsed = loadYaml(configYaml) as Map;
    return new BuildConfig.fromMap(
        packageName, dependencies, new Map.from(parsed ?? const {}));
  }

  /// Create a [BuildConfig] read a map which was already parsed.
  factory BuildConfig.fromMap(
      String packageName, Iterable<String> dependencies, Map config) {
    return runInBuildConfigZone(() => new BuildConfig._fromJson(config),
        packageName, dependencies.toList());
  }

  BuildConfig({
    String packageName,
    @required Map<String, BuildTarget> buildTargets,
    Map<String, BuilderDefinition> builderDefinitions,
    Map<String, PostProcessBuilderDefinition> postProcessBuilderDefinitions:
        const {},
  })  : this.buildTargets = _normalizeBuildTargetKeys(
            buildTargets ??
                {
                  r'$default': new BuildTarget(
                    dependencies: currentPackageDefaultDependencies,
                  )
                },
            packageName ?? currentPackage),
        this.builderDefinitions = _normalizeBuilderDefinitions(
            builderDefinitions ?? const {}, packageName ?? currentPackage),
        this.postProcessBuilderDefinitions = _normalizeBuilderDefinitions(
            postProcessBuilderDefinitions ?? const {},
            packageName ?? currentPackage),
        this.packageName = packageName ?? currentPackage {
    // Set up the expandos for all our build targets and definitions so they
    // can know which package and builder key they refer to.
    this.buildTargets.forEach((key, target) {
      packageExpando[target] = this.packageName;
      builderKeyExpando[target] = key;
    });
    this.builderDefinitions.forEach((key, definition) {
      packageExpando[definition] = this.packageName;
      builderKeyExpando[definition] = key;
    });
    this.postProcessBuilderDefinitions.forEach((key, definition) {
      packageExpando[definition] = this.packageName;
      builderKeyExpando[definition] = key;
    });

    if (!this.buildTargets.containsKey(_defaultTarget(this.packageName))) {
      throw new ArgumentError('Must specify a target with the name '
          '`${this.packageName}` or `\$default`.');
    }
  }

  factory BuildConfig._fromJson(Map json) => _$BuildConfigFromJson(json);
}

String _defaultTarget(String package) => '$package:$package';

Map<String, BuildTarget> _normalizeBuildTargetKeys(
        Map<String, BuildTarget> buildTargets, String packageName) =>
    buildTargets.map((key, target) =>
        new MapEntry(normalizeTargetKeyDefinition(key, packageName), target));

Map<String, T> _normalizeBuilderDefinitions<T>(
        Map<String, T> builderDefinitions, String packageName) =>
    builderDefinitions.map((key, definition) => new MapEntry(
        normalizeBuilderKeyDefinition(key, packageName), definition));
