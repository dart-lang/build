// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'benchmark.dart';

/// The shape of the dependency graph.
///
/// Ordering matters because dependencies are read as needed for each build. If
/// the first build already depends on everything, as in `forwards`, that's very
/// different to if each build brings in a new dependency, as in `backwards`.
///
/// `app.dart` is the file that will be changed to trigger an incremental build,
/// in all cases all files transitively depend on it.
enum Shape {
  /// A single library cycle.
  loop,

  /// A line of libraries.
  ///
  /// Considered in alphanumeric order, each one has a dependency on the next.
  /// The final library depends on `app.dart`.
  forwards,

  /// A line of libraries.
  ///
  /// Considered in alphanumeric order, each one has a dependency on the one
  /// before. The first library depends on `app.dart`.
  backwards,

  /// Randomly connected libraries.
  random;

  Iterable<String> importNames(
    int libraryNumber, {
    required int benchmarkSize,
  }) {
    switch (this) {
      case Shape.loop:
        return [
          if (libraryNumber == 0) 'app.dart',
          Benchmarks.libraryName(
            (libraryNumber - 1) % benchmarkSize,
            benchmarkSize: benchmarkSize,
          ),
        ];
      case Shape.forwards:
        return [
          if (libraryNumber == benchmarkSize - 1) 'app.dart',
          if (libraryNumber != benchmarkSize - 1)
            Benchmarks.libraryName(
              libraryNumber + 1,
              benchmarkSize: benchmarkSize,
            ),
        ];
      case Shape.backwards:
        return [
          if (libraryNumber == 0) 'app.dart',
          if (libraryNumber != 0)
            Benchmarks.libraryName(
              libraryNumber - 1,
              benchmarkSize: benchmarkSize,
            ),
        ];
      case Shape.random:
        // Use random.nextInt(random.nextInt(...)) to get a distribution of
        // imports biased towards lower number libraries, which is more
        // realistic than flat random imports.
        final numberOfImports = _random.nextInt(_random.nextInt(10) + 1);
        return [
          if (_random.nextInt(libraryNumber + 1) == 0) 'app.dart',
          for (var i = 0; i != numberOfImports; ++i)
            Benchmarks.libraryName(
              _random.nextInt(_random.nextInt(benchmarkSize + 1) + 1) + 1,
              benchmarkSize: benchmarkSize,
            ),
        ];
    }
  }
}

final _random = Random(0);
