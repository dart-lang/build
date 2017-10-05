// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../package_builder/package_builder.dart';
import 'input_set.dart';

/// A "phase" in the build graph, which represents running a [builder] on a
/// specific [package].
abstract class BuildAction {
  String get package;

  /// Creates an [AssetBuildAction] for a normal [Builder].
  ///
  /// Runs [builder] on [package] with [inputs] as primary inputs, excluding
  /// [excludes]. Glob syntax is supported for both [inputs] and [excludes].
  factory BuildAction(Builder builder, String package,
      {List<String> inputs = const ['**'], List<String> excludes = const []}) {
    var inputSet = new InputSet(package, inputs, excludes: excludes);
    return new AssetBuildAction._(builder, inputSet);
  }
}

/// The default type of [BuildAction], create one using the normal
/// [BuildAction] constructor.
class AssetBuildAction implements BuildAction {
  final Builder builder;

  @override
  String get package => inputSet.package;

  final InputSet inputSet;

  AssetBuildAction._(this.builder, this.inputSet);

  @override
  String toString() => '$builder on $inputSet';
}

/// A special type of [BuildAction] which takes a [PackageBuilder] instead of
/// a normal [Builder], and runs a single time on [package] instead of once per
/// input file.
class PackageBuildAction implements BuildAction {
  final PackageBuilder builder;

  @override
  final String package;

  PackageBuildAction(this.builder, this.package);
}
