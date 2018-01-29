// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';
import 'package:test/test.dart';

import 'package:build_runner/src/package_graph/apply_builders.dart';
import 'package:build_runner/src/package_graph/target_graph.dart';

import '../common/package_graphs.dart';

void main() {
  group('apply_builders.createBuildActions', () {
    test('builderConfigOverrides overrides builder config globally', () async {
      var packageGraph = buildPackageGraph({
        rootPackage('a'): ['b'],
        package('b'): []
      });
      var targetGraph = await TargetGraph.forPackageGraph(packageGraph);
      var builderApplications = [
        apply('b|cool_builder', [(options) => new CoolBuilder(options)],
            toAllPackages())
      ];
      var actions = await createBuildActions(targetGraph, builderApplications, {
        'b|cool_builder': {'option_a': 'a', 'option_c': 'c'},
      });
      for (var action in actions) {
        expect((action.builder as CoolBuilder).optionA, equals('a'));
        expect((action.builder as CoolBuilder).optionB, equals('defaultB'));
        expect((action.builder as CoolBuilder).optionC, equals('c'));
      }
    });
  });
}

class CoolBuilder extends Builder {
  final String optionA;
  final String optionB;
  final String optionC;

  CoolBuilder(BuilderOptions options)
      : optionA = options.config['option_a'] as String ?? 'defaultA',
        optionB = options.config['option_b'] as String ?? 'defaultB',
        optionC = options.config['option_c'] as String ?? 'defaultC';

  @override
  final buildExtensions = {
    '.txt': ['.out'],
  };

  @override
  Future build(BuildStep buildStep) async => throw new UnimplementedError();
}
