// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A unique identifier prefix for the part phase index [phase].
///
/// The prefix is the phase number preceded by `$`, so phase 0 produces `$0`
/// and phase 43 produces `$43`. The `$` makes clashes with identifiers written
/// by hand unlikely.
String prefixForPhase(int phase) {
  RangeError.checkNotNegative(phase, 'phase');
  return '\$$phase';
}
