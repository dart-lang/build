// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Copied from https://github.com/dart-lang/sdk/blob/9d28b1eb9f9cfb7331fef25238be5cba593e37ac/pkg/frontend_server/lib/src/uuid.dart

import 'dart:math' show Random;

/// A random workspace path.
///
/// It's an absolute path, so it won't be interpreted differently based on the
/// current working directory.
String randomWorkspace() {
  final special = 8 + _random.nextInt(4);

  return '/${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}-'
      '${_bitsDigits(16, 4)}-'
      '4${_bitsDigits(12, 3)}-'
      '${_printDigits(special, 1)}${_bitsDigits(12, 3)}-'
      '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}';
}

final Random _random = Random();

String _bitsDigits(int bitCount, int digitCount) =>
    _printDigits(_generateBits(bitCount), digitCount);

int _generateBits(int bitCount) => _random.nextInt(1 << bitCount);

String _printDigits(int value, int count) =>
    value.toRadixString(16).padLeft(count, '0');
