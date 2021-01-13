// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart' show BuilderOptions;
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
const scriptSnapshotLocation = '$scriptLocation.snapshot';

final _log = Logger('Entrypoint');

/// Options to generate custom build scripts.
///
/// The build script is a generated Dart file in [scriptLocation]. It contains
/// all builder definitions part of the build and is used by the top-level
/// `build_runner` commands to run a build with the correct builders.
///
/// By providing custom generation options, it's possible to tweak parts of a
/// build script.
class BuildScriptGenerationOptions {
  const BuildScriptGenerationOptions();

  /// Builds a Dart expression to invoke a build.
  ///
  /// [args] is an expression evaluating to the command-line arguments passed
  /// to the build script.
  /// [builders] is an expression evaluating to a list of `BuilderApplication`s
  /// from `build_runner_core`.
  /// The expression should evaluate to a `Future<int>`. Its result will be
  /// posted to an optional `sendPort` of the generated entrypoint. Further,
  /// the generated script will set its exit code to the returned value.
  ///
  /// For reference, the default implementation calls `run(args, builders)`
  /// from `package:build_runner/build_runner.dart`.
  Expression runBuild(Expression args, Expression builders) {
    return refer('run', 'package:build_runner/build_runner.dart')
        .call([args, builders]);
  }

  /// The package graph to consider for builder applications.
  Future<PackageGraph> packageGraph() => PackageGraph.forThisPackage();

  /// Finds overrides for `build.yaml` configurations.
  ///
  /// Keys in the returned map correspond to package names, the associated value
  /// is the overriden build configuration.
  ///
  /// By default, the root package can override the build configuration of a
  /// package `foo` by declaring a `foo.build.yaml` file.
  Future<Map<String, BuildConfig>> findConfigOverrides(
      PackageGraph graph, RunnerAssetReader reader) {
    return findBuildConfigOverrides(graph, null, reader);
  }
}

Future<String> generateBuildScript(
    [BuildScriptGenerationOptions options =
        const BuildScriptGenerationOptions()]) {
  ArgumentError.checkNotNull(options, 'options');
  return logTimedAsync(_log, 'Generating build script', () {
    final generator = _BuildScriptGenerator(options);
    return generator._generateBuildScript();
  });
}

class _BuildScriptGenerator {
  final BuildScriptGenerationOptions _options;

  _BuildScriptGenerator(this._options);

  Future<String> _generateBuildScript() async {
    final builders = await _findBuilderApplications();
    final library = Library((b) => b.body.addAll([
          literalList(
                  builders,
                  refer('BuilderApplication',
                      'package:build_runner_core/build_runner_core.dart'))
              .assignFinal('_builders')
              .statement,
          _main()
        ]));
    final emitter = DartEmitter(Allocator.simplePrefixing());
    try {
      return DartFormatter().format('''
      // Ensure that the build script itself is not opted in to null safety,
      // instead of taking the language version from the current package.
      //
      // @dart=2.9
      //
      // ignore_for_file: directives_ordering

      ${library.accept(emitter)}''');
    } on FormatterException {
      _log.severe('Generated build script could not be parsed.\n'
          'This is likely caused by a misconfigured builder definition.');
      throw CannotBuildException();
    }
  }

  /// A method forwarding to `run`.
  Method _main() => Method((b) => b
    ..name = 'main'
    ..returns = TypeReference((b) => b
      ..symbol = 'Future'
      ..url = 'dart:async'
      ..types.add(refer('void')))
    ..modifier = MethodModifier.async
    ..requiredParameters.add(Parameter((b) => b
      ..name = 'args'
      ..type = TypeReference((b) => b
        ..symbol = 'List'
        ..types.add(refer('String')))))
    ..optionalParameters.add(Parameter((b) => b
      ..name = 'sendPort'
      ..type = refer('SendPort', 'dart:isolate')))
    ..body = Block.of([
      _options
          .runBuild(refer('args'), refer('_builders'))
          .awaited
          .assignVar('result')
          .statement,
      refer('sendPort')
          .nullSafeProperty('send')
          .call([refer('result')]).statement,
      refer('exitCode', 'dart:io').assign(refer('result')).statement,
    ]));

