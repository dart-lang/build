// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../package_builder/package_builder.dart';
import 'input_set.dart';

/// A "phase" in the build graph, which represents running a [builder] on a
/// specific [package].
///
/// See the [BuildAction] and [PackageBuildAction] implementations.
abstract class BuildActionBase<T> {
  String get package;

  T get builder;
}

/// The default type of [BuildActionBase], takes a normal [Builder] and an
/// [InputSet] of primary inputs to run on.
class BuildAction implements BuildActionBase<Builder> {
  @override
  final Builder builder;

  @override
  String get package => inputSet.package;

  final InputSet inputSet;

  BuildAction(this.builder, String package,
      {List<String> inputs = const ['**'], List<String> excludes = const []})
      : inputSet = new InputSet(package, inputs, excludes: excludes);

  @override
  String toString() => '$builder on $inputSet';
}

/// A special type of [BuildActionBase] which takes a [PackageBuilder] instead
/// of a normal [Builder], and runs a single time on [package] instead of once
/// per input file.
class PackageBuildAction implements BuildActionBase<PackageBuilder> {
  @override
  final PackageBuilder builder;

  @override
  final String package;

  PackageBuildAction(this.builder, this.package);
}
