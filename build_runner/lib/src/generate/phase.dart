// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../package_builder/package_builder.dart';
import 'input_set.dart';

/// A "phase" in the build graph, which represents running a builder on a
/// specific [package].
///
/// If [isOptional] is `true` then this action runs lazily when another action
/// tries to read one of its outputs. If no other action attempts to read the
/// outputs of an optional action, then its outputs will never be created.
///
/// See the [BuildAction] and [PackageBuildAction] implementations.
abstract class BuildAction {
  String get package;

  final bool isOptional;

  BuildAction._(bool isOptional) : this.isOptional = isOptional ?? false;

  factory BuildAction(Builder builder, String package,
      {List<String> inputs = const ['**'],
      List<String> excludes = const [],
      bool isOptional}) {
    var inputSet = new InputSet(package, inputs, excludes: excludes);
    return new AssetBuildAction._(builder, inputSet, isOptional: isOptional);
  }
}

/// The default type of [BuildAction], takes a normal [Builder] and an
/// [InputSet] of primary inputs to run on.
class AssetBuildAction extends BuildAction {
  final Builder builder;

  final InputSet inputSet;

  @override
  String get package => inputSet.package;

  AssetBuildAction._(this.builder, this.inputSet, {bool isOptional})
      : super._(isOptional);

  @override
  String toString() => '$builder on $inputSet';
}

/// A special type of [BuildAction] which takes a [PackageBuilder] instead
/// of a normal [Builder], and runs a single time on [package] instead of once
/// per input file.
class PackageBuildAction extends BuildAction {
  final PackageBuilder builder;

  @override
  final String package;

  PackageBuildAction(this.builder, this.package, {bool isOptional})
      : super._(isOptional);
}
