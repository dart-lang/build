// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'phase.dart';

abstract class FatalBuildException implements Exception {
  const FatalBuildException();
}

class InvalidBuildPhaseException extends FatalBuildException {
  final String _reason;

  InvalidBuildPhaseException.nonRootPackage(InBuildPhase phase, String root)
      : _reason = 'A build phase ($phase) is attempting to operate on '
            'package "${phase.package}", but the build script is '
            'located in package "$root". It\'s not valid to attempt to '
            'generate files for another package unless the BuilderApplication'
            'specified "hideOutput".'
            '\n\n'
            'Did you mean to write:\n'
            '  new BuilderApplication(..., toRoot())\n'
            'or\n'
            '  new BuilderApplication(..., hideOutput: true)\n'
            '... instead?';
  @override
  String toString() => 'InvalidBuildPhaseException: $_reason';
}

/// Indicates that the build cannot be attempted.
///
/// Before throwing this exception a user actionable message should be logged.
class CannotBuildException implements Exception {
  const CannotBuildException();
}
