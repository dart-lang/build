// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_config/build_config.dart';
import 'package:graphs/graphs.dart';

/// Put [builders] into an order such that any builder which specifies
/// [BuilderDefinition.requiredInputs] will come after any builder which
/// produces a desired output.
///
/// All builders which don't specify required inputs will come first, followed
/// by the builders with required inputs. If there is a cycle in required inputs
/// this will throw.
Iterable<BuilderDefinition> findBuilderOrder(
    Iterable<BuilderDefinition> builders) {
  final result = <BuilderDefinition>[];
  result.addAll(builders.where((b) => b.requiredInputs.isEmpty));
  final toOrder = builders.where((b) => b.requiredInputs.isNotEmpty);
  result.addAll(_findOrder(toOrder));
  return result;
}

List<BuilderDefinition> _findOrder(Iterable<BuilderDefinition> builders) {
  Iterable<BuilderDefinition> dependencies(BuilderDefinition parent) =>
      builders.where((child) => _hasInputDependency(parent, child));
  var components = stronglyConnectedComponents<String, BuilderDefinition>(
      builders, _builderKey, dependencies);
  return components.map((component) {
    if (component.length > 1) {
      throw new ArgumentError('Required input cycle for ${component.toList()}');
    }
    return component.single;
  }).toList();
}

/// Whether [parent] has a `required_input` that wants to read outputs produced
/// by [child].
bool _hasInputDependency(BuilderDefinition parent, BuilderDefinition child) {
  final childOutputs = child.buildExtensions.values.expand((v) => v).toSet();
  return parent.requiredInputs
      .any((input) => childOutputs.any((output) => output.endsWith(input)));
}

String _builderKey(BuilderDefinition b) => '${b.package}|${b.name}';
