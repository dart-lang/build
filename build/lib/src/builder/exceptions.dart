// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../asset/id.dart';

class UnexpectedOutputException implements Exception {
  final AssetId assetId;
  final Iterable<AssetId> expectedOutputs;

  UnexpectedOutputException(this.assetId, {this.expectedOutputs});

  @override
  String toString() => 'UnexpectedOutputException: $assetId'
      '${expectedOutputs == null ? '' : '\nExpected one of: $expectedOutputs'}';
}
