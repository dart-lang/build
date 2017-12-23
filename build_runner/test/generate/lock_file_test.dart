// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/generate/exceptions.dart';
import 'package:build_runner/src/generate/lock_file.dart';
import 'package:build_runner/src/package_graph/package_graph.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../common/descriptors.dart';

void main() {
  PackageGraph graph;

  setUp(() async {
    await d.dir('pkg', [
      d.dir('lib'),
      d.file('.packages', 'pkg:./lib/'),
      await pubspec('pkg'),
    ]).create();

    final root = new PackageNode('pkg', p.join(d.sandbox, 'pkg'), isRoot: true);
    graph = new PackageGraph.fromRoot(root);
    expect(graph.root.path, isNotNull);
  });

  test('should create a lock file', () async {
    // Start with no lock file.
    await d.dir('pkg', [
      d.nothing('build.lock'),
    ]).validate();

    // Create a lock file.
    await createLock(graph, hash: '1234');

    // Expect a lock file.
    await d.dir('pkg', [
      d.file('build.lock', '1234'),
    ]).validate();
  });

  test('should throw if a lock file already exists', () async {
    await d.dir('pkg', [
      d.file('build.lock', '1234'),
    ]).create();

    expect(createLock(graph), throwsConcurrentBuildException);
  });

  test('should remove a lock file', () async {
    await d.dir('pkg', [
      d.file('build.lock', '1234'),
    ]).create();

    await clearLock(graph, hash: '1234');

    await d.dir('pkg', [
      d.nothing('build.lock'),
    ]).validate();
  });

  test('should throw on removing a lock file with a wrong hash', () async {
    await d.dir('pkg', [
      d.file('build.lock', '1234'),
    ]).create();

    expect(clearLock(graph, hash: 'ABCD'), throwsConcurrentBuildException);

    await d.dir('pkg', [
      d.file('build.lock', '1234'),
    ]).validate();
  });
}

final throwsConcurrentBuildException =
    throwsA(const isInstanceOf<ConcurrentBuildException>());
