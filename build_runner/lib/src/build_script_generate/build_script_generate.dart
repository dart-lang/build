// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/build_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:graphs/graphs.dart';
import 'package:logging/logging.dart';

import '../logging/logging.dart';
import '../package_graph/build_config_overrides.dart';
import '../util/constants.dart';
import 'builder_ordering.dart';

const scriptLocation = '$entryPointDir/build.dart';

Future<String> generateBuildScript([String configKey]) => logTimedAsync(
    new Logger('Entrypoint'),
    'Generating build script',
    () => _generateBuildScript(configKey));

Future<String> _generateBuildScript(String configKey) async {
  final builders = await _findBuilderApplications(configKey);
  final library = new Library((b) => b.body.addAll(
      [literalList(builders).assignFinal('_builders').statement, _main()]));
  final emitter = new DartEmitter(new Allocator.simplePrefixing());
  return new DartFormatter().format('${library.accept(emitter)}');
}

/// Finds expressions to create all the [BuilderApplication] instances that
/// should be applied packages in the build.
///
/// Adds `apply` expressions based on the BuildefDefinitions from any package
/// which has a `build.yaml`.
Future<Iterable<Expression>> _findBuilderApplications(String configKey) async {
  final builderApplications = <Expression>[];
  final packageGraph = new PackageGraph.forThisPackage();
  final orderedPackages = stronglyConnectedComponents<String, PackageNode>(
          [packageGraph.root], (node) => node.name, (node) => node.dependencies)
      .expand((c) => c);
  final buildConfigOverrides =
      await findBuildConfigOverrides(packageGraph, configKey);
  Future<BuildConfig> _packageBuildConfig(PackageNode package) async {
    if (buildConfigOverrides.containsKey(package.name)) {
      return buildConfigOverrides[package.name];
    }
    return BuildConfig.fromBuildConfigDir(
        package.name, package.dependencies.map((n) => n.name), package.path);
  }

  bool _isValidDefinition(dynamic definition) {
    // Filter out builderDefinitions with relative imports that aren't
    // from the root package, because they will never work.
    if (definition.import.startsWith('package:') as bool) return true;
    return definition.package == packageGraph.root.name;
  }

  final orderedConfigs =
      await Future.wait(orderedPackages.map(_packageBuildConfig));
  final builderDefinitions = orderedConfigs
      .expand((c) => c.builderDefinitions.values)
      .where(_isValidDefinition);

  final orderedBuilders = findBuilderOrder(builderDefinitions).toList();
  builderApplications.addAll(orderedBuilders.map(_applyBuilder));

  final postProcessBuilderDefinitions = orderedConfigs
      .expand((c) => c.postProcessBuilderDefinitions.values)
      .where(_isValidDefinition);
  builderApplications
      .addAll(postProcessBuilderDefinitions.map(_applyPostProcessBuilder));

  return builderApplications;
}

/// A method forwarding to `run`.
Method _main() => new Method((b) => b
  ..name = 'main'
  ..modifier = MethodModifier.async
  ..requiredParameters.add(new Parameter((b) => b
    ..name = 'args'
    ..type = new TypeReference((b) => b
      ..symbol = 'List'
      ..types.add(refer('String')))))
  ..optionalParameters.add(new Parameter((b) => b
    ..name = 'sendPort'
    ..type = refer('SendPort', 'dart:isolate')))
  ..body = new Block.of([
    refer('run', 'package:build_runner/build_runner.dart')
        .call([refer('args'), refer('_builders')])
        .awaited
        .assignVar('result')
        .statement,
    refer('sendPort')
        .nullSafeProperty('send')
        .call([refer('result')]).statement,
  ]));

