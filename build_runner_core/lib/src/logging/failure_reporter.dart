// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

import '../asset_graph/node.dart';

/// A tracker for the errors which have already been reported during the current
/// build.
///
/// Errors that occur due to actions that are run within this build will be
/// reported directly as they happen. When an action is skipped and remains a
/// failure the error will not have been reported by the time we check wether
/// the build is failed.
///
/// The lifetime of this class should be a single build.
class FailureReporter {
  /// Removes all stored errors from previous builds.
  ///
  /// This should be called any time the build phases change since the naming
  /// scheme is dependent on the build phases.
  static Future<void> cleanErrorCache() async {
    // TODO: Remove all error files
  }

  /// Remove the stored error for [output] if it existed.
  ///
  /// This should be called anytime an action is being run that could produce
  /// [output].
  static Future<void> clean(GeneratedAssetNode output) async {
    // TODO: Remove the specific file associated with this action
  }

  /// A set of Strings which uniquely identify a particular build action and
  /// it's primary input.
  final _reportedActions = new Set<String>();

  /// Indicate that a failure reason for the build step which would produce
  /// [output] and all other outputs from the same build step has been printed.
  void markReported(GeneratedAssetNode output, Iterable<ErrorReport> errors) {
    _reportedActions.add(_actionKey(output));
    // TODO: Store the errors
  }

  /// Indicate that the build steps which would produce [outputs] are failing
  /// due to a dependency and being skipped so no actuall error will be
  /// produced.
  Future<void> markSkipped(Iterable<GeneratedAssetNode> outputs) async {
    // TODO: mark these as "reported" and remove any cached errors.
  }

  /// Print stored errors for any build steps which would output nodes in
  /// [failingNodes] which haven't already been reported.
  void reportErrors(Iterable<GeneratedAssetNode> failingNodes, Logger logger) {
    for (final failure in failingNodes) {
      final key = _actionKey(failure);
      if (_reportedActions.contains(key)) continue;
      // TODO: Log the error from the stored file.
      _reportedActions.add(key);
    }
  }
}

/// Matches the call to [Logger.severe] except the [message] and [error] are
/// eagerly converted to String.
class ErrorReport {
  final String message;
  final String error;
  final StackTrace stackTrace;
  ErrorReport(this.message, this.error, this.stackTrace);
}

String _actionKey(GeneratedAssetNode node) =>
    '${node.builderOptionsId} on ${node.primaryInput}';
