// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart' show AssetId, BuilderOptions;
import 'package:build_config/build_config.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:graphs/graphs.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../package_graph/build_config_overrides.dart';
import 'builder_ordering.dart';

const scriptLocation = '$entryPointDir/build.dart';
const scriptKernelLocation = '$scriptLocation$scriptKernelSuffix';
const scriptKernelSuffix = '.dill';
const scriptKernelCachedLocation =
    '$scriptKernelLocation$scriptKernelCachedSuffix';
const scriptKernelCachedSuffix = '.cached';

final _log = Logger('Entrypoint');

Future<String> generateBuildScript() =>
    logTimedAsync(_log, 'Generating build script', _generateBuildScript);

Future<String> _generateBuildScript() async {
  final info = await findBuildScriptOptions();
  final builders = info.builderApplications;
  final library = Library((b) => b.body.addAll([
        declareFinal('_builders')
            .assign(literalList(
                builders,
                refer('BuilderApplication',
                    'package:build_runner_core/build_runner_core.dart')))
            .statement,
        _main()
      ]));
  final emitter = DartEmitter(
      allocator: Allocator.simplePrefixing(), useNullSafetySyntax: true);
  try {
    final content = StringBuffer()
      ..writeln('// ignore_for_file: directives_ordering')
      ..writeln(library.accept(emitter));

    return DartFormatter().format(content.toString());
  } on FormatterException {
    _log.severe('Generated build script could not be parsed.\n'
        'This is likely caused by a misconfigured builder definition.');
    throw CannotBuildException();
  }
}

/// Finds expressions to create all the `BuilderApplication` instances that
/// should be applied packages in the build.
///
/// Adds `apply` expressions based on the BuildefDefinitions from any package
/// which has a `build.yaml`.
///
/// Optionally, a custom [packageGraph] and [buildConfigOverrides] can be used
/// to change which packages and build configurations are considered.
/// By default, the [PackageGraph.forThisPackage] will be used and configuration
/// overrides will be loaded from the root package.
Future<Iterable<Expression>> findBuilderApplications({
  PackageGraph? packageGraph,
  Map<String, BuildConfig>? buildConfigOverrides,
}) async {
  final info = await findBuildScriptOptions(
      packageGraph: packageGraph, buildConfigOverrides: buildConfigOverrides);
  return info.builderApplications;
}

Future<BuildScriptInfo> findBuildScriptOptions({
  PackageGraph? packageGraph,
  Map<String, BuildConfig>? buildConfigOverrides,
}) async {
  packageGraph ??= await PackageGraph.forThisPackage();
  final orderedPackages = stronglyConnectedComponents<PackageNode>(
    [packageGraph.root],
    (node) => node.dependencies,
    equals: (a, b) => a.name == b.name,
    hashCode: (n) => n.name.hashCode,
  ).expand((c) => c);
  var reader = FileBasedAssetReader(packageGraph);
  var overrides = buildConfigOverrides ??=
      await findBuildConfigOverrides(packageGraph, reader);
  Future<BuildConfig> packageBuildConfig(PackageNode package) async {
    if (overrides.containsKey(package.name)) {
      return overrides[package.name]!;
    }
    try {
      return await BuildConfig.fromBuildConfigDir(
          package.name, package.dependencies.map((n) => n.name), package.path);
    } on ArgumentError // ignore: avoid_catching_errors
    catch (_) {
      // During the build an error will be logged.
      return BuildConfig.useDefault(
          package.name, package.dependencies.map((n) => n.name));
    }
  }

  // TODO: Remove the dynamic calls here. We don't have a shared interface
  // today and rely on dynamic calls instead which is bad.
  bool isValidDefinition(dynamic definition) {
    // Filter out builderDefinitions with relative imports that aren't
    // from the root package, because they will never work.
    // ignore: avoid_dynamic_calls
    final import = definition.import as String;
    if (import.startsWith('package:')) {
      // Make sure package is known in packageGraph (when present),
      // otherwise PackageNotFoundException will be thrown down the road
      final pkg = AssetId.resolve(Uri.parse(import)).package;
      if (packageGraph?.allPackages.containsKey(pkg) ?? true) {
        return true;
      }
      _log.warning('Could not load imported package "$pkg" for definition '
          // ignore: avoid_dynamic_calls
          '"${definition.key}".');
      return false;
    }
    // ignore: avoid_dynamic_calls
    return definition.package == packageGraph!.root.name;
  }

  final orderedConfigs =
      await Future.wait(orderedPackages.map(packageBuildConfig));
  final builderDefinitions = orderedConfigs
      .expand((c) => c.builderDefinitions.values)
      .where(isValidDefinition);

  final rootBuildConfig = orderedConfigs.last;
  final orderedBuilders =
      findBuilderOrder(builderDefinitions, rootBuildConfig.globalOptions)
          .toList();

  final postProcessBuilderDefinitions = orderedConfigs
      .expand((c) => c.postProcessBuilderDefinitions.values)
      .where(isValidDefinition);

  // Validate the builder keys in the global builder config, these should always
  // refer to actual builders.
  var allBuilderKeys = {for (var definition in orderedBuilders) definition.key};
  for (var globalBuilderConfig in rootBuildConfig.globalOptions.entries) {
    void checkBuilderKey(String builderKey) {
      if (allBuilderKeys.contains(builderKey)) return;
      _log.warning(
          'Invalid builder key `$builderKey` found in global_options config of '
          'build.yaml. This configuration will have no effect.');
    }

    checkBuilderKey(globalBuilderConfig.key);
    globalBuilderConfig.value.runsBefore.forEach(checkBuilderKey);
  }

  final applications = [
    for (var builder in orderedBuilders) _applyBuilder(builder),
    for (var builder in postProcessBuilderDefinitions)
      _applyPostProcessBuilder(builder)
  ];

  return BuildScriptInfo(applications);
}

