// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:yaml/yaml.dart';

import 'build_config.dart';

/// Supported values for the `platforms` attribute.
const _allPlatforms = const [
  _vmPlatform,
  _webPlatform,
  _flutterPlatform,
];
const _vmPlatform = 'vm';
const _webPlatform = 'web';
const _flutterPlatform = 'flutter';

const _targetOptions = const [
  _builders,
  _default,
  _dependencies,
  _excludeSources,
  _platforms,
  _sources,
];
const _builders = 'builders';
const _default = 'default';
const _dependencies = 'dependencies';
const _excludeSources = 'exclude_sources';
const _platforms = 'platforms';
const _sources = 'sources';

const _builderConfigOptions = const [
  _generateFor,
  _enabled,
  _options,
];
const _generateFor = 'generate_for';
const _enabled = 'enabled';
const _options = 'options';

const _builderDefinitionOptions = const [
  _builderFactories,
  _import,
  _buildExtensions,
  _target,
  _autoApply,
  _requiredInputs,
  _isOptional,
  _buildTo,
];
const _builderFactories = 'builder_factories';
const _import = 'import';
const _buildExtensions = 'build_extensions';
const _target = 'target';
const _autoApply = 'auto_apply';
const _requiredInputs = 'required_inputs';
const _isOptional = 'is_optional';
const _buildTo = 'build_to';

BuildConfig parseFromYaml(
    String packageName, Iterable<String> dependencies, String configYaml,
    {bool includeWebSources}) {
  includeWebSources ??= false;

  final buildTargets = <String, BuildTarget>{};
  final builderDefinitions = <String, BuilderDefinition>{};

  final config = loadYaml(configYaml);

  final Map<String, Map> targetConfigs =
      config['targets'] as Map<String, Map> ?? {};
  for (var targetName in targetConfigs.keys) {
    var targetConfig = _readMapOrThrow(
        targetConfigs, targetName, _targetOptions, 'target `$targetName`');

    final builders = _readBuildersOrThrow(targetConfig, _builders);

    final dependencies = _readListOfStringsOrThrow(targetConfig, _dependencies,
        defaultValue: []);

    final excludeSources = _readListOfStringsOrThrow(
        targetConfig, _excludeSources,
        defaultValue: []);

    var isDefault =
        _readBoolOrThrow(targetConfig, _default, defaultValue: false);

    final platforms = _readListOfStringsOrThrow(targetConfig, _platforms,
        defaultValue: [], validValues: _allPlatforms);

    final sources = _readListOfStringsOrThrow(targetConfig, _sources);

    buildTargets[targetName] = new BuildTarget(
      builders: builders,
      dependencies: dependencies,
      platforms: platforms,
      excludeSources: excludeSources,
      isDefault: isDefault,
      name: targetName,
      package: packageName,
      sources: sources,
    );
  }

  if (buildTargets.isEmpty) {
    // Add the default dart library if there are no targets discovered.
    var sources = ["lib/**"];
    if (includeWebSources) sources.add("web/**");
    buildTargets[packageName] = new BuildTarget(
        dependencies: dependencies,
        isDefault: true,
        name: packageName,
        package: packageName,
        sources: sources);
  } else if (buildTargets.length == 1 &&
      !buildTargets.values.single.isDefault) {
    // Allow omitting `isDefault` if there is exactly 1 target.
    buildTargets[buildTargets.keys.single] =
        new BuildTarget.asDefault(buildTargets.values.single);
  }

  if (buildTargets.values.where((l) => l.isDefault).length != 1) {
    throw new ArgumentError('Found no targets with `$_default: true`. '
        'Expected exactly one.');
  }

  final Map<String, Map> builderConfigs =
      config['builders'] as Map<String, Map> ?? {};
  for (var builderName in builderConfigs.keys) {
    final builderConfig = _readMapOrThrow(builderConfigs, builderName,
        _builderDefinitionOptions, 'builder `$builderName`',
        defaultValue: <String, dynamic>{});

    final builderFactories =
        _readListOfStringsOrThrow(builderConfig, _builderFactories);
    final import = _readStringOrThrow(builderConfig, _import);
    final buildExtensions = _readBuildExtensions(builderConfig);
    final target = _readStringOrThrow(builderConfig, _target);
    final autoApply = _readAutoApplyOrThrow(builderConfig, _autoApply,
        defaultValue: AutoApply.none);
    final requiredInputs = _readListOfStringsOrThrow(
        builderConfig, _requiredInputs,
        defaultValue: const []);
    final isOptional =
        _readBoolOrThrow(builderConfig, _isOptional, defaultValue: false);

    final mustBuildToCache =
        autoApply == AutoApply.dependents || autoApply == AutoApply.allPackages;
    final buildTo = _readBuildToOrThrow(builderConfig, _buildTo,
        defaultValue: mustBuildToCache ? BuildTo.cache : BuildTo.source);

    if (mustBuildToCache && buildTo != BuildTo.cache) {
      throw new ArgumentError('`hide_output` may not be set to `False` '
          'when using `auto_apply: ${builderConfig[_autoApply]}`');
    }

    builderDefinitions[builderName] = new BuilderDefinition(
      builderFactories: builderFactories,
      import: import,
      buildExtensions: buildExtensions,
      name: builderName,
      package: packageName,
      target: target,
      autoApply: autoApply,
      requiredInputs: requiredInputs,
      isOptional: isOptional,
      buildTo: buildTo,
    );
  }
  return new BuildConfig(
      packageName: packageName,
      buildTargets: buildTargets,
      builderDefinitions: builderDefinitions);
}

