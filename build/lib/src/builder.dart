// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'build_step.dart';

/// A factory for a builder in the `build_runner` build.
///
/// To write your own builder, create a top-level function that is a
/// `BuilderFactory`: it accepts a `BuilderOptions` and returns an instance of
/// your `Builder`. Then, create a `build.yaml` at the root of the package
/// telling `build_runner` about the factory.
///
/// For example:
///
/// ```yaml
/// builders:
///   my_builder:
///     import: "package:my_package/builder.dart"
///     builder_factories: ["myBuilder"]
///     build_extensions: {".dart": [".my_package.dart"]}
///     auto_apply: dependents
/// ```
///
/// This `build.yaml` file says there is a `BuilderFactory` in
/// `package:my_package/builder.dart` called `myBuilder`.
/// `auto_apply: dependents` tells `build_runner` to run the builder on all
/// packages that depend on `my_package`.
///
/// The `build_extensions` should if possible match the value returned by
/// [Builder.buildExtensions], because the `buildExtensions` in the `build.yaml`
/// is what decides the order in which builders will run. However, a builder
/// can change its `buildExtensions` based on options. In this case the builder
/// order is determined based on `build.yaml` but the runtime behavior uses
/// the runtime `buildExtensions`.
typedef BuilderFactory = Builder Function(BuilderOptions options);

/// Options that are passed to a [BuilderFactory] to instantiate a [Builder].
///
/// Based on these options the [Builder] can change any aspect of its behavior:
/// its [Builder.buildExtensions], which files it reads, which files it outputs
/// and/or the contents of those files.
///
/// The options come from three places: a builder's own `build.yaml` file can
/// define defaults; the package the builder is running in can set options; and
/// options can be passed in on the `build_runner` command line using
/// `--define`.
class BuilderOptions {
  /// A configuration with no options set.
  static const empty = BuilderOptions({});

  /// A configuration with [isRoot] set to `true` and no options set.
  static const forRoot = BuilderOptions({}, isRoot: true);

  /// The configuration to apply to a given usage of a [Builder].
  ///
  /// Possible values are primitives available in JSON and yaml: `String`,
  /// `num`, `bool` or `List` or `Map` of these types.
  final Map<String, dynamic> config;

  /// Whether this builder is running on the root package.
  final bool isRoot;

  const BuilderOptions(this.config, {this.isRoot = false});

  /// Returns a new set of options with keys from [other] overriding options in
  /// this instance.
  ///
  /// Config values are overridden at a per-key granularity, there is no
  /// value-level merging.
  ///
  /// If [other] is `null` then this instance is returned directly.
  ///
  /// The `isRoot` value is overridden to the value from [other].
  BuilderOptions overrideWith(BuilderOptions? other) {
    // ignore: avoid_returning_this
    if (other == null) return this;
    return BuilderOptions(
      {}
        ..addAll(config)
        ..addAll(other.config),
      isRoot: other.isRoot,
    );
  }
}

/// A builder in the `build_runner` build.
///
/// Each builder specifies which files it matches as [buildExtensions]; matching
/// files are called "primary inputs".
///
/// During the build `build_runner` runs the [build] method of each builder once
/// per primary input, with a [BuildStep] created for that input.
abstract class Builder {
  /// Generates the outputs for a given [BuildStep].
  FutureOr<void> build(BuildStep buildStep);

  /// Mapping from input file extension to output file extensions.
  ///
  /// All input sources matching any key in this map will be passed as a build
  /// step to this builder. Only files with the same basename and an extension
  /// from the values in this map are expected as outputs.
  ///
  /// - If an empty key exists, all inputs are considered matching.
  /// - An instance of a builder must always return the same configuration.
  ///   Typically, a builder will return a `const` map. Builders may also choose
  ///   extensions based on [BuilderOptions].
  /// - Most builders will use a single input extension and one or more output
  ///   extensions.
  ///
  /// TODO(davidmorgan): add examples.
  Map<String, List<String>> get buildExtensions;
}
