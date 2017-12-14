// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build_config/build_config.dart';
import 'package:build_runner/build_runner.dart';
import 'package:code_builder/code_builder.dart' hide File;
import 'package:dart_style/dart_style.dart';
import 'package:graphs/graphs.dart';
import 'package:logging/logging.dart';

import '../logging/logging.dart';
import '../util/constants.dart';
import 'builder_ordering.dart';

const scriptLocation = '$entryPointDir/build.dart';

Future<Null> ensureBuildScript() async {
  var log = new Logger('ensureBuildScript');
  var scriptFile = new File(scriptLocation);
  scriptFile.createSync(recursive: true);
  await logTimedAsync(log, 'Generating build script',
      () async => scriptFile.writeAsString(await _generateBuildScript()));
}

Future<String> _generateBuildScript() async {
  final builders = await _findBuilderApplications();
  final library = new Library((b) => b.body.addAll(
      [literalList(builders).assignFinal('_builders').statement, _main()]));
  final emitter = new DartEmitter(new Allocator.simplePrefixing());
  return new DartFormatter().format('${library.accept(emitter)}');
}

/// Finds expressions to create all the [BuilderApplication] instances that
/// should be applied packages in the build.
///
/// - Add any builders which specify `auto_apply: True` in their `build.yaml`
/// - Add the DDC builders which apply to all packages
/// - Add the DDC bootstrap builder to the root package
Future<Iterable<Expression>> _findBuilderApplications() async {
  final builderApplications = <Expression>[];
  final packageGraph = new PackageGraph.forThisPackage();
  final orderedPackages = stronglyConnectedComponents<String, PackageNode>(
          [packageGraph.root], (node) => node.name, (node) => node.dependencies)
      .expand((c) => c);
  final builderDefinitions =
      (await Future.wait(orderedPackages.map(_packageBuildConfig)))
          .expand((c) => c.builderDefinitions.values);

  final orderedBuilders = findBuilderOrder(builderDefinitions);
  builderApplications.addAll(orderedBuilders.map(_applyBuilder));
  var ddcBootstrap = builderDefinitions.firstWhere(
      (b) => b.package == 'build_compilers' && b.name == 'ddc_bootstrap');
  // TODO - should this be configurable?
  builderApplications.add(_applyBuilderWithFilter(ddcBootstrap,
      refer('toRoot', 'package:build_runner/build_runner.dart').call([]),
      inputs: ['web/**.dart', 'test/**.browser_test.dart']));
  return builderApplications;
}

/// A method forwarding to `run`.
Method _main() => new Method((b) => b
  ..name = 'main'
  ..lambda = true
  ..requiredParameters.add(new Parameter((b) => b
    ..name = 'args'
    ..type = new TypeReference((b) => b
      ..symbol = 'List'
      ..types.add(refer('String')))))
  ..body = refer('run', 'package:build_runner/build_runner.dart')
      .call([refer('args'), refer('_builders')]).code);

Future<BuildConfig> _packageBuildConfig(PackageNode package) async =>
    BuildConfig.fromPackageDir(
        await Pubspec.fromPackageDir(package.path), package.path);

/// An expression calling `apply` with appropriate setup for a Builder.
Expression _applyBuilder(BuilderDefinition definition) =>
    _applyBuilderWithFilter(definition, _findToExpression(definition));

Expression _applyBuilderWithFilter(
    BuilderDefinition definition, Expression toExpression,
    {List<String> inputs}) {
  final namedArgs = <String, Expression>{};
  if (inputs != null) {
    namedArgs['inputs'] = literalList(inputs);
  }
  if (definition.isOptional) {
    namedArgs['isOptional'] = literalTrue;
  }
  if (definition.buildTo == BuildTo.cache) {
    namedArgs['hideOutput'] = literalTrue;
  }
  return refer('apply', 'package:build_runner/build_runner.dart').call([
    literalString(definition.package),
    literalString(definition.name),
    literalList(definition.builderFactories
        .map((f) => refer(f, definition.import))
        .toList()),
    toExpression,
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
