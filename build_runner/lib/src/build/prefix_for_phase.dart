// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String _base62Chars =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/// Returns a unique identifier prefix for the given part phase index.
///
/// Converts [phase] into a base-62 representation using characters `a-z`,
/// `A-Z`, and `0-9`, and prepends one `$` character per digit.
///
/// Phase 0 produces `$a`, phase 61 produces `$9`, phase 62 produces `$$aa`.
String prefixForPhase(int phase) {
  RangeError.checkNotNegative(phase, 'phase');

  var value = phase;
  var limit = 62;
  var length = 1;
  while (value >= limit) {
    value -= limit;
    limit *= 62;
    length++;
  }

  var result = '';
  for (var i = 0; i < length; i++) {
    result = _base62Chars[value % 62] + result;
    value ~/= 62;
  }

  return ('\$' * length) + result;
}
