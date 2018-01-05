// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_config/build_config.dart';
import 'package:graphs/graphs.dart';

/// Put [builders] into an order such that any builder which specifies
/// [BuilderDefinition.requiredInputs] will come after any builder which
/// produces a desired output.
///
/// Builders will be put in the following order:
/// - Builders which write to the source tree and don't have required inputs.
/// - Builders which write to the source tree and have required inputs (these
/// inputs can only be also on disk)
/// - Builders which write to the build cache and don't have requried inputs.
/// - Builders which write to the build cache and have required inputs
Iterable<BuilderDefinition> findBuilderOrder(
    Iterable<BuilderDefinition> builders) {
  final result = <BuilderDefinition>[];

  result.addAll(builders
      .where((b) => b.buildTo == BuildTo.source && b.requiredInputs.isEmpty));

  final requiredInSource = builders
      .where((b) => b.buildTo == BuildTo.source && b.requiredInputs.isNotEmpty);
  result.addAll(_findOrder(requiredInSource));

  result.addAll(builders
      .where(((b) => b.buildTo == BuildTo.cache && b.requiredInputs.isEmpty)));

  final requiredInCache = builders
      .where((b) => b.buildTo == BuildTo.cache && b.requiredInputs.isNotEmpty);
  result.addAll(_findOrder(requiredInCache));

  return result;
}

List<BuilderDefinition> _findOrder(Iterable<BuilderDefinition> builders) {
  Iterable<BuilderDefinition> dependencies(BuilderDefinition parent) =>
      builders.where((child) => _hasInputDependency(parent, child));
  var components = stronglyConnectedComponents<String, BuilderDefinition>(
      builders, (b) => b.key, dependencies);
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