class BuildScriptInfo {
  final Iterable<Expression> builderApplications;

  BuildScriptInfo(this.builderApplications);
}

/// A method forwarding to `run`.
Method _main() => Method((b) => b
  ..name = 'main'
  ..returns = refer('void')
  ..modifier = MethodModifier.async
  ..requiredParameters.add(Parameter((b) => b
    ..name = 'args'
    ..type = TypeReference((b) => b
      ..symbol = 'List'
      ..types.add(refer('String')))))
  ..optionalParameters.add(Parameter((b) => b
    ..name = 'sendPort'
    ..type = TypeReference((b) => b
      ..symbol = 'SendPort'
      ..url = 'dart:isolate'
      ..isNullable = true)))
  ..body = Block.of([
    declareVar('result')
        .assign(refer('run', 'package:build_runner/build_runner.dart')
            .call([refer('args'), refer('_builders')]).awaited)
        .statement,
    refer('sendPort')
        .nullSafeProperty('send')
        .call([refer('result')]).statement,
    refer('exitCode', 'dart:io').assign(refer('result')).statement,
  ]));

/// An expression calling `apply` with appropriate setup for a Builder.
Expression _applyBuilder(BuilderDefinition definition) {
  final namedArgs = {
    if (definition.isOptional) 'isOptional': literalTrue,
    if (definition.buildTo == BuildTo.cache)
      'hideOutput': literalTrue
    else
      'hideOutput': literalFalse,
    if (!identical(definition.defaults.generateFor, InputSet.anything))
      'defaultGenerateFor':
          refer('InputSet', 'package:build_config/build_config.dart')
              .constInstance([], {
        if (definition.defaults.generateFor.include != null)
          'include': _rawStringList(definition.defaults.generateFor.include!),
        if (definition.defaults.generateFor.exclude != null)
          'exclude': _rawStringList(definition.defaults.generateFor.exclude!),
      }),
    if (definition.defaults.options.isNotEmpty)
      'defaultOptions': _constructBuilderOptions(definition.defaults.options),
    if (definition.defaults.devOptions.isNotEmpty)
      'defaultDevOptions':
          _constructBuilderOptions(definition.defaults.devOptions),
    if (definition.defaults.releaseOptions.isNotEmpty)
      'defaultReleaseOptions':
          _constructBuilderOptions(definition.defaults.releaseOptions),
    if (definition.appliesBuilders.isNotEmpty)
      'appliesBuilders': _rawStringList(definition.appliesBuilders),
  };
  var import = _buildScriptImport(definition.import);
  return refer('apply', 'package:build_runner_core/build_runner_core.dart')
      .call([
    literalString(definition.key, raw: true),
    literalList([for (var f in definition.builderFactories) refer(f, import)]),
    _findToExpression(definition),
  ], namedArgs);
}

