// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';

import 'target_graph.dart';

/// Triggers per builder.
///
/// A builder opts in to using triggers by setting the option
/// `run_only_if_triggered` to `true`. Then, it only runs if a trigger fires.
/// Triggers are quick to evaluate, so this allows build steps to be skipped
/// quickly without resolving source.
///
/// Packages can set builder options per target, and triggers are accumulated
/// across all packages in the build. This allows builders to set reasonable
/// default heuristics while also allowing individual codebases to fully tune
/// the heuristics, including disabling them to always just run.
class BuildTriggers {
  final BuiltMap<String, BuiltSet<BuildTrigger>> triggers;

  BuildTriggers({required this.triggers});

  Iterable<BuildTrigger>? operator [](String builderName) =>
      triggers[builderName];

  // TODO(davidmorgan): fix.
  Digest get digest => md5.convert(utf8.encode(triggers.toString()));

  /// Parses [triggers], or throws a descriptive exception on failure.
  ///
  /// On failure, [packageName] will be mentioned as the problem package.
  ///
  /// [triggers] is an `Object` read directly from yaml, to be valid it should
  /// be a list of strings that parse with [BuildTrigger.tryParse].
  static Iterable<BuildTrigger> parseList({
    required Object triggers,
    required String packageName,
  }) {
    if (triggers is! List<Object?>) {
      throw BuildConfigParseException(
        packageName,
        'Invalid `triggers`, should be a list of triggers: $triggers',
      );
    }
    final result = <BuildTrigger>[];
    for (final triggerString in triggers) {
      BuildTrigger? trigger;
      if (triggerString is String) {
        trigger = BuildTrigger.tryParse(triggerString);
      }
      if (trigger == null) {
        throw BuildConfigParseException(
          packageName,
          'Invalid trigger: `$triggerString`',
        );
      }
      result.add(trigger);
    }
    return result;
  }
}

/// A build trigger: a heuristic that possibly skips running a build step based
/// on the primary input source.
abstract class BuildTrigger {
  /// Parses a trigger, returning `null` on failure.
  ///
  /// The only supported trigger is [ImportBuildTrigger].
  static BuildTrigger? tryParse(String trigger) {
    if (trigger.startsWith('import ')) {
      trigger = trigger.substring('import '.length);
      return ImportBuildTrigger(trigger);
    }
    return null;
  }

  bool triggersOnPrimaryInput(String source);
}

/// A build trigger that checks for a direct import.
class ImportBuildTrigger implements BuildTrigger {
  final String import;

  // TODO(davidmorgan): more parsing / checking, test coverage.
  ImportBuildTrigger(this.import);

  @override
  bool triggersOnPrimaryInput(String source) {
    // TODO(davidmorgan): smarter checking.
    return source.contains(import);
  }

  // Take care with `toString`, it's used for the digest to check if triggers
  // have changed.
  @override
  String toString() => 'import $import';
}
