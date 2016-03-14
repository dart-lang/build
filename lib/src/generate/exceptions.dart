// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
class ConcurrentBuildException implements Exception {
  const ConcurrentBuildException();

  @override
  String toString() =>
      'ConcurrentBuildException: Only one build may be running at a time.';
}

class BuildScriptUpdatedException extends FatalBuildException {
  const BuildScriptUpdatedException();

  @override
  String toString() => 'BuildScriptUpdatedException: Build abandoned due to '
      'change to the build script or one of its dependencies. This could be '
      'caused by a pub get or any other change. Please restart the build '
      'script.';
}

class UnexpectedExistingOutputsException extends FatalBuildException {
  const UnexpectedExistingOutputsException();

  @override
  String toString() => 'UnexpectedExistingOutputsException: Either you opted '
      'not to delete existing files, or you are not running in interactive '
      'mode and did not specify `deleteFilesByDefault` as `true`.';
}

abstract class FatalBuildException implements Exception {
  const FatalBuildException();
}
