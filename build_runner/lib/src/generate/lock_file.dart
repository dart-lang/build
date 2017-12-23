// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../generate/exceptions.dart';
import '../package_graph/package_graph.dart';

/// Returns a simple string hash used to determine if a lock file is owned.
String _createHash() => md5
    .convert(pid.toString().codeUnits)
    .bytes
    .map((b) => b.toRadixString(16))
    .join('');

/// Returns a future that completes with a hash when [graph] could be locked.
///
/// This same hash is expected to be used with [clearLock] when the build
/// process is complete. Throws a `ConcurrentBuildException` if the lock could
/// not be created.
Future<String> createLock(PackageGraph graph, {String hash}) async {
  // For package graphs without a root (usually for testing), just succeed.
  hash ??= _createHash();
  if (graph?.root?.path == null) {
    return hash;
  }
  final path = p.join(graph.root.path, 'build.lock');
  final file = new File(path);
  if (await file.exists()) {
    throw new ConcurrentBuildException(file.absolute.path);
  }
  await file.writeAsString(hash);
  return hash;
}

/// Returns a future that completes after clearing the lock file for [graph].
Future<Null> clearLock(PackageGraph graph, {String hash}) async {
  // For package graphs without a root (usually for testing), just succeed.
  if (graph?.root?.path == null) {
    return;
  }
  final path = p.join(graph.root.path, 'build.lock');
  final file = new File(path);
  if (!await file.exists()) {
    return;
  }
  final input = await file.readAsString();
  hash ??= _createHash();
  if (hash != input) {
    throw new ConcurrentBuildException(file.absolute.path);
  }
  await file.delete();
}
