// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'config.dart';

/// A `build_runner` benchmark.
abstract interface class Benchmark {
  void create(RunConfig config);
}

/// Helpers for creating benchmarks.
class Benchmarks {
  static String libraryName(int libraryNumber, {required int benchmarkSize}) {
    // Start numbering from 1.
    ++libraryNumber;
    // Pad with zeros so alphabetic sort gives numerical ordering.
    final sizeDigits = benchmarkSize.toString().length;
    return 'lib${libraryNumber.toString().padLeft(sizeDigits, '0')}.dart';
  }

  static String partName(
    int libraryNumber, {
    required int benchmarkSize,
    String infix = 'g',
  }) => libraryName(
    libraryNumber,
    benchmarkSize: benchmarkSize,
  ).replaceAll('.dart', '.$infix.dart');

  static String testName(int testNumber, {required int benchmarkSize}) {
    // Start numbering from 1.
    ++testNumber;
    // Pad with zeros so alphabetic sort gives numerical ordering.
    final sizeDigits = benchmarkSize.toString().length;
    return 'some_test${testNumber.toString().padLeft(sizeDigits, '0')}.dart';
  }
}
