// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:collection/collection.dart';

import 'input_matcher.dart';

/// A "phase" in the build graph, which represents running a [Builder] on a
/// specific [package].
class BuildAction implements InputMatcher {
  final String package;
  final Builder builder;
  final InputMatcher _inputs;

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

  BuildAction._(this.package, this.builder, this._inputs, this.builderOptions,
      {bool isOptional, bool hideOutput})
      : this.isOptional = isOptional ?? false,
        this.hideOutput = hideOutput ?? false;

  /// Creates an [BuildAction] for a normal [Builder].
  ///
  /// The build target is defined by [package] as well as [targetSources]. By
  /// default all sources in the target are used as primary inputs to the
  /// builder, but it can be further filtered with [generateFor].
  ///
  /// [isOptional] specifies that a Builder may not be run unless some other
  /// Builder in a later phase attempts to read one of the potential outputs.
  ///
  /// [hideOutput] specifies that the generated asses should be placed in the
  /// build cache rather than the source tree.
  factory BuildAction(
    Builder builder,
    String package, {
    InputSet targetSources,
    InputSet generateFor,
    BuilderOptions builderOptions,
    bool isOptional,
    bool hideOutput,
  }) {
    var inputs = new InputMatcher(targetSources ?? const InputSet());
    if (generateFor != null) {
      inputs = new InputMatcher.allOf([inputs, new InputMatcher(generateFor)]);
    }
    builderOptions ??= const BuilderOptions(const {});
    return new BuildAction._(package, builder, inputs, builderOptions,
        isOptional: isOptional, hideOutput: hideOutput);
  }

  @override
  bool matches(AssetId id) => id.package == package && _inputs.matches(id);

  @override
  String toString() {
    final settings = <String>[];
    if (isOptional) settings.add('optional');
    if (hideOutput) settings.add('hidden');
    var result = '$builder on $_inputs';
    if (settings.isNotEmpty) result += ' $settings';
    return result;
  }

  /// The identity of this action in terms of a build graph.
  ///
  /// This takes into account everything except for the [builderOptions], which
  /// are tracked separately via a `BuilderOptionsNode` which supports more fine
  /// grained invalidation.
  int get identity => _deepEquals.hash(
      ['${builder.runtimeType}', package, _inputs, isOptional, hideOutput]);
}

final _deepEquals = const DeepCollectionEquality();
