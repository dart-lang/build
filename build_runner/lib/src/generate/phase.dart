// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../builder/post_process_builder.dart';
import 'input_matcher.dart';

/// A "phase" in the build graph, which represents running a some builders on a
/// [package].
abstract class BuildAction {
  /// Either a [Builder] or a [PostProcessBuilder].
  dynamic get builder;

  String get package;
  InputMatcher get targetSources;
  InputMatcher get generateFor;

  /// Whether to run lazily when an output is read.
  ///
  /// An optional build action will only run if one of its outputs is read by
  /// a later [Builder], or is used as a primary input to a later [Builder].
  ///
  /// If no build actions read the output of an optional action, then it will
  /// never run.
  bool get isOptional;

  BuilderOptions get builderOptions;

  /// Whether generated assets should be placed in the build cache.
  ///
  /// When this is `false` the Builder may not run on any [package] other than
  /// the root.
  bool get hideOutput;

  @override
  String toString() {
    final settings = <String>[];
    if (isOptional) settings.add('optional');
    if (hideOutput) settings.add('hidden');
    var result = '${builder.runtimeType} on $targetSources in $package';
    if (settings.isNotEmpty) result += ' $settings';
    return result;
  }

  /// The identity of this action in terms of a build graph. If the identity of
  /// any action changes the build will be invalidated.
  ///
  /// This takes into account everything except for the [builderOptions], which
  /// are tracked separately via a `BuilderOptionsNode` which supports more fine
  /// grained invalidation.
  int get identity => _deepEquals.hash([
        '${builder.runtimeType}',
        package,
        targetSources,
        generateFor,
        isOptional,
        hideOutput
      ]);
}

/// A [BuildAction] that uses a [Builder] to generate files.
class BuilderBuildAction extends BuildAction {
  @override
  final Builder builder;

  @override
  final String package;
  @override
  final InputMatcher targetSources;
  @override
  final InputMatcher generateFor;
  @override
  final bool isOptional;
  @override
  final BuilderOptions builderOptions;
  @override
  final bool hideOutput;

  BuilderBuildAction._(this.package, this.builder, this.builderOptions,
      {@required this.targetSources,
      @required this.generateFor,
      bool isOptional,
      bool hideOutput})
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
  factory BuilderBuildAction(
    Builder builder,
    String package, {
    InputSet targetSources,
    InputSet generateFor,
    BuilderOptions builderOptions,
    bool isOptional,
    bool hideOutput,
  }) {
    var targetSourceMatcher =
        new InputMatcher(targetSources ?? const InputSet());
    var generateFormatcher = new InputMatcher(generateFor ?? const InputSet());
    builderOptions ??= const BuilderOptions(const {});
    return new BuilderBuildAction._(package, builder, builderOptions,
        targetSources: targetSourceMatcher,
        generateFor: generateFormatcher,
        isOptional: isOptional,
        hideOutput: hideOutput);
  }
}

/// A [BuildAction] that uses a [PostProcessBuilder] to generate files.
class PostProcessBuildAction extends BuildAction {
  @override
  final PostProcessBuilder builder;
  @override
  bool get hideOutput => true;
  @override
  bool get isOptional => false;

  @override
  final BuilderOptions builderOptions;
  @override
  final InputMatcher generateFor;
  @override
  final String package;
  @override
  final InputMatcher targetSources;

  PostProcessBuildAction._(this.package, this.builder, this.builderOptions,
      {@required this.targetSources, @required this.generateFor});

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
  factory PostProcessBuildAction(
    PostProcessBuilder builder,
    String package, {
    InputSet targetSources,
    InputSet generateFor,
    BuilderOptions builderOptions,
  }) {
    var targetSourceMatcher =
        new InputMatcher(targetSources ?? const InputSet());
    var generateFormatcher = new InputMatcher(generateFor ?? const InputSet());
    builderOptions ??= const BuilderOptions(const {});
    return new PostProcessBuildAction._(package, builder, builderOptions,
        targetSources: targetSourceMatcher, generateFor: generateFormatcher);
  }

  @override
  String toString() {
    final settings = <String>[];
    if (isOptional) settings.add('optional');
    if (hideOutput) settings.add('hidden');
    var result = '${builder.runtimeType} on $targetSources in $package';
    if (settings.isNotEmpty) result += ' $settings';
    return result;
  }

  /// This takes into account everything except for the [builderOptions], which
  /// are tracked separately via a `BuilderOptionsNode` which supports more fine
  /// grained invalidation.
  int get identity => _deepEquals.hash([
        '${builder.runtimeType}',
        package,
        targetSources,
        generateFor,
        isOptional,
        hideOutput
      ]);
}

final _deepEquals = const DeepCollectionEquality();
