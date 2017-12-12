// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../package_builder/package_builder.dart';
import 'input_set.dart';

/// A "phase" in the build graph, which represents running a [Builder] on a
/// specific [package].
///
/// See the [BuildAction] and [PackageBuildAction] implementations.
abstract class BuildAction {
  String get package;

  /// Whether to run lazily when an output is read.
  ///
  /// An optional build action will only run if one of its outputs is read by
  /// a later [Builder], or is used as a primary input to a later [Builder].
  ///
  /// If no build actions read the output of an optional action, then it will
  /// never run.
  final bool isOptional;

  final BuilderOptions builderOptions;

  /// Whether generated assets should be placed in the build cache.
  ///
  /// When this is `false` the Builder may not run on any [package] other than
  /// the root.
  final bool hideOutput;

  BuildAction._(this.builderOptions, {bool isOptional, bool hideOutput})
      : this.isOptional = isOptional ?? false,
        this.hideOutput = hideOutput ?? false;

  /// Creates an [AssetBuildAction] for a normal [Builder].
  ///
  /// Runs [builder] on [package] with [inputs] as primary inputs, excluding
  /// [excludes]. Glob syntax is supported for both [inputs] and [excludes].
  ///
  /// [isOptional] specifies that a Builder may not be run unless some other
  /// Builder in a later phase attempts to read one of the potential outputs.
  ///
  /// [hideOutput] specifies that the generated asses should be placed in the
  /// build cache rather than the source tree.
  factory BuildAction(
    Builder builder,
    String package, {
    List<String> inputs,
    List<String> excludes,
    BuilderOptions builderOptions,
    bool isOptional,
    bool hideOutput,
  }) {
    var inputSet = new InputSet(package, inputs, excludes: excludes);
    builderOptions ??= const BuilderOptions(const {});
    return new AssetBuildAction._(builder, inputSet, builderOptions,
        isOptional: isOptional, hideOutput: hideOutput);
  }
}

/// The default type of [BuildAction], takes a normal [Builder] and an
/// [InputSet] of primary inputs to run on.
class AssetBuildAction extends BuildAction {
  final Builder builder;

  final InputSet inputSet;

  @override
  String get package => inputSet.package;

  AssetBuildAction._(this.builder, this.inputSet, BuilderOptions builderOptions,
      {bool isOptional, bool hideOutput})
      : super._(builderOptions, isOptional: isOptional, hideOutput: hideOutput);

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

  PackageBuildAction(this.builder, this.package,
      {BuilderOptions builderOptions, bool isOptional, bool hideOutput})
      : super._(builderOptions ?? const BuilderOptions(const {}),
            isOptional: isOptional, hideOutput: hideOutput);
}

// TODO - remove this once we are no longer using `writeToCache` argument
BuildAction hiddenAction(BuildAction action) {
  if (action is AssetBuildAction) {
    return new AssetBuildAction._(
        action.builder, action.inputSet, action.builderOptions,
        isOptional: action.isOptional, hideOutput: true);
  }
  if (action is PackageBuildAction) {
    return new PackageBuildAction(action.builder, action.package,
        builderOptions: action.builderOptions,
        isOptional: action.isOptional,
        hideOutput: true);
  }
  throw new ArgumentError('must be AssetBuildAction or PackageBuildAction');
}
