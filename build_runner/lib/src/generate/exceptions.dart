// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/generate/phase.dart';

import 'phase.dart';

abstract class FatalBuildException implements Exception {
  const FatalBuildException();
}

class UnexpectedExistingOutputsException extends FatalBuildException {
  final Set<AssetId> conflictingOutputs;

  const UnexpectedExistingOutputsException(this.conflictingOutputs);

  @override
  String toString() => 'UnexpectedExistingOutputsException: Either you opted '
      'not to delete existing files, or you are not running in interactive '
      'mode and did not specify `deleteFilesByDefault` as `true`.\n\n'
      'Found ${conflictingOutputs.length} outputs already on disk:\n\n'
      '${conflictingOutputs.join('\n')}\n';
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
