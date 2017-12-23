// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../package_graph/package_graph.dart';

String _createHash() => 

/// Returns a future that completes with a hash when [graph] could be locked.
///
/// This same hash is expected to be used with [clearLock] when the build
/// process is complete. Throws a `ConcurrentBuildException` if the lock could
/// not be created.
Future<String> createLock(PackageGraph graph) {

}

/// Returns a future that completes after clearing the lock file for [graph].
///
/// If [hash] is provided, throws a `ConcurrentBuildException` if it does not
/// match the lock file created, and the lock file is not cleared/removed.
Future<Null> clearLock(PackageGraph graph, {String hash}) {

}
