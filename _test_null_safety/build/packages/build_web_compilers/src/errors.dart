// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

/// An [Exception] that is thrown when a worker returns an error.
abstract class _WorkerException implements Exception {
  final AssetId failedAsset;

  final String error;

  /// A message to prepend to [toString] output.
  String get message;

  _WorkerException(this.failedAsset, this.error);

  @override
  String toString() => '$message:$failedAsset\n\n$error';
}

/// An [Exception] that is thrown when dartdevc compilation fails.
class DartDevcCompilationException extends _WorkerException {
  @override
  final String message = 'Error compiling dartdevc module';

  DartDevcCompilationException(AssetId jsId, String error) : super(jsId, error);
}