/// An expression calling `applyPostProcess` with appropriate setup for a
/// PostProcessBuilder.
Expression _applyPostProcessBuilder(PostProcessBuilderDefinition definition) {
  final namedArgs = {
    if (!identical(definition.defaults.generateFor, InputSet.anything))
      'defaultGenerateFor':
          refer('InputSet', 'package:build_config/build_config.dart')
              .constInstance([], {
        if (definition.defaults.generateFor.include != null)
          'include': _rawStringList(definition.defaults.generateFor.include!),
        if (definition.defaults.generateFor.exclude != null)
          'exclude': _rawStringList(definition.defaults.generateFor.exclude!),
      }),
    if (definition.defaults.options.isNotEmpty)
      'defaultOptions': _constructBuilderOptions(definition.defaults.options),
    if (definition.defaults.devOptions.isNotEmpty)
      'defaultDevOptions':
          _constructBuilderOptions(definition.defaults.devOptions),
    if (definition.defaults.releaseOptions.isNotEmpty)
      'defaultReleaseOptions':
          _constructBuilderOptions(definition.defaults.releaseOptions),
  };
  var import = _buildScriptImport(definition.import);
  return refer('applyPostProcess',
          'package:build_runner_core/build_runner_core.dart')
      .call([
    literalString(definition.key, raw: true),
    refer(definition.builderFactory, import),
  ], namedArgs);
}

Expression _rawStringList(List<String> strings) =>
    literalConstList([for (var s in strings) literalString(s, raw: true)]);

/// Returns the actual import to put in the generated script based on an import
/// found in the build.yaml.
String _buildScriptImport(String import) {
  if (import.startsWith('package:')) {
    return import;
  } else if (import.startsWith('../') || import.startsWith('/')) {
    _log.warning('The `../` import syntax in build.yaml is now deprecated, '
        'instead do a normal relative import as if it was from the root of '
        'the package. Found `$import` in your `build.yaml` file.');
    return import;
  } else {
    return p.url.relative(import, from: p.url.dirname(scriptLocation));
  }
}

Expression _findToExpression(BuilderDefinition definition) {
  switch (definition.autoApply) {
    case AutoApply.none:
      return refer('toNoneByDefault',
              'package:build_runner_core/build_runner_core.dart')
          .call([]);
    case AutoApply.dependents:
      return refer('toDependentsOf',
              'package:build_runner_core/build_runner_core.dart')
          .call([literalString(definition.package, raw: true)]);
    case AutoApply.allPackages:
      return refer('toAllPackages',
              'package:build_runner_core/build_runner_core.dart')
          .call([]);
    case AutoApply.rootPackage:
      return refer('toRoot', 'package:build_runner_core/build_runner_core.dart')
          .call([]);
  }
}

/// An expression creating a [BuilderOptions] from a json string.
Expression _constructBuilderOptions(Map<String, dynamic> options) =>
    refer('BuilderOptions', 'package:build/build.dart')
        .constInstance([options.toExpression()]);

/// Converts a Dart object to a source code representation.
///
/// This is similar to [literal] from `package:code_builder`, except that it
/// always writes raw string literals.
extension ConvertToExpression on Object? {
  Expression toExpression() {
    final $this = this;

    if ($this is Map) {
      return literalMap({
        for (final entry in $this.cast<Object?, Object?>().entries)
          entry.key.toExpression(): entry.value.toExpression()
      }, refer('String'), refer('dynamic'));
    } else if ($this is List) {
      return literalList(
          [for (final entry in $this.cast<Object?>()) entry.toExpression()],
          refer('dynamic'));
    } else if ($this is String) {
      return literalString($this, raw: true);
    } else {
      return literal(this);
    }
  }
}
