// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An error which occurred during code generation.
///
/// These are typically errors that were detected internally.
class CodegenError extends Error {
  final String _message;

  CodegenError(this._message);

  @override
  String toString() => 'CodegenError: $_message';
}
