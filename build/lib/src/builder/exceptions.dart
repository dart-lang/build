// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../asset/asset.dart';

class UnexpectedOutputException implements Exception {
  final Asset asset;

  UnexpectedOutputException(this.asset);

  @override
  String toString() => 'UnexpectedOutputException: $asset';
}
