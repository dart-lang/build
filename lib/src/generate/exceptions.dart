// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
class ConcurrentBuildException implements Exception {
  const ConcurrentBuildException();

  @override
  String toString() =>
      'ConcurrentBuildException: Only one build may be running at a time.';
}

class BuildScriptUpdatedException implements Exception {
  const BuildScriptUpdatedException();

  @override
  String toString() => 'Build abandoned due to change to the build script or '
      'one of its dependencies. This could be caused by a pub get or any other '
      'change. Please restart the build script.';
}
