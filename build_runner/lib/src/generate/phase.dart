// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:collection/collection.dart';

import 'input_set.dart';

/// A "phase" in the build graph, which represents running a [Builder] on a
/// specific [package].
class BuildAction implements InputSet {
  final String package;
  final Builder builder;
  final InputSet _inputSet;

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

  BuildAction._(this.package, this.builder, this._inputSet, this.builderOptions,
      {bool isOptional, bool hideOutput})
      : this.isOptional = isOptional ?? false,
        this.hideOutput = hideOutput ?? false;

  /// Creates an [BuildAction] for a normal [Builder].
  ///
  /// Runs [builder] on [package] with [include] as primary inputs, excluding
  /// [exclude]. Glob syntax is supported for both [include] and [exclude].
  ///
  /// [isOptional] specifies that a Builder may not be run unless some other
  /// Builder in a later phase attempts to read one of the potential outputs.
  ///
  /// [hideOutput] specifies that the generated asses should be placed in the
  /// build cache rather than the source tree.
  factory BuildAction(
    Builder builder,
    String package, {
    Iterable<String> include,
    Iterable<String> exclude,
    BuilderOptions builderOptions,
    bool isOptional,
    bool hideOutput,
  }) {
    var inputSet = new InputSet(include: include, exclude: exclude);
    builderOptions ??= const BuilderOptions(const {});
    return new BuildAction._(package, builder, inputSet, builderOptions,
        isOptional: isOptional, hideOutput: hideOutput);
  }

  @override
  bool matches(AssetId id) => id.package == package && _inputSet.matches(id);

  @override
  String toString() {
    final settings = <String>[];
    if (isOptional) settings.add('optional');
    if (hideOutput) settings.add('hidden');
    var result = '$builder on $_inputSet';
    if (settings.isNotEmpty) result += ' $settings';
    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildAction &&
          other.package == package &&
          other._inputSet == _inputSet &&
          other.isOptional == isOptional &&
          other.hideOutput == hideOutput &&
          _deepEquals.equals(
              other.builderOptions.config, builderOptions.config);

  @override
  int get hashCode => _deepEquals.hash(
      [package, _inputSet, isOptional, hideOutput, builderOptions.config]);
}

final _deepEquals = const DeepCollectionEquality();