Map<String, List<String>> _readBuildExtensions(Map<String, dynamic> options) {
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

Map<String, dynamic> _readMapOrThrow(Map<String, dynamic> options,
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

String _readStringOrThrow(Map<String, dynamic> options, String option,
    {String defaultValue, bool allowNull: false}) {
  var value = options[option];
  if (value == null && allowNull) return null;
  if (value is! String) {
    throw new ArgumentError(
        'Expected a String for `$option` but got `$value`.');
  }
  return value as String;
}

bool _readBoolOrThrow(Map<String, dynamic> options, String option,
    {bool defaultValue, bool allowNull: false}) {
  var value = options[option] ?? defaultValue;
  // ignore: avoid_returning_null
  if (value == null && allowNull) return null;
  if (value is! bool) {
    throw new ArgumentError(
        'Expected a boolean for `$option` but got `$value`.');
  }
  return value as bool;
}

AutoApply _readAutoApplyOrThrow(Map<String, dynamic> options, String option,
    {AutoApply defaultValue}) {
  final value = options[option];
  if (value == null && defaultValue != null) return defaultValue;
  final allowedValues = const {
    'none': AutoApply.none,
    'dependents': AutoApply.dependents,
    'all_packages': AutoApply.allPackages,
    'root_package': AutoApply.rootPackage
  };
  if (value is! String || !allowedValues.containsKey(value)) {
    throw new ArgumentError('Expected one of ${allowedValues.keys.toList()} '
        'for `$option` but got `$value`');
  }
  return allowedValues[value];
}

BuildTo _readBuildToOrThrow(Map<String, dynamic> options, String option,
    {BuildTo defaultValue}) {
  final value = options[option];
  if (value == null && defaultValue != null) return defaultValue;
  final allowedValues = const {
    'source': BuildTo.source,
    'cache': BuildTo.cache,
  };
  if (value is! String || !allowedValues.containsKey(value)) {
    throw new ArgumentError('Expected one of ${allowedValues.keys.toList()} '
        'for `$option` but got `$value`');
  }
  return allowedValues[value];
}

Map<String, TargetBuilderConfig> _readBuildersOrThrow(
    Map<String, dynamic> options, String option) {
  final values = options[option];
  if (values == null) return const {};

  if (values is! Map<String, dynamic>) {
    throw new ArgumentError('Got `$values` for `$option` but expected a Map.');
  }
  final builderConfigs = values as Map<String, dynamic>;

  final parsedConfigs = <String, TargetBuilderConfig>{};
  for (final builderKey in builderConfigs.keys) {
    final builderConfig = _readMapOrThrow(builderConfigs, builderKey,
        _builderConfigOptions, 'builder config `$builderKey`',
        defaultValue: {});

    final isEnabled =
        _readBoolOrThrow(builderConfig, _enabled, allowNull: true);

    final generateFor =
        _readListOfStringsOrThrow(builderConfig, _generateFor, allowNull: true);

    var parsedOptions = const BuilderOptions(const {});
    if (builderConfig.containsKey(_options)) {
      final options = builderConfig[_options];
      if (options is! Map) {
        throw new ArgumentError('Invalid builder options for `$builderKey`, '
            'got `$options` but expected a Map');
      }
      parsedOptions = new BuilderOptions(options as Map<String, dynamic>);
    }
    parsedConfigs[builderKey] = new TargetBuilderConfig(
      isEnabled: isEnabled,
      generateFor: generateFor,
      options: parsedOptions,
    );
  }
  return parsedConfigs;
}

List<String> _readListOfStringsOrThrow(
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
    var invalidValues = (value as List).where((v) => !validValues.contains(v));
    if (invalidValues.isNotEmpty) {
      throw new ArgumentError('Got invalid values ``$invalidValues` for '
          '`$option`. Only `$validValues` are supported.');
    }
  }
  return new List<String>.from(value as List);
}
