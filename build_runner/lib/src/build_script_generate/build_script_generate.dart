// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:build_config/build_config.dart';
import 'package:build_runner/build_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';

import '../logging/logging.dart';
import '../util/constants.dart';
import 'builder_ordering.dart';
import 'types.dart' as types;

const scriptLocation = '$entryPointDir/build.dart';

Future<Null> ensureBuildScript() async {
  var log = new Logger('ensureBuildScript');
  var scriptFile = new io.File(scriptLocation);
  // TODO - how can we invalidate this?
  //if (scriptFile.existsSync()) return;
  scriptFile.createSync(recursive: true);
  await logTimedAsync(log, 'Generating build script',
      () async => scriptFile.writeAsString(await _generateBuildScript()));
}

Future<String> _generateBuildScript() async {
  final builders = await _findBuilderApplications();
  final library =
      new File((b) => b.body.addAll([_findBuildActions(builders), _main()]));
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
  final builderDefinitions =
      (await Future.wait(packageGraph.orderedPackages.map(_packageBuildConfig)))
          .expand((c) => c.builderDefinitions.values);

  final orderedBuilders = findBuilderOrder(builderDefinitions);
  builderApplications
      .addAll(orderedBuilders.map((b) => _applyBuilder(b, packageGraph)));
  var ddcBootstrap = builderDefinitions.firstWhere(
      (b) => b.package == 'build_compilers' && b.name == 'ddc_bootstrap');
  // TODO - should this be configurable?
  builderApplications.add(_applyBuilderWithFilter(
      ddcBootstrap,
      refer('toPackage', 'package:build_runner/build_runner.dart')
          .call([literalString(packageGraph.root.name)]),
      inputs: ['web/**.dart', 'test/**.browser_test.dart']));
  return builderApplications;
}

/// A method which creates a list literal containing [builderApplications] and
/// calls `createBuildActions` to resolve them.
Method _findBuildActions(Iterable<Expression> builderApplications) =>
    new Method((b) => b
      ..name = '_buildActions'
      ..requiredParameters.add(new Parameter((b) => b
        ..name = 'packageGraph'
        ..type = types.packageGraph))
      ..returns = types.buildActions
      ..body = new Block.of([
        // TODO - Pass actual arguments
        literalList([], refer('String')).assignVar('args').statement,
        literalList(builderApplications.toList())
            .assignVar('builders')
            .statement,
        refer('createBuildActions', 'package:build_runner/build_runner.dart')
            .call([refer('packageGraph'), refer('builders')],
                {'args': refer('args')})
            .returned
            .statement,
      ]));

Method _main() => new Method((b) => b
  ..name = 'main'
  ..modifier = MethodModifier.async
  ..body = new Block.of([
    refer('_buildActions')
        .call([types.packageGraph.newInstanceNamed('forThisPackage', [])])
        .assignVar('actions')
        .statement,
    refer('watch', 'package:build_runner/build_runner.dart')
        .call([refer('actions')], {'writeToCache': literalTrue})
        .awaited
        .assignVar('handler')
        .statement,
    refer('serve', 'package:shelf/shelf_io.dart')
        .call([
          refer('handler').property('handlerFor').call([literalString('web')]),
          literalString('localhost'),
          literal(8000)
        ])
        .awaited
        .assignVar('server')
        .statement,
    refer('handler')
        .property('buildResults')
        .property('drain')
        .call([])
        .awaited
        .statement,
    refer('server').property('close').call([]).awaited.statement
  ]));

Future<BuildConfig> _packageBuildConfig(PackageNode package) async =>
    BuildConfig.fromPackageDir(
        await Pubspec.fromPackageDir(package.path), package.path);

/// An expression calling `apply` with appropriate setup for a Builder.
Expression _applyBuilder(
        BuilderDefinition definition, PackageGraph packageGraph) =>
    _applyBuilderWithFilter(
        definition, _findToExpression(definition, packageGraph));

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
  return refer('apply', 'package:build_runner/build_runner.dart').call([
    literalString(definition.package),
    literalString(definition.name),
    literalList(definition.builderFactories
        .map((f) => refer(f, definition.import))
        .toList()),
    toExpression,
  ], namedArgs);
}

// TODO - graph argument should be removed once `toRoot()` is a supported
// PackageFilter
Expression _findToExpression(
    BuilderDefinition definition, PackageGraph packageGraph) {
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
      return refer('toPackage', 'package:build_runner/build_runner.dart')
          .call([literalString(packageGraph.root.name)]);
  }
  throw 'Unreachable';
}
