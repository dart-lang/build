// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'invalidation_tester.dart';

/// Checks for memory leaks.
///
/// Runs many incremental builds, prints the average increase in memory usage
/// per build.
///
/// Run using `tool/leak_check.sh`.
void main(List<String> arguments) async {
  final tester = InvalidationTester(testIsRunning: false);

  tester.sources(['a.1']);

  tester.builder(from: '.1', to: '.2')
    ..reads('.1')
    ..resolvesOther('a.1')
    ..writes('.2');

  await tester.build();
  await tester.build(change: 'a.1');

  // `.dart_tool/build_resolvers/sdk.sum` will be calculated and written if it
  // does not yet exist, leading to very different memory usage. Users should
  // run with the arg `setup` first to make sure this has happened.
  if (arguments.contains('setup')) return;

  final before = ProcessInfo.currentRss;
  for (var i = 0; i != 5000; ++i) {
    await tester.build(change: 'a.1');
  }
  final after = ProcessInfo.currentRss;
  print((after - before) ~/ 5000);
}