  /// Finds expressions to create all the `BuilderApplication` instances that
  /// should be applied packages in the build.
  ///
  /// Adds `apply` expressions based on the BuildefDefinitions from any package
  /// which has a `build.yaml`.
  Future<Iterable<Expression>> _findBuilderApplications() async {
    final packageGraph = await _options.packageGraph();
    final orderedPackages = stronglyConnectedComponents<PackageNode>(
      [packageGraph.root],
      (node) => node.dependencies,
      equals: (a, b) => a.name == b.name,
      hashCode: (n) => n.name.hashCode,
    ).expand((c) => c);
    final buildConfigOverrides = await _options.findConfigOverrides(
        packageGraph, FileBasedAssetReader(packageGraph));
    Future<BuildConfig> _packageBuildConfig(PackageNode package) async {
      if (buildConfigOverrides.containsKey(package.name)) {
        return buildConfigOverrides[package.name];
      }
      try {
        return await BuildConfig.fromBuildConfigDir(package.name,
            package.dependencies.map((n) => n.name), package.path);
      } on ArgumentError catch (_) {
        // During the build an error will be logged.
        return BuildConfig.useDefault(
            package.name, package.dependencies.map((n) => n.name));
      }
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

    final postProcessBuilderDefinitions = orderedConfigs
        .expand((c) => c.postProcessBuilderDefinitions.values)
        .where(_isValidDefinition);

    return [
      for (var builder in orderedBuilders) _applyBuilder(builder),
      for (var builder in postProcessBuilderDefinitions)
        _applyPostProcessBuilder(builder)
    ];
  }
}

/// An expression calling `apply` with appropriate setup for a Builder.
Expression _applyBuilder(BuilderDefinition definition) {
  final namedArgs = {
    if (definition.isOptional) 'isOptional': literalTrue,
    if (definition.buildTo == BuildTo.cache)
      'hideOutput': literalTrue
    else
      'hideOutput': literalFalse,
    if (!identical(definition.defaults?.generateFor, InputSet.anything))
      'defaultGenerateFor':
          refer('InputSet', 'package:build_config/build_config.dart')
              .constInstance([], {
        if (definition.defaults.generateFor.include != null)
          'include': _rawStringList(definition.defaults.generateFor.include),
        if (definition.defaults.generateFor.exclude != null)
          'exclude': _rawStringList(definition.defaults.generateFor.exclude),
      }),
    if (definition.defaults?.options?.isNotEmpty ?? false)
      'defaultOptions': _constructBuilderOptions(definition.defaults.options),
    if (definition.defaults?.devOptions?.isNotEmpty ?? false)
      'defaultDevOptions':
          _constructBuilderOptions(definition.defaults.devOptions),
    if (definition.defaults?.releaseOptions?.isNotEmpty ?? false)
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
    if (!identical(definition.defaults?.generateFor, InputSet.anything))
      'defaultGenerateFor':
          refer('InputSet', 'package:build_config/build_config.dart')
              .constInstance([], {
        if (definition.defaults.generateFor.include != null)
          'include': _rawStringList(definition.defaults.generateFor.include),
        if (definition.defaults.generateFor.exclude != null)
          'exclude': _rawStringList(definition.defaults.generateFor.exclude),
      }),
    if (definition.defaults?.options?.isNotEmpty ?? false)
      'defaultOptions': _constructBuilderOptions(definition.defaults.options),
    if (definition.defaults?.devOptions?.isNotEmpty ?? false)
      'defaultDevOptions':
          _constructBuilderOptions(definition.defaults.devOptions),
    if (definition.defaults?.releaseOptions?.isNotEmpty ?? false)
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

Expression _rawStringList(List<String> strings) => literalConstList(
    [for (var string in strings) literalString(string, raw: true)]);

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
  throw ArgumentError('Unhandled AutoApply type: ${definition.autoApply}');
}

/// An expression creating a [BuilderOptions] from a json string.
Expression _constructBuilderOptions(Map<String, dynamic> options) =>
    refer('BuilderOptions', 'package:build/build.dart')
        .newInstance([literalMap(options)]);