/// An expression calling `apply` with appropriate setup for a Builder.
Expression _applyBuilder(BuilderDefinition definition) {
  final namedArgs = <String, Expression>{};
  if (definition.isOptional) {
    namedArgs['isOptional'] = literalTrue;
  }
  if (definition.buildTo == BuildTo.cache) {
    namedArgs['hideOutput'] = literalTrue;
  } else {
    namedArgs['hideOutput'] = literalFalse;
  }
  if (!identical(definition.defaults?.generateFor, InputSet.anything)) {
    final inputSetArgs = <String, Expression>{};
    if (definition.defaults.generateFor.include != null) {
      inputSetArgs['include'] =
          literalConstList(definition.defaults.generateFor.include);
    }
    if (definition.defaults.generateFor.exclude != null) {
      inputSetArgs['exclude'] =
          literalConstList(definition.defaults.generateFor.exclude);
    }
    namedArgs['defaultGenerateFor'] =
        refer('InputSet', 'package:build_config/build_config.dart')
            .constInstance([], inputSetArgs);
  }
  if (!identical(definition.defaults?.options, BuilderOptions.empty)) {
    namedArgs['defaultOptions'] =
        _constructBuilderOptions(definition.defaults.options);
  }
  if (!identical(definition.defaults?.devOptions, BuilderOptions.empty)) {
    namedArgs['defaultDevOptions'] =
        _constructBuilderOptions(definition.defaults.devOptions);
  }
  if (!identical(definition.defaults?.releaseOptions, BuilderOptions.empty)) {
    namedArgs['defaultReleaseOptions'] =
        _constructBuilderOptions(definition.defaults.releaseOptions);
  }
  if (definition.appliesBuilders.isNotEmpty) {
    namedArgs['appliesBuilders'] = literalList(definition.appliesBuilders);
  }
  return refer('apply', 'package:build_runner/build_runner.dart').call([
    literalString(definition.key),
    literalList(definition.builderFactories
        .map((f) => refer(f, definition.import))
        .toList()),
    _findToExpression(definition),
  ], namedArgs);
}

/// An expression calling `applyPostProcess` with appropriate setup for a
/// PostProcessBuilder.
Expression _applyPostProcessBuilder(PostProcessBuilderDefinition definition) {
  final namedArgs = <String, Expression>{};
  if (definition.defaults?.generateFor != null) {
    final inputSetArgs = <String, Expression>{};
    if (definition.defaults.generateFor.include != null) {
      inputSetArgs['include'] =
          literalConstList(definition.defaults.generateFor.include);
    }
    if (definition.defaults.generateFor.exclude != null) {
      inputSetArgs['exclude'] =
          literalConstList(definition.defaults.generateFor.exclude);
    }
    namedArgs['defaultGenerateFor'] =
        refer('InputSet', 'package:build_config/build_config.dart')
            .constInstance([], inputSetArgs);
  }
  return refer('applyPostProcess', 'package:build_runner/build_runner.dart')
      .call([
    literalString(definition.key),
    refer(definition.builderFactory, definition.import),
  ], namedArgs);
}

Expression _findToExpression(BuilderDefinition definition) {
  switch (definition.autoApply) {
    case AutoApply.none:
      return refer('toNoneByDefault', 'package:build_runner/build_runner.dart')
          .call([]);
    case AutoApply.dependents:
      return refer('toDependentsOf', 'package:build_runner/build_runner.dart')
          .call([literalString(definition.package)]);
    case AutoApply.allPackages:
      return refer('toAllPackages', 'package:build_runner/build_runner.dart')
          .call([]);
    case AutoApply.rootPackage:
      return refer('toRoot', 'package:build_runner/build_runner.dart').call([]);
  }
  throw new ArgumentError('Unhandled AutoApply type: ${definition.autoApply}');
}

/// An expression creating a [BuilderOptions] from a json string.
Expression _constructBuilderOptions(BuilderOptions options) =>
    refer('BuilderOptions', 'package:build/build.dart').newInstance([
      refer('json', 'dart:convert')
          .property('decode')
          .call([literalString(json.encode(options.config))])
    ]);
