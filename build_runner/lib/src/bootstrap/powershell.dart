// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Windows powershell.
class Powershell {
  static List<String> baseArgs = [
    // Flutter uses "-ExecutionPolicy Bypass" when it uses powershell for
    // its "update Dart" script, do the same.
    '-ExecutionPolicy',
    'Bypass',
    // No user profile: faster startup, avoid customizations.
    '-NoProfile',
    // Error instead of hang on user prompt.
    '-NonInteractive',
  ];
}
